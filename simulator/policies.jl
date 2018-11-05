
function parallel_policy(evs::Array{EVinstance},C::Float64)

    if length(evs)==0
        #nothing to do, return empty array for consistence
        U=Array{Float64}(undef,0);
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


function ev_parallel_trace(arribos,demandas,salidas,potencias,C=Inf;snapshots=[Inf])
    ev_sim_trace(arribos,demandas,salidas,potencias,parallel_policy,C,snapshots)
end

function edf_policy(evs::Array{EVinstance},C::Float64)


    if length(evs)==0
        #nothing to do, return empty array for consistence
        U=Array{Float64}(undef,0);
    else
        deadlines = [ev.currentDeadline for ev in evs];
        perm = sortperm(deadlines);

        p=0.0;
        i=1;
        U=zeros(length(evs));

        #recorro el vector en orden de deadline y le asigno su potencia maxima o lo que falte pare llegar a C (puede ser 0)
        while p<C && i<=length(evs)
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

function ev_edf_trace(arribos,demandas,salidas,potencias,C=Inf;snapshots=[Inf])
    ev_sim_trace(arribos,demandas,salidas,potencias,edf_policy,C,snapshots)
end

function llf_policy(evs::Array{EVinstance},C::Float64)

    if length(evs)==0
        #nothing to do, return empty array for consistence
        U=Array{Float64}(undef,0);
    else
        laxities = [ev.currentDeadline-ev.currentWorkload/ev.chargingPower for ev in evs];
        perm = sortperm(laxities);

        p=0.0;
        i=1;
        U=zeros(length(evs));

        #recorro el vector en orden de deadline y le asigno su potencia maxima o lo que falte pare llegar a C (puede ser 0)
        while p<C && i<=length(evs)
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

function ev_llf_trace(arribos,demandas,salidas,potencias,C=Inf;snapshots=[Inf])
    ev_sim_trace(arribos,demandas,salidas,potencias,llf_policy,C,snapshots)
end

function llr_policy(evs::Array{EVinstance},C::Float64)

    if length(evs)==0
        #nothing to do, return empty array for consistence
        U=Array{Float64}(undef,0);
    else
        relative_laxities = [ev.currentDeadline*ev.chargingPower/ev.currentWorkload for ev in evs];
        perm = sortperm(relative_laxities);

        p=0.0;
        i=1;
        U=zeros(length(evs));

        #recorro el vector en orden de deadline y le asigno su potencia maxima o lo que falte pare llegar a C (puede ser 0)
        while p<C && i<=length(evs)
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


function ev_llr_trace(arribos,demandas,salidas,potencias,C=Inf;snapshots=[Inf])
    ev_sim_trace(arribos,demandas,salidas,potencias,llr_policy,C,snapshots)
end

function pf_policy(evs::Array{EVinstance},C::Float64)

    if length(evs)==0
        #nothing to do, return empty array for consistence
        U=Array{Float64}(undef,0);
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

function ev_pf_trace(arribos,demandas,salidas,potencias,C=Inf;snapshots=[Inf])
    ev_sim_trace(arribos,demandas,salidas,potencias,pf_policy,C,snapshots)
end

function exact_policy(evs::Array{EVinstance},C::Float64)


    if length(evs)==0
        #nothing to do, return empty array for consistence
        U=Array{Float64}(undef,0);
    else
        #exact scheduling o potencia maxima
        U = [min(ev.currentWorkload/ev.currentDeadline,ev.chargingPower) for ev in evs];

        #curtailing si me paso de C
        if sum(U)>C
            U = C/sum(U)*U;

            #otra posibilidad es ordernar por rate y asignar hasta C
        end

    end
    return U;

end

function ev_exact(lambda,mu,gamma,Tfinal,C=Inf;snapshots=[Inf])
    ev_sim(lambda,mu,gamma,Tfinal,C,exact_policy,snapshots)
end

function ev_exact_trace(arribos,demandas,salidas,potencias,C=Inf;snapshots=[Inf])
    ev_sim_trace(arribos,demandas,salidas,potencias,exact_policy,C,snapshots)
end

using JuMP, Gurobi, LinearAlgebra

function peak_policy(evs::Array{EVinstance},C::Float64)


    if length(evs)==0
        #nothing to do, return empty array for consistence
        U=Array{Float64}(undef,0);
    else
        U=zeros(length(evs));

        idx = sortperm([ev.currentDeadline for ev in evs]);

        sigma = [ev.currentWorkload for ev in evs][idx];
        tau = [ev.currentDeadline for ev in evs][idx];
        deltat=diff([0;tau]);
        p = [ev.chargingPower for ev in evs][idx];
        n=length(evs);

        m=Model(solver=GurobiSolver(OutputFlag=0))

        @variable(m,x[1:n,1:n]>=0)
        @variable(m,auxvar)

        @constraint(m,[i=1:n,j=i+1:n],x[i,j]==0)

        @constraint(m,[i=1:n,j=1:i],x[i,j]<=p[i])
        @constraint(m,sum(x*Diagonal(deltat),dims=2).==sigma)
        @constraint(m,sum(x,dims=1).<=auxvar)

        @objective(m,Min,auxvar)

        solve(m)

        U[idx] = max.(getvalue(x)[:,1],0.0);


    end
    return U;

end

function ev_peak(lambda,mu,gamma,Tfinal,C=Inf;snapshots=[Inf])
    ev_sim(lambda,mu,gamma,Tfinal,C,peak_policy,snapshots)
end

function ev_peak_trace(arribos,demandas,salidas,potencias,C=Inf;snapshots=[Inf])
    ev_sim_trace(arribos,demandas,salidas,potencias,peak_policy,C,snapshots)
end

function fifo_policy(evs::Array{EVinstance},C::Float64)


    if length(evs)==0
        #nothing to do, return empty array for consistence
        U=Array{Float64}(undef,0);
    else
        p=0.0;
        i=1;
        U=zeros(length(evs));
        while p<C && i<=length(evs)
            alloc = min(evs[i].chargingPower,C-p);
            p=p+alloc;
            U[i]=alloc;
            i=i+1;
        end
    end
    return U;

end

function ev_fifo(lambda,mu,gamma,Tfinal,C=Inf;snapshots=[Inf])
    ev_sim(lambda,mu,gamma,Tfinal,C,fifo_policy,snapshots)
end

function ev_fifo_trace(arribos,demandas,salidas,potencias,C=Inf;snapshots=[Inf])
    ev_sim_trace(arribos,demandas,salidas,potencias,fifo_policy,C,snapshots)
end
