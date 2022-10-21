#######################################################################
###
### Scheduling policies
###
#######################################################################

### A large family of policies are priority policies (based on a priority rule
### such as order of arrival, deadline order, etc)
### The general_priority_policty implements this general case. perm is the priority permutation

function general_priority_policy(evs::Array{EVinstance},C::Number,perm::Array{<:Integer})

    p=0.0;
    i=1;

    while p<C && i<=length(evs)
        alloc = min(evs[perm[i]].chargingPower,C-p);
        p=p+alloc;
        evs[perm[i]].currentPower=alloc;
        i=i+1;
    end

    while i<=length(evs)
        evs[perm[i]].currentPower=0.0;
        i=i+1
    end

    return p;
end

### Priority based policies

### Earliest Deadline first.
function edf_policy(evs::Array{EVinstance},C::Number)

    deadlines = [ev.currentDeadline for ev in evs]
    perm = sortperm(deadlines);

    return general_priority_policy(evs::Array{EVinstance},C::Number,perm::Array{<:Integer})
end

@addpolicy("edf")

### Least laxity first
function llf_policy(evs::Array{EVinstance},C::Number)

    laxities = [ev.currentDeadline - ev.currentWorkload/ev.chargingPower for ev in evs]
    perm = sortperm(laxities);

    return general_priority_policy(evs::Array{EVinstance},C::Number,perm::Array{<:Integer})
end

@addpolicy("llf")

### Least laxity ratio (Zeballos et al 2019)
function llr_policy(evs::Array{EVinstance},C::Number)

    relative_laxities = [ev.currentDeadline*ev.chargingPower/ev.currentWorkload for ev in evs];
    perm = sortperm(relative_laxities);

    return general_priority_policy(evs::Array{EVinstance},C::Number,perm::Array{<:Integer})
end

@addpolicy("llr")

### FIFO. It's a priority policy with arrival time as priority vector.
function fifo_policy(evs::Array{EVinstance},C::Number)

    perm = collect(1:length(evs))

    return general_priority_policy(evs::Array{EVinstance},C::Number,perm::Array{<:Integer})
end

@addpolicy("fifo")

### LIFO. It's a priority policy with reversed arrival time as priority vector.
function lifo_policy(evs::Array{EVinstance},C::Number)

    perm = collect(length(evs):-1:1)

    return general_priority_policy(evs::Array{EVinstance},C::Number,perm::Array{<:Integer})
end

@addpolicy("lifo")

### LAR: least attained ratio
function lar_policy(evs::Array{EVinstance},C::Number)

    relative_attained = [(ev.departureTime-ev.arrivalTime-ev.currentDeadline)*ev.chargingPower/ev.currentWorkload for ev in evs];
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

#max weight policy where weight is minimum between rem. work and rem. deadline
function mw_policy(evs::Array{EVinstance},C::Number)

    remaining_w = [ev.currentWorkload for ev in evs];
    remaining_d = [ev.currentDeadline for ev in evs];

    weights = min.(remaining_w,remaining_d)
    perm = sortperm(weights,rev=true);

    return general_priority_policy(evs::Array{EVinstance},C::Number,perm::Array{<:Integer})
end

@addpolicy("mw")

### Non-priority based policies

### Processor sharing Policy
function parallel_policy(evs::Array{EVinstance},C::Number)

    totPower=sum([ev.chargingPower for ev in evs]);
    curtail = min(1,C/totPower);

    [ev.currentPower = curtail*ev.chargingPower for ev in evs]

    return curtail*totPower
end

@addpolicy("parallel")

### Proportional fairness policy
function pf_policy(evs::Array{EVinstance},C::Number)

    ##TODO Revisar comput_pf. Parece estar bien.
    workloads = [ev.currentWorkload for ev in evs];
    deadlines = [ev.currentDeadline for ev in evs];
    U=compute_pf(workloads,deadlines,C)

    for i=1:length(evs)
        evs[i].currentPower = U[i]
    end

    return sum(U);
end

## helper function to compute the proportional fair allocation
function compute_pf(workloads,deadlines,C)

    w=workloads./deadlines;

    U=zeros(size(w));
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

### Exact scheduling (Nakahira et al 2018)
function exact_policy(evs::Array{EVinstance},C::Number)

    #exact scheduling o potencia maxima
    U = [min(ev.currentWorkload/ev.currentDeadline,ev.chargingPower) for ev in evs];

    #curtailing si me paso de C
    if sum(U)>C
        U = C/sum(U)*U;
        #otra posibilidad es ordernar por rate y asignar hasta C
    end

    for i=1:length(evs)
        evs[i].currentPower = U[i]
    end

    return sum(U);
end

@addpolicy("exact")

### Policies that use reported deadlines instead of deadline

### EDF policy based on reported deadlines
function edfu_policy(evs::Array{EVinstance},C::Number)

    deadlines = [ev.currentReportedDeadline for ev in evs];
    perm = sortperm(deadlines);

    return general_priority_policy(evs::Array{EVinstance},C::Number,perm::Array{<:Integer})

end

@addpolicy("edfu")

### EDF policy based on reported deadlines with curtailing after deadline expiration (Narbondo et al 2021)
function edfc_policy(evs::Array{EVinstance},C::Number)

    deadlines = [ev.currentReportedDeadline for ev in evs];

    pending = findall(deadlines.>0)
    expired = findall(deadlines.<=0)

    perm1 = sortperm(deadlines[pending]);
    perm2 = sortperm(deadlines[expired], rev=true);

    perm = [pending[perm1];expired[perm2]]

    return general_priority_policy(evs::Array{EVinstance},C::Number,perm::Array{<:Integer})

end

@addpolicy("edfc")

### LDF policy based on reported deadlines
function llfu_policy(evs::Array{EVinstance},C::Number)

    laxities = [ev.currentReportedDeadline-ev.currentWorkload/ev.chargingPower for ev in evs];
    perm = sortperm(laxities);

    return general_priority_policy(evs::Array{EVinstance},C::Number,perm::Array{<:Integer})

end

@addpolicy("llfu")

### LLF policy based on reported deadlines with curtailing after deadline expiration (Narbondo et al 2021)
function llfc_policy(evs::Array{EVinstance},C::Number)

    deadlines = [ev.currentReportedDeadline for ev in evs];
    laxities = [ev.currentReportedDeadline-ev.currentWorkload/ev.chargingPower for ev in evs];

    pending = findall(deadlines.>0)
    expired = findall(deadlines.<=0)

    perm1 = sortperm(laxities[pending]);
    perm2 = sortperm(laxities[expired], rev=true);

    perm = [pending[perm1];expired[perm2]]

    return general_priority_policy(evs::Array{EVinstance},C::Number,perm::Array{<:Integer})

end

@addpolicy("llfc")


#######################################################################
###
### Routing policies. For use with a Router object
###
#######################################################################

### Routing policy where the less occupied station is chosen
function least_loaded_routing(stations::Vector{ChargingStation}, ev::EVinstance)

    x = [length(sta.charging) for sta in stations]

    _,idx = findmin(x)
    return idx

end

export least_loaded_routing

### Random routing policy
function random_routing(stations::Vector{ChargingStation},ev::EVinstance)

    return rand(DiscreteUniform(1,length(stations)))
    
end

export random_routing

### Random routing policy based on the number of free spaces in each sink
function free_spaces_routing(stations::Vector{ChargingStation},ev::EVinstance)

    @assert sum([sta.chargingSpots for sta in stations])<Inf "Free spaces routing requiere finite-capacity stations, found $([sta.chargingSpots for sta in stations])"

    free = [sta.chargingSpots - sta.occupation for sta in stations]

    if sum(free)>0
        p = free/sum(free)
        d = Categorical(p)
        return rand(d)
    else
        return rand(DiscreteUniform(1,length(stations)))
    end
    
end

export free_spaces_routing