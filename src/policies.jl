### The following code defines all the policies that can be used in the simulator




### A large family of policies are priority policies (based on a priority rule
### such as order of arrival, deadline order, etc)
### The general_priority_policty implements this general case.

function general_priority_policy(evs::Array{EVinstance},C::Number,perm::Array{<:Integer})

    p=0.0;
    i=1;
    U=zeros(length(evs));

    while p<C && i<=length(evs)
        alloc = min(evs[perm[i]].chargingPower,C-p);
        p=p+alloc;
        U[perm[i]]=alloc;
        i=i+1;
    end

    return U;
end

### Priority based policies

### Earliest Deadline first.
function edf_policy(evs::Array{EVinstance},C::Number)

    deadlines = [ev.currentReportedDeadline for ev in evs];
    perm = sortperm(deadlines);

    return general_priority_policy(evs::Array{EVinstance},C::Number,perm::Array{<:Integer})
end

@addpolicy("edf")

### Least laxity first
function llf_policy(evs::Array{EVinstance},C::Number)

    laxities = [ev.currentReportedDeadline-ev.currentWorkload/ev.chargingPower for ev in evs];
    perm = sortperm(laxities);

    return general_priority_policy(evs::Array{EVinstance},C::Number,perm::Array{<:Integer})
end

@addpolicy("llf")

function llr_policy(evs::Array{EVinstance},C::Number)

    relative_laxities = [ev.currentReportedDeadline*ev.chargingPower/ev.currentWorkload for ev in evs];
    perm = sortperm(relative_laxities);

    return general_priority_policy(evs::Array{EVinstance},C::Number,perm::Array{<:Integer})
end

@addpolicy("llr")


### FIFO. It's a priority policy with arrival time as priority vector.
function fifo_policy(evs::Array{EVinstance},C::Number)

    perm = 1:length(evs)

    return general_priority_policy(evs::Array{EVinstance},C::Number,perm::Array{<:Integer})
end

@addpolicy("fifo")

### FIFO. It's a priority policy with reversed arrival time as priority vector.
function lifo_policy(evs::Array{EVinstance},C::Number)

    perm = length(evs):-1:1

    return general_priority_policy(evs::Array{EVinstance},C::Number,perm::Array{<:Integer})
end

@addpolicy("lifo")

### LAR: least attained ratio
function lar_policy(evs::Array{EVinstance},C::Number)

    relative_attained = [(ev.departureTime-ev.arrivalTime-ev.currentReportedDeadline)*ev.chargingPower/ev.currentWorkload for ev in evs];
    perm = sortperm(relative_attained,rev=true);

    return general_priority_policy(evs::Array{EVinstance},C::Number,perm::Array{<:Integer})
end

@addpolicy("lar")

### LAS: least attained service
function las_policy(evs::Array{EVinstance},C::Number)

    attained = [ev.requestedEnergy-ev.currentWorkload for ev in evs];
    perm = sortperm(attained);

    return general_priority_policy(evs::Array{EVinstance},C::Number,perm::Array{<:Integer})
end

@addpolicy("las")

### RATIO policy: just sort by current percentage of charge remaining
function ratio_policy(evs::Array{EVinstance},C::Number)

    ratios = [ev.currentWorkload/ev.requestedEnergy for ev in evs];
    perm = sortperm(ratios,rev=true);

    return general_priority_policy(evs::Array{EVinstance},C::Number,perm::Array{<:Integer})
end

@addpolicy("ratio")


### LRPT: Largest remaining processing tiem
function lrpt_policy(evs::Array{EVinstance},C::Number)

    remaining = [ev.currentWorkload for ev in evs];
    perm = sortperm(remaining,rev=true);

    return general_priority_policy(evs::Array{EVinstance},C::Number,perm::Array{<:Integer})
end

@addpolicy("lrpt")


### Non-priority based policies

