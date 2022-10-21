"""
Charging Station Agent

Defines a general EV Charging Station with a given number of charging spots (i.e. parking spaces), maximum power that can be delivered by the installation and a scheduling policy (e.g. edf_policy). It can be used directly connected to an Arrival Process or to a Router.

Constructor:

ChargingStation(chargingSpots=Inf, maximumPower=Inf, schedulingPolicy = parallel_policy; snapshots = Float64[])
"""
mutable struct ChargingStation <: Agent

    #attributes
    chargingSpots::Float64
    maximumPower::Float64
    schedulingPolicy::Function
    position::Vector{Float64}

    #state
    timeToNextEvent::Float64
    nextEventType::Symbol
    occupation::Int64
    currentPower::Float64
    charging::Array{EVinstance}
    alreadyCharged::Array{EVinstance}
    incoming::Array{EVinstance}
    congestionPrice::Float64

    #tracing
    trace::DataFrame
    arrivals::Int64
    totalCompletedCharges::Int64
    incompleteDepartures::Int64
    totalDepartures::Int64
    blocked::Int64
    totalEnergyRequested::Float64
    totalEnergyDelivered::Float64

    #final state of EVs through the station
    completedEVs::Array{EVinstance}

    #snapshots
    snapshotTimes::Vector{Float64}
    snapshots::Array{Snapshot}
    nextSnapshot::Float64


    function ChargingStation(chargingSpots=Inf, maximumPower=Inf, schedulingPolicy::Function = parallel_policy; snapshots::Vector{Float64} = Float64[], position::Vector{Float64}=[NaN,NaN])
        trace = DataFrame(  time=0.0, 
                            arrivals=0,
                            occupation = 0,
                            currentPower = 0.0, 
                            currentCharging=0,
                            currentAlreadyCharged=0,
                            currentCongestionPrice=0.0,
                            totalCompletedCharges=0,
                            incompleteDepartures=0,
                            totalDepartures=0,
                            blocked=0,
                            totalEnergyRequested=0.0,
                            totalEnergyDelivered=0.0
                        )
        if isempty(snapshots)
            new(chargingSpots,maximumPower,schedulingPolicy,position,Inf,:Nothing,0,0.0,EVinstance[],EVinstance[],EVinstance[],0.0,trace,0,0,0,0,0,0.0,0.0,EVinstance[],snapshots,Snapshot[], Inf)
        else
            new(chargingSpots,maximumPower,schedulingPolicy,position, snapshots[1],:Snapshot,0,0.0,EVinstance[],EVinstance[],EVinstance[],0.0,trace,0,0,0,0,0,0.0,0.0,EVinstance[],snapshots,Snapshot[],snapshots[1])
        end
    end

end

#Internal function to update state after dt time units
function update_state!(sta::ChargingStation, dt::Float64)
    map(v->update_vehicle!(v,dt),sta.charging);
    map(v->update_vehicle!(v,dt),sta.alreadyCharged);
    map(v->update_position!(v,sta.position,dt),sta.incoming);
    sta.timeToNextEvent = sta.timeToNextEvent-dt
end

#Internal function to save the state to the trace DataFrame
function trace_state!(sta::ChargingStation, t::Float64)
    push!(sta.trace, [t,sta.arrivals,sta.occupation, sta.currentPower, length(sta.charging), length(sta.alreadyCharged), sta.congestionPrice, sta.totalCompletedCharges,sta.incompleteDepartures,sta.totalDepartures, sta.blocked,sta.totalEnergyRequested,sta.totalEnergyDelivered])
end

