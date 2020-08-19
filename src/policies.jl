
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

@addpolicy("parallel")

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

@addpolicy("edf")

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

@addpolicy("llf")

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

@addpolicy("llr")


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

@addpolicy("pf")


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

@addpolicy("exact")

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

        m=Model(GLPK.Optimizer)

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

@addpolicy("peak")


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

@addpolicy("fifo")


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

@addpolicy("lifo")


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

@addpolicy("lar")


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

@addpolicy("las")


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

@addpolicy("ratio")


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

@addpolicy("lrpt")


#max weight policy where weight is minimum between rem. work and rem. deadline
function mw_policy(evs::Array{EVinstance},C::Float64)

    if length(evs)==0
        #nothing to do, return empty array for consistence
        U=Array{Float64}(undef,0);
    else
        remaining_w = [ev.currentWorkload for ev in evs];
        remaining_d = [ev.currentDeadline for ev in evs];

        weights = min.(remaining_w,remaining_d)
        perm = sortperm(weights,rev=true);

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

@addpolicy("mw")

#this policy comes from maximizing myopically the potential amount of work one can perform, ignoring future arrivals
#it underload it behaves exactly as exact scheduling!
function weird_policy(evs::Array{EVinstance},C::Float64)

    if length(evs)==0
        #nothing to do, return empty array for consistence
        U=Array{Float64}(undef,0);
    else

        perm = sortperm([ev.currentDeadline for ev in evs], rev=true)

        remaining_w = [ev.currentWorkload for ev in evs];
        remaining_d = [ev.currentDeadline for ev in evs];

        p=0.0;
        i=1;
        U=zeros(length(evs));

        #recorro el vector en orden de deadline y le asigno su potencia maxima o lo que falte pare llegar a C (puede ser 0)
        while p<C && i<=length(evs)
            ev = evs[perm[i]];
            alloc = min(ev.chargingPower,ev.chargingPower*ev.currentWorkload/ev.currentDeadline,C-p)
            p=p+alloc;
            U[perm[i]]=alloc;
            i=i+1;
        end

    end
    return U;
end

@addpolicy("weird")


function edffixed_policy(evs::Array{EVinstance},C::Float64)

    threshold = log(2);

    if length(evs)==0
        #nothing to do, return empty array for consistence
        U=Array{Float64}(undef,0);
    else
        deadlines = [ev.currentDeadline for ev in evs];
        U=zeros(length(evs));
        U[deadlines.<=threshold].=1;
    end
    return U;

end

@addpolicy("edffixed")
