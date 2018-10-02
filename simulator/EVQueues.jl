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

include("ev_sim_nuevo.jl")  ##codigo del simulador comun
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
    sim.avgX = compute_average(x->x,sim.T,sim.X);
    sim.avgY = compute_average(x->x,sim.T,sim.Y);
    #sim.avgW = sim.pD*mean(sim.W[:,2]);
    k=Int64(round(0.2*length(sim.W[:,2])));
    sim.avgW = mean(sim.W[k:end,2]);  #el pD no va porque ahora guardo todos los workloads remanentes.

    sim.rangeX = collect(minimum(sim.X):maximum(sim.X))
    sim.pX=zeros(length(sim.rangeX));
    for i=1:length(sim.rangeX)
        sim.pX[i] = compute_average(x->x.==sim.rangeX[i],sim.T,sim.X);
    end

    sim.rangeY = collect(minimum(sim.Y):maximum(sim.Y))
    sim.pY=zeros(length(sim.rangeY));
    for i=1:length(sim.rangeY)
        sim.pY[i] = compute_average(x->x.==sim.rangeY[i],sim.T,sim.Y);
    end

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
