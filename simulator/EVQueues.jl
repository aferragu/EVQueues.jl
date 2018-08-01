__precompile__()

module EVQueues

using Distributions, ProgressMeter

export ev_parallel, ev_pf, ev_edf, ev_llf, ev_llr, ev_exact, compute_statistics!, EVSim, ev_parallel_trace, ev_pf_trace, ev_edf_trace, ev_llf_trace, ev_llr_trace, ev_exact_trace

#defino la estructura resultados de simulacion
mutable struct EVSim
    T::Vector{Float64}  #times
    X::Vector{UInt16}   #charging
    Y::Vector{UInt16}   #already charged
    W::Array{Float64,2} #::Vector{Float64}  #original workload, departure workload, original deadline
    pD::Float64         #probability of expired deadline
    workloads::Vector{Float64}
    deadlinesON::Vector{Float64}
    U:: Union{Float64,Vector{Float64}}
    rangeX::Vector{Integer}
    pX::Vector{Float64} #steady state X
    rangeY::Vector{Integer}
    pY::Vector{Float64} #steady state Y
    avgX::Float64       #average X
    avgY::Float64       #average Y
    avgW::Float64       #average unfinished workload (taking finished into account)
    EVSim(T,X,Y,W,pD,workloads,deadlinesON,U)=new(T,X,Y,W,pD,workloads,deadlinesON,U,[],[],[],[],NaN,NaN,NaN)
end

include("ev_sim.jl")  ##codigo del simulador comun
include("ev_sim_trace.jl") ##codigo del simulador a partir de trazas

function parallel_policy(workloads,deadlinesON,C)

    if C==Inf
        U=ones(workloads);
    else
        x=length(workloads);
        if x>0
            U=min(C/x,1)*ones(workloads); #processor sharing
        else
            U=0;
        end
    end
    return U;
end

function ev_parallel(lambda,mu,gamma,Tfinal,C=Inf)
    ev_sim(lambda,mu,gamma,Tfinal,C,parallel_policy)
end


function ev_parallel_trace(arribos,demandas,salidas,C=Inf,snapshot=Inf)
    ev_sim_trace(arribos,demandas,salidas,parallel_policy,C,snapshot)
end

function edf_policy(workloads,deadlinesON,C)

    if C==Inf
        U=ones(workloads);
    else
        x=length(workloads);
        if x>0
            if x<C
                U=ones(workloads);
            else
                U=zeros(workloads);
                perm=sortperm(deadlinesON);
                U[perm[1:C]]=1; #edf
            end
        else
            U=0;
        end
    end
    return U;
end

function ev_edf(lambda,mu,gamma,Tfinal,C=Inf)
    ev_sim(lambda,mu,gamma,Tfinal,C,edf_policy)
end

function ev_edf_trace(arribos,demandas,salidas,C=Inf,snapshot=Inf)
    ev_sim_trace(arribos,demandas,salidas,edf_policy,C,snapshot)
end

function llf_policy(workloads,deadlinesON,C)

    if C==Inf
        U=ones(workloads);
    else
        x=length(workloads);
        if x>0
            if x<C
                U=ones(workloads);
            else
                U=zeros(workloads);
                perm=sortperm(deadlinesON-workloads);
                U[perm[1:C]]=1; #llf
            end
        else
            U=0;
        end
    end
    return U;
end

function ev_llf(lambda,mu,gamma,Tfinal,C=Inf)
    ev_sim(lambda,mu,gamma,Tfinal,C,llf_policy)
end

function ev_llf_trace(arribos,demandas,salidas,C=Inf,snapshot=Inf)
    ev_sim_trace(arribos,demandas,salidas,llf_policy,C,snapshot)
end

function llr_policy(workloads,deadlinesON,C)

    if C==Inf
        U=ones(workloads);
    else
        x=length(workloads);
        if x>0
            if x<C
                U=ones(workloads);
            else
                U=zeros(workloads);
                perm=sortperm(deadlinesON./workloads);
                U[perm[1:C]]=1; #llf relativo
            end
        else
            U=0;
        end
    end
    return U;
end

function ev_llr(lambda,mu,gamma,Tfinal,C=Inf)
    ev_sim(lambda,mu,gamma,Tfinal,C,llr_policy)
end


function ev_llr_trace(arribos,demandas,salidas,C=Inf,snapshot=Inf)
    ev_sim_trace(arribos,demandas,salidas,llr_policy,C,snapshot)
end

function pf_policy(workloads,deadlinesON,C)

    if C==Inf
        U=ones(workloads);
    else
        x=length(workloads);
        if x>0
            U = compute_pf(workloads,deadlinesON,C);
        else
            U=0;
        end
    end
    return U;
end

function compute_pf(workloads,deadlinesON,C)

    w=workloads./deadlinesON;
    # r=Variable(length(w));
    # p=maximize(w'*log.(r));
    # p.constraints+=(r.<=1);
    # p.constraints+=(sum(r)<=C);
    # p.constraints+=(r.>=0);
    # solve!(p)
    #U=r.value;
    U=zeros(w);
    perm = sortperm(w,rev=true);
    w=sort(w,rev=true);

    for i=1:length(w)

        aux = w[i:end]/sum(w[i:end])*C;
        if aux[1]>1
            U[i] = 1;
            C=C-1;
        else
            U[i:end] = aux;
            break
        end
    end
    U[perm]=U;
    return U;

end

function ev_pf(lambda,mu,gamma,Tfinal,C=Inf)
    ev_sim(lambda,mu,gamma,Tfinal,C,pf_policy)
end

function ev_pf_trace(arribos,demandas,salidas,C=Inf,snapshot=Inf)
    ev_sim_trace(arribos,demandas,salidas,pf_policy,C,snapshot)
end

function exact_policy(workloads,deadlinesON,C)

    x=length(workloads);
    if C==Inf
        if x>0
            U=workloads./deadlinesON;
        else
            U=0;
        end
    else
        if x>0
            U=zeros(workloads);
            perm=sortperm(deadlinesON./workloads);
            p=0;
            i=1;
            for i=1:x
                allocation = min(workloads[perm[i]]/deadlinesON[perm[i]],1);
                allocation = min(C-p,allocation);
                U[perm[i]]=allocation;
                i=i+1;
                p=p+allocation;
            end
        else
            U=0;
        end
    end
    return U;
end

function ev_exact(lambda,mu,gamma,Tfinal,C=Inf)
    ev_sim(lambda,mu,gamma,Tfinal,C,exact_policy)
end

function ev_exact_trace(arribos,demandas,salidas,C=Inf,snapshot=Inf)
    ev_sim_trace(arribos,demandas,salidas,exact_policy,C,snapshot)
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



end #end module
