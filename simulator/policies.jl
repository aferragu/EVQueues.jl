
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

@addpolicy("parallel",parallel_policy)

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

@addpolicy("edf",edf_policy)

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

@addpolicy("llf",llf_policy)

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

@addpolicy("llr",llr_policy)


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

@addpolicy("pf",pf_policy)


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

@addpolicy("exact",exact_policy)

using JuMP, Gurobi

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
        power = [ev.chargingPower for ev in evs][idx];
        n=length(evs);

        m=Model(solver=GurobiSolver(OutputFlag=0))

        @variable(m,x[1:n,1:n]>=0)
        @variable(m,auxvar)

        @constraint(m,[i=1:n,j=i+1:n],x[i,j]==0)

        @constraint(m,[i=1:n,j=1:i],x[i,j]<=power[i])
        @constraint(m,[i=1:n],sum(x[i,:].*deltat)==sigma[i])
        @constraint(m,sum(x,dims=1).<=auxvar)

        @objective(m,Min,auxvar)

        solve(m)

        U[idx] = max.(getvalue(x)[:,1],0.0);


    end
    return U;

end

@addpolicy("peak",peak_policy)


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

@addpolicy("fifo",fifo_policy)


function lifo_policy(evs::Array{EVinstance},C::Float64)


    if length(evs)==0
        #nothing to do, return empty array for consistence
        U=Array{Float64}(undef,0);
    else
        p=0.0;
        i=length(evs);
        U=zeros(length(evs));
        while p<C && i>=1
            alloc = min(evs[i].chargingPower,C-p);
            p=p+alloc;
            U[i]=alloc;
            i=i-1;
        end
    end
    return U;

end

@addpolicy("lifo",lifo_policy)


function lar_policy(evs::Array{EVinstance},C::Float64)

    if length(evs)==0
        #nothing to do, return empty array for consistence
        U=Array{Float64}(undef,0);
    else
        relative_attained = [(ev.departureTime-ev.arrivalTime-ev.currentDeadline)*ev.chargingPower/ev.currentWorkload for ev in evs];
        perm = sortperm(relative_attained,rev=true);

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

@addpolicy("lar",lar_policy)


function las_policy(evs::Array{EVinstance},C::Float64)

    if length(evs)==0
        #nothing to do, return empty array for consistence
        U=Array{Float64}(undef,0);
    else
        attained = [ev.requestedEnergy-ev.currentWorkload for ev in evs];
        perm = sortperm(attained);

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

@addpolicy("las",las_policy)


function ratio_policy(evs::Array{EVinstance},C::Float64)

    if length(evs)==0
        #nothing to do, return empty array for consistence
        U=Array{Float64}(undef,0);
    else
        ratios = [ev.currentWorkload/ev.requestedEnergy for ev in evs];
        perm = sortperm(ratios,rev=true);

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

@addpolicy("ratio",ratio_policy)


function lrpt_policy(evs::Array{EVinstance},C::Float64)

    if length(evs)==0
        #nothing to do, return empty array for consistence
        U=Array{Float64}(undef,0);
    else
        remaining = [ev.currentWorkload for ev in evs];
        perm = sortperm(remaining,rev=true);

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

@addpolicy("lrpt",lrpt_policy)
