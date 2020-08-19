module EVQueues

using ProgressMeter, Distributions, Serialization, JuMP, GLPK

export  compute_statistics!, compute_fairness,
        EVSim, loadsim, savesim

mutable struct EVinstance
    arrivalTime::Float64
    departureTime::Float64
    requestedEnergy::Float64
    chargingPower::Float64
    currentWorkload::Float64
    currentDeadline::Float64
    currentPower::Float64
    departureWorkload::Float64
    completionTime::Float64
    #inicializo la instancia solo con los 4 primeros y completo los otros al comienzo. Departure workload y CompletionTime queda en NaN
    EVinstance( arrivalTime::Float64,
                departureTime::Float64,
                requestedEnergy::Float64,
                chargingPower::Float64) = new(arrivalTime,departureTime,requestedEnergy,chargingPower,requestedEnergy,departureTime-arrivalTime,0.0,NaN,NaN)
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

include("utilities.jl") ##codigo con utilidades varias
include("ev_sim.jl")  ##codigo del simulador comun
include("ev_sim_trace.jl") ##codigo del simulador a partir de trazas
include("policies.jl")  ##codigo que implementa las politicas

function savesim(sim::EVSim, file::String)
    io=open(file,"w");
    serialize(io,sim);
    close(io);
end

function loadsim(file::String)
    io=open(file,"r");
    sim::EVSim = deserialize(io);
    close(io);
    return sim;
end

end #end module