mutable struct ChargingStation <: Agent

    #attributes
    chargingSpots::Float64
    maximumPower::Float64
    schedulingPolicy::Function

    #state
    timeToNextEvent::Float64
    nextEventType::Symbol
    occupation::Int64
    currentPower::Float64
    charging::Array{EVinstance}
    alreadyCharged::Array{EVinstance}

    #tracing
    trace::DataFrame
    arrivals::Int64
    totalCompletedCharges::Int64
    incompleteDepartures::Int64
    totalDepartures::Int64
    blocked::Int64
    totalEnergyRequested::Float64
    totalEnergyDelivered::Float64

    completedEVs::Array{EVinstance}


    function ChargingStation(chargingSpots=Inf, maximumPower=Inf, schedulingPolicy = parallel_policy)
        trace = DataFrame(  time=0.0, 
                            arrivals=0,
                            occupation = 0,
                            currentPower = 0, 
                            currentCharging=0,
                            currentAlreadyCharged=0,
                            totalCompletedCharges=0,
                            incompleteDepartures=0,
                            totalDepartures=0,
                            blocked=0,
                            totalEnergyRequested=0.0,
                            totalEnergyDelivered=0.0
                        )
        new(chargingSpots,maximumPower,schedulingPolicy,Inf,:Nothing,0,0.0,EVinstance[],EVinstance[],trace,0,0,0,0,0,0.0,0.0,EVinstance[])
    end

end

#update state after dt time units
function update_state!(sta::ChargingStation, dt::Float64)
    map(v->update_vehicle(v,dt),sta.charging);
    map(v->update_vehicle(v,dt),sta.alreadyCharged);
end

function trace_state!(sta::ChargingStation, t::Float64)
    push!(sta.trace, [t,sta.arrivals,sta.occupation, sta.currentPower, length(sta.charging), length(sta.alreadyCharged),sta.totalCompletedCharges,sta.incompleteDepartures,sta.totalDepartures, sta.blocked,sta.totalEnergyRequested,sta.totalEnergyDelivered])
end

#handles the event at time t with type "event"
function handle_event(sta::ChargingStation, t::Float64, params...)

    #Defined events:
    #Arrival - when a new car arrivalTimes.
    #FinishedCharge - when a car finishes its energy charge.
    #ChargingFinishedStay - deadline expiration while charging.
    #AlreadyChargedFinishedStay - deadline expiration of already charged vehicle.

    eventType = params[1]

    if eventType === :Arrival

        #new arrival comes. Expects EV as second parameters
        newEV = params[2]::EVinstance

        sta.arrivals = sta.arrivals+1
        #check for space
        if sta.occupation < sta.chargingSpots
            push!(sta.charging, newEV)
            sta.occupation = sta.occupation + 1
            sta.totalEnergyRequested = sta.totalEnergyRequested + newEV.requestedEnergy
        else
            sta.blocked = sta.blocked + 1
        end

    elseif eventType === :FinishedCharge

        #someone finished its charge within their deadline
        aux,k = findmin([ev.currentWorkload for ev in sta.charging]);
        @assert isapprox(aux,0.0,atol=eps()) ":FinishedCharge event with positive energy?"

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
        @assert isapprox(aux,0.0,atol=eps()) ":ChargingFinishedStay event with positive deadline?"
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
        @assert isapprox(aux,0.0,atol=eps()) ":AlreadyChargedFinishedStay event with positive deadline?"

        deleteat!(sta.alreadyCharged,k);
        sta.occupation = sta.occupation - 1
        sta.totalDepartures = sta.totalDepartures + 1

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

    ##Define next event
    aux,case = findmin([nextCharge,nextDepON,nextDepOFF])

    sta.timeToNextEvent = aux
    if case==1
        sta.nextEventType = :FinishedCharge
    elseif case==2
        sta.nextEventType = :ChargingFinishedStay
    elseif case==3
        sta.nextEventType = :AlreadyChargedFinishedStay
    end


end