### Processor sharing Policy
function parallel_policy(evs::Array{EVinstance},C::Number)

    totPower=sum([ev.chargingPower for ev in evs]);
    curtail = min(1,C/totPower);

    U = [curtail*ev.chargingPower for ev in evs]

    return U
end

@addpolicy("parallel")


### Proportional fairness policy
function pf_policy(evs::Array{EVinstance},C::Number)

    ##TODO Revisar comput_pf. Parece estar bien.
    workloads = [ev.currentWorkload for ev in evs];
    deadlines = [ev.currentReportedDeadline for ev in evs];
    U=compute_pf(worklodas,deadlines,C)

    return U;
end

function compute_pf(workloads,deadlinesON,C)

    w=workloads./deadlinesON;

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


### Exact scheduling.
function exact_policy(evs::Array{EVinstance},C::Number)

    #exact scheduling o potencia maxima
    U = [min(ev.currentWorkload/ev.currentReportedDeadline,ev.chargingPower) for ev in evs];

    #curtailing si me paso de C
    if sum(U)>C
        U = C/sum(U)*U;
        #otra posibilidad es ordernar por rate y asignar hasta C
    end

    return U;
end

@addpolicy("exact")

### MPC peak minimizer policy. Check whether this is needed to reduce dependencies.
function peak_policy(evs::Array{EVinstance},C::Number)

    U=zeros(length(evs));

    idx = sortperm([ev.currentReportedDeadline for ev in evs]);

    sigma = [ev.currentWorkload for ev in evs][idx];
    tau = [ev.currentReportedDeadline for ev in evs][idx];
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

    return U;

end

@addpolicy("peak")


#### WEIRD POLICIES: This are only for trial purposes. Will be depurated.

#max weight policy where weight is minimum between rem. work and rem. deadline
function mw_policy(evs::Array{EVinstance},C::Number)

    remaining_w = [ev.currentWorkload for ev in evs];
    remaining_d = [ev.currentReportedDeadline for ev in evs];

    weights = min.(remaining_w,remaining_d)
    perm = sortperm(weights,rev=true);

    return general_priority_policy(evs::Array{EVinstance},C::Number,perm::Array{<:Integer})
end

@addpolicy("mw")

#this policy comes from maximizing myopically the potential amount of work one can perform, ignoring future arrivals
#it underload it behaves exactly as exact scheduling!
function weird_policy(evs::Array{EVinstance},C::Number)

    perm = sortperm([ev.currentReportedDeadline for ev in evs], rev=true)

    remaining_w = [ev.currentWorkload for ev in evs];
    remaining_d = [ev.currentReportedDeadline for ev in evs];

    return general_priority_policy(evs::Array{EVinstance},C::Number,perm::Array{<:Integer})
end

@addpolicy("weird")


### Curtailed policies (for reported deadlines)
function edfc_policy(evs::Array{EVinstance},C::Number)


    deadlines = [ev.currentReportedDeadline for ev in evs];

    positivas = findall(deadlines.>0)
    negativas = findall(deadlines.<=0)

    perm1 = sortperm(deadlines[positivas]);
    perm2 = sortperm(deadlines[negativas], rev=true);

    perm = [positivas[perm1];negativas[perm2]]

    return general_priority_policy(evs::Array{EVinstance},C::Number,perm::Array{<:Integer})

end

@addpolicy("edfc")

function llfc_policy(evs::Array{EVinstance},C::Number)


    deadlines = [ev.currentReportedDeadline for ev in evs];
    laxities = [ev.currentReportedDeadline-ev.currentWorkload/ev.chargingPower for ev in evs];

    positivas = findall(deadlines.>0)
    negativas = findall(deadlines.<=0)

    perm1 = sortperm(laxities[positivas]);
    perm2 = sortperm(laxities[negativas], rev=true);

    perm = [positivas[perm1];negativas[perm2]]

    return general_priority_policy(evs::Array{EVinstance},C::Number,perm::Array{<:Integer})

end

@addpolicy("llfc")
