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
    arrivals::Int64
    completedEVs::Array{EVinstance}
    totalCompletedCharges::Int64
    incompleteDepartures::Int64
    totalDepartures::Int64
    blocked::Int64
    totalEnergyRequested::Float64
    totalEnergyDelivered::Float64

    function ChargingStation(chargingSpots=Inf, maximumPower=Inf, schedulingPolicy = parallel_policy)
        new(chargingSpots,maximumPower,schedulingPolicy,Inf,:Nothing,0,0.0,EVinstance[],EVinstance[],0,EVinstance[],0,0,0,0,0.0,0.0)
    end

end

#update state after dt time units
function update_state!(sta::ChargingStation, dt::Float64)
    map(v->update_vehicle(v,dt),sta.charging);
    map(v->update_vehicle(v,dt),sta.alreadyCharged);
end

function get_traces(sta::ChargingStation)::Vector{Float64}
    return [sta.arrivals,sta.completedCharges,sta.incompleteDepartures,sta.totalDepartures,sta.blocked,sta.totalEnergyRequested,sta.totalEnergyDelivered]
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

        ev.currentPower=0.0;
        ev.departureWorkload = ev.currentWorkload;
        ev.completionTime=t;

    elseif eventType === :AlreadyChargedFinishedStay

        aux,k = findmin([ev.currentDeadline for ev in sta.alreadyCharged]);
        @assert isapprox(aux,0.0,atol=eps()) ":AlreadyChargedFinishedStay event with positive deadline?"

        deleteat!(sta.alreadyCharged,k);
        sta.occupation = sta.occupation - 1

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
    aux,caso = findmin([nextCharge,nextDepON,nextDepOFF])

    sta.timeToNextEvent = aux
    if caso==1
        sta.nextEventType = :FinishedCharge
    elseif caso==2
        sta.nextEventType = :ChargingFinishedStay
    elseif caso==3
        sta.nextEventType = :AlreadyChargedFinishedStay
    end


end
