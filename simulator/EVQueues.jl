__precompile__()

module EVQueues

using ProgressMeter, Distributions

export ev_parallel, ev_pf, ev_edf, ev_llf, ev_llr, ev_exact, compute_statistics!, EVSim, ev_parallel_trace, ev_pf_trace, ev_edf_trace, ev_llf_trace, ev_llr_trace, ev_exact_trace, compute_fairness, loadsim, savesim



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
                chargingPower::Float64) = new(arrivalTime,departureTime,requestedEnergy,chargingPower,requestedEnergy/chargingPower,departureTime-arrivalTime,0.0,NaN,NaN)
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

include("ev_sim.jl")  ##codigo del simulador comun
#include("ev_sim_trace.jl") ##codigo del simulador a partir de trazas

include("policies.jl")

function update_vehicle(ev::EVinstance,dt::Float64)

    ev.currentWorkload-=ev.currentPower*dt;
    ev.currentDeadline-=dt;

end

function compute_average(f,T::Vector{Float64},X::Vector{UInt16})
    return sum(f(X[1:end-1]).*diff(T))/T[end]
end

function compute_statistics!(sim::EVSim)
    sim.stats.avgX = compute_average(x->x,sim.timetrace.T,sim.timetrace.X);
    sim.stats.avgY = compute_average(x->x,sim.timetrace.T,sim.timetrace.Y);

    sim.stats.avgW = mean([ev.departureWorkload for ev in sim.EVs]);

    rangeX = collect(minimum(sim.timetrace.X):maximum(sim.timetrace.X))
    pX=zeros(length(sim.stats.rangeX));
    for i=1:length(pX)
        pX[i] = compute_average(x->x.==rangeX[i],sim.timetrace.T,sim.timetrace.X);
    end
    sim.stats.rangeX = rangeX;
    sim.stats.pX=pX;

    rangeY = collect(minimum(sim.timetrace.Y):maximum(sim.timetrace.Y))
    pY=zeros(length(sim.stats.rangeY));
    for i=1:length(pY)
        pY[i] = compute_average(x->x.==rangeY[i],sim.timetrace.T,sim.timetrace.Y);
    end
    sim.stats.rangeY = rangeY;
    sim.stats.pY=pY;

    sim.stats.pD = sum([ev.departureWorkload>0 for ev in sim.EVs])/length(sim.EVs);

    return nothing
end

function fairness_index(sr,s)

    J=1.0;

    if length(sr)>0 && sum(sr)>0
        J = mean(sr./s).^2/(mean((sr./s).^2));
    end
    return J
end

function compute_fairness(sim::EVSim,t::Vector{Float64},h::Float64)

    J=zeros(length(t))

    for i=1:length(t)
        w=sim.W[sim.W[:,4].<=t[i],:];
        w=w[w[:,4].>=t[i]-h,:];

        J[i] = fairness_index(w[:,1]-w[:,2],w[:,1]);

    end
    return J;
end


function savesim(sim::EVSim, file::String)
    serialize(open(file,"w"),sim);
end

function loadsim(file::String)
    io=open(file,"r");
    deserialize(io);
end

end #end module
