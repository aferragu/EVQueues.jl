abstract type Agent  end

#returns the time of next event of an agent and names
function get_next_event(agent::Agent)::Tuple{Float64,Symbol}
    return agent.timeToNextEvent, agent.nextEventType
end

#update state after dt time units (redefine if necessary)
function update_state!(agent::Agent, dt::Float64)
    agent.timeToNextEvent = agent.timeToNextEvent-dt
end

function take_snapshot!(agent::Agent,t::Float64)
    #do nothing unless redefined
end

mutable struct EVinstance
    arrivalTime::Float64
    departureTime::Float64
    reportedDepartureTime::Float64   ##para el caso en que hay incertidumbre
    requestedEnergy::Float64
    chargingPower::Float64
    currentWorkload::Float64
    currentDeadline::Float64
    currentReportedDeadline::Float64
    currentPower::Float64
    departureWorkload::Float64
    completionTime::Float64

    #inicializo la instancia solo con los 4 importantes y completo los otros al comienzo.
    #En particular reportedDepartureTime lo pongo igual a Departure time por defecto.
    #Departure workload y CompletionTime queda en NaN hasta que se calculen mas adelante.
    EVinstance( arrivalTime::Float64,
                departureTime::Float64,
                requestedEnergy::Float64,
                chargingPower::Float64) = new(  arrivalTime,
                                                departureTime,
                                                departureTime,
                                                requestedEnergy,
                                                chargingPower,
                                                requestedEnergy,
                                                departureTime-arrivalTime,
                                                departureTime-arrivalTime,
                                                0.0,NaN,NaN)

    #este segundo constructor me deja llenar el reportedDepartureTime
    #en particular el valor de currentReportedDeadline se calcula con lo el reportado
    EVinstance( arrivalTime::Float64,
                departureTime::Float64,
                reportedDepartureTime::Float64,
                requestedEnergy::Float64,
                chargingPower::Float64) = new(  arrivalTime,
                                                departureTime,
                                                reportedDepartureTime,
                                                requestedEnergy,
                                                chargingPower,
                                                requestedEnergy,
                                                departureTime-arrivalTime,
                                                reportedDepartureTime-arrivalTime,
                                                0.0,NaN,NaN)
end

mutable struct Snapshot
    t::Float64                          #snapshot time
    charging::Array{EVinstance}         #vehicles in the system in charge
    alreadyCharged::Array{EVinstance}   #already charged vehicles still present
end

mutable struct ChargingStationStatistics
    rangeCharging::Vector{Int64}
    pCharging::Vector{Float64} #steady state X
    rangeAlreadyCharged::Vector{Int64}
    pAlreadyCharged::Vector{Float64} #steady state Y
    avgCharging::Float64       #average X
    avgAlreadyCharged::Float64       #average Y
    pD::Float64         #probability of expired deadline
    avgW::Float64       #average unfinished workload (taking finished into account)
    pB::Float64         #nlocking probability
end