#Handles the event at time t
function handle_event(sta::ChargingStation, t::Float64, params...)

    #Defined events:
    #Arrival - when a new car arrivalTimes.
    #FinishedCharge - when a car finishes its energy charge.
    #ChargingFinishedStay - deadline expiration while charging.
    #AlreadyChargedFinishedStay - deadline expiration of already charged vehicle.
    #Snapshot - must take snapshot

    eventType = params[1]

    if eventType === :Arrival

        if length(params)==2
            #this is a fresh arrival, and the vehicle is expected as params[2]
            newEV = params[2]::EVinstance

            if newEV.currentPosition[1] === sta.position[1] && newEV.currentPosition[2] === sta.position[2] #arrival is immediate, carry on
                sta.arrivals = sta.arrivals+1
                #check for space
                if sta.occupation < sta.chargingSpots
                    push!(sta.charging, newEV)
                    sta.occupation = sta.occupation + 1
                    sta.totalEnergyRequested = sta.totalEnergyRequested + newEV.requestedEnergy
                else
                    sta.blocked = sta.blocked + 1
                end
            else #vehicle is far away, add to incoming
                push!(sta.incoming, newEV)
            end
        else
            #This is an endogenously generated arrival, due to a incoming vehicle reaching the station

            #find out which
            aux,k = findmin(compute_arrival_time.(sta.incoming,Ref(sta.position)))
            @assert isapprox(aux,0,atol=tol) "At time $t incoming :Arrival event with positive computed arrival time $aux"

            #retrieve it and delete it from incoming
            newEV = sta.incoming[k]
            deleteat!(sta.incoming,k)

            @assert isapprox(newEV.currentPosition,sta.position,atol=tol) "At time $t incoming :Arrival but positions do not match"

            #proceed as usual
            sta.arrivals = sta.arrivals+1
            #check for space
            if sta.occupation < sta.chargingSpots
                push!(sta.charging, newEV)
                sta.occupation = sta.occupation + 1
                sta.totalEnergyRequested = sta.totalEnergyRequested + newEV.requestedEnergy
            else
                sta.blocked = sta.blocked + 1
            end
        end

    elseif eventType === :FinishedCharge

        #someone finished its charge within their deadline
        aux,k = findmin([ev.currentWorkload for ev in sta.charging]);
        @assert isapprox(aux,0.0,atol=tol) "At time $t :FinishedCharge event with positive energy - $aux?"

        #Move to already charged
        ev = sta.charging[k];
        push!(sta.alreadyCharged,ev);
        #Move to list of finised charged for statistics
        push!(sta.completedEVs,ev)
        #remove from charging
        deleteat!(sta.charging,k)

        sta.totalCompletedCharges = sta.totalCompletedCharges + 1
        sta.totalEnergyDelivered = sta.totalEnergyDelivered + ev.requestedEnergy

        ev.currentPower=0.0;
        ev.departureWorkload=0.0;
        ev.completionTime=t;

    elseif eventType === :ChargingFinishedStay

        sta.incompleteDepartures = sta.incompleteDepartures + 1
        
        #save the finished car
        aux,k = findmin([ev.currentDeadline for ev in sta.charging]);
        @assert isapprox(aux,0.0,atol=tol) ":ChargingFinishedStay event with positive deadline?"
        ev=sta.charging[k];

        push!(sta.completedEVs,ev);
        deleteat!(sta.charging,k)
        sta.occupation = sta.occupation - 1
        sta.totalDepartures = sta.totalDepartures + 1
        sta.incompleteDepartures = sta.incompleteDepartures + 1
        sta.totalEnergyDelivered = sta.totalEnergyDelivered + ev.requestedEnergy - ev.currentWorkload

        ev.currentPower=0.0;
        ev.departureWorkload = ev.currentWorkload;
        ev.completionTime=t;

    elseif eventType === :AlreadyChargedFinishedStay

        aux,k = findmin([ev.currentDeadline for ev in sta.alreadyCharged]);
        @assert isapprox(aux,0.0,atol=tol) ":AlreadyChargedFinishedStay event with positive deadline?"

        deleteat!(sta.alreadyCharged,k);
        sta.occupation = sta.occupation - 1
        sta.totalDepartures = sta.totalDepartures + 1

    elseif eventType === :Snapshot

        take_snapshot!(sta,t)
        sta.snapshotTimes = sta.snapshotTimes[2:end]

    end

    #After event, update power powerAllocation using the policy and compute nextEventType and timeToNextEvent

    if length(sta.charging)>0 #there are vehicles charging

        p = sta.schedulingPolicy(sta.charging,sta.maximumPower);
        sta.currentPower = sum(p)

        if minimum([ev.currentWorkload for ev in sta.charging])==0
            nextCharge=0;
        else
            nextCharge = minimum([ev.currentWorkload/ev.currentPower for ev in sta.charging]);
        end

        nextDepON = minimum([ev.currentDeadline for ev in sta.charging]);
    else
        nextCharge = Inf;
        nextDepON = Inf;
        sta.currentPower=0.0;
    end

    if length(sta.alreadyCharged)>0
        nextDepOFF = minimum([ev.currentDeadline for ev in sta.alreadyCharged]);
    else
        nextDepOFF = Inf;
    end

    if length(sta.incoming)>0
        nextIncoming = minimum(compute_arrival_time.(sta.incoming,Ref(sta.position)))
    else
        nextIncoming = Inf
    end

    if isempty(sta.snapshotTimes)
        nextSnapshot = Inf
    else
        nextSnapshot = sta.snapshotTimes[1]-t
    end

    #update congestionPrice
    sta.congestionPrice = compute_congestion_price(sta)

    ##Define next event
    aux,case = findmin([nextCharge,nextDepON,nextDepOFF,nextIncoming,nextSnapshot])

    sta.timeToNextEvent = aux
    if aux==Inf
        sta.nextEventType = :Nothing
    elseif case==1
        sta.nextEventType = :FinishedCharge
    elseif case==2
        sta.nextEventType = :ChargingFinishedStay
    elseif case==3
        sta.nextEventType = :AlreadyChargedFinishedStay
    elseif case==4
        sta.nextEventType = :Arrival
    elseif case==5
        sta.nextEventType = :Snapshot
    end


end

#Internal function to take a snapshot of the state at time t
function take_snapshot!(sta::ChargingStation,t::Float64)

    charging = deepcopy(sta.charging)
    alreadyCharged = deepcopy(sta.alreadyCharged)
    incoming = deepcopy(sta.incoming)
    congestionPrice = sta.congestionPrice

    snapshot = Snapshot(t,charging,alreadyCharged,incoming,congestionPrice)
    push!(sta.snapshots,snapshot)
    
end

