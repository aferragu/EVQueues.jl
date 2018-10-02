
function parallel_policy(evs::Array{EVinstance},C::Float64)

    if length(evs)==0
        #nothing to do, return empty array for consistence
        U=Array{Float64}(0);
    else

        totPower=sum([ev.chargingPower for ev in evs]);
        curtail = min(1,C/totPower);

        U = [curtail*ev.chargingPower for ev in evs]
    end
    return U
end

function ev_parallel(lambda,mu,gamma,Tfinal,C=Inf;snapshots=[Inf])
    ev_sim(lambda,mu,gamma,Tfinal,C,parallel_policy,snapshots)
end


function ev_parallel_trace(arribos,demandas,salidas,C=Inf;snapshots=[Inf])
    ev_sim_trace(arribos,demandas,salidas,parallel_policy,C,snapshots)
end

function edf_policy(evs::Array{EVinstance},C::Float64)


    if length(evs)==0
        #nothing to do, return empty array for consistence
        U=Array{Float64}(0);
    else
        deadlines = [ev.currentDeadline for ev in evs];
        perm = sortperm(deadlines);

        p=0.0;
        i=1;
        U=zeros(length(evs));

        #recorro el vector en orden de deadline y le asigno su potencia maxima o lo que falte pare llegar a C (puede ser 0)
        while p<C && i<length(evs)
            alloc = min(evs[perm[i]].chargingPower,C-p);
            p=p+alloc;
            U[perm[i]]=alloc;
            i=i+1;
        end

    end
    return U;

end

function ev_edf(lambda,mu,gamma,Tfinal,C=Inf;snapshots=[Inf])
    ev_sim(lambda,mu,gamma,Tfinal,C,edf_policy,snapshots)
end

function ev_edf_trace(arribos,demandas,salidas,C=Inf;snapshots=[Inf])
    ev_sim_trace(arribos,demandas,salidas,edf_policy,C,snapshots)
end

function llf_policy(evs::Array{EVinstance},C::Float64)

    if length(evs)==0
        #nothing to do, return empty array for consistence
        U=Array{Float64}(0);
    else
        laxities = [ev.currentDeadline-ev.currentWorkload/ev.chargingPower for ev in evs];
        perm = sortperm(laxities);

        p=0.0;
        i=1;
        U=zeros(length(evs));

        #recorro el vector en orden de deadline y le asigno su potencia maxima o lo que falte pare llegar a C (puede ser 0)
        while p<C && i<length(evs)
            alloc = min(evs[perm[i]].chargingPower,C-p);
            p=p+alloc;
            U[perm[i]]=alloc;
            i=i+1;
        end

    end
    return U;
end

function ev_llf(lambda,mu,gamma,Tfinal,C=Inf;snapshots=[Inf])
    ev_sim(lambda,mu,gamma,Tfinal,C,llf_policy,snapshots)
end

function ev_llf_trace(arribos,demandas,salidas,C=Inf;snapshots=[Inf])
    ev_sim_trace(arribos,demandas,salidas,llf_policy,C,snapshots)
end

function llr_policy(evs::Array{EVinstance},C::Float64)

    if length(evs)==0
        #nothing to do, return empty array for consistence
        U=Array{Float64}(0);
    else
        relative_laxities = [ev.currentDeadline*ev.chargingPower/ev.currentWorkload for ev in evs];
        perm = sortperm(relative_laxities);

        p=0.0;
        i=1;
        U=zeros(length(evs));

        #recorro el vector en orden de deadline y le asigno su potencia maxima o lo que falte pare llegar a C (puede ser 0)
        while p<C && i<length(evs)
            alloc = min(evs[perm[i]].chargingPower,C-p);
            p=p+alloc;
            U[perm[i]]=alloc;
            i=i+1;
        end

    end
    return U;
end

function ev_llr(lambda,mu,gamma,Tfinal,C=Inf;snapshots=[Inf])
    ev_sim(lambda,mu,gamma,Tfinal,C,llr_policy,snapshots)
end


function ev_llr_trace(arribos,demandas,salidas,C=Inf;snapshots=[Inf])
    ev_sim_trace(arribos,demandas,salidas,llr_policy,C,snapshots)
end

function pf_policy(evs::Array{EVinstance},C::Float64)

    if length(evs)==0
        #nothing to do, return empty array for consistence
        U=Array{Float64}(0);
    else
        ##TODO Compute pf bien
        workloads = [ev.currentWorkload for ev in evs];
        deadlines = [ev.currentDeadline for ev in evs];
        U=compute_pf(worklodas,deadlines,C)
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

function ev_pf(lambda,mu,gamma,Tfinal,C=Inf;snapshots=[Inf])
    ev_sim(lambda,mu,gamma,Tfinal,C,pf_policy,snapshots)
end

function ev_pf_trace(arribos,demandas,salidas,C=Inf;snapshots=[Inf])
    ev_sim_trace(arribos,demandas,salidas,pf_policy,C,snapshots)
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

function ev_exact(lambda,mu,gamma,Tfinal,C=Inf;snapshots=[Inf])
    ev_sim(lambda,mu,gamma,Tfinal,C,exact_policy,snapshots)
end

function ev_exact_trace(arribos,demandas,salidas,C=Inf;snapshots=[Inf])
    ev_sim_trace(arribos,demandas,salidas,exact_policy,C,snapshots)
end