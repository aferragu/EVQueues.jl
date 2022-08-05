abstract type Agent  end

#returns the time of next event of an agent and names
function get_next_event(agent::Agent)::Tuple{Float64,Symbol}
    return agent.timeToNextEvent, agent.nextEventType
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

mutable struct TimeTrace
    T::Vector{Float64}          #event times
    X::Vector{UInt16}           #charging vehicles
    Y::Vector{UInt16}           #already charged
    P::Vector{Float64}          #used power
end

mutable struct SimStatistics
    rangeX::Vector{Integer}
    pX::Vector{Float64} #steady state X
    rangeY::Vector{Integer}
    pY::Vector{Float64} #steady state Y
    avgX::Float64       #average X
    avgY::Float64       #average Y
    pD::Float64         #probability of expired deadline
    avgW::Float64       #average unfinished workload (taking finished into account)
end

#defino la estructura resultados de simulacion
mutable struct EVSim
    parameters::Dict
    timetrace::TimeTrace
    EVs::Vector{EVinstance}
    snapshots::Vector{Snapshot}
    stats::SimStatistics
end

#defino la estructura resultados de simulacion
mutable struct EVSimParallel
    parameters::Dict
    timetrace::Vector{TimeTrace}
    EVs::Vector{Vector{EVinstance}}
    snapshots::Vector{Vector{Snapshot}}
    stats::Vector{SimStatistics}
end
