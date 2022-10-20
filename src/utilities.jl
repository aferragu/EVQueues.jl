### Internal function to update the state of a vehicle after time dt.
function update_vehicle(ev::EVinstance,dt::Float64)

    ev.currentWorkload-=ev.currentPower*dt;
    ev.currentDeadline-=dt;
    ev.currentReportedDeadline-=dt;

end

### Internal function to compute the mean value of a function f(X) over a trajectory of time T.
function compute_average(f,T::Vector{Float64},X::Vector{Int64})
    return sum(f(X[1:end-1]).*diff(T))/T[end]
end

"""
function compute_statistics(sta::ChargingStation,t_start=0.0,t_end=Inf)

Compute summary statistics of a Charging Station between t_start and t_end. Returns a ChargingStationStatistics object
"""
function compute_statistics(sta::ChargingStation,t_start=0.0,t_end=Inf)

    trace = filter(:time => t -> t_start<= t <=t_end, sta.trace)
    avgX = compute_average(x->x,trace[!,:time],trace[!,:currentCharging]);
    avgY = compute_average(x->x,trace[!,:time],trace[!,:currentAlreadyCharged]);

    rangeX = collect(minimum(trace[!,:currentCharging]):maximum(trace[!,:currentCharging]))
    pX = [compute_average(x->x.==l,trace[!,:time],trace[!,:currentCharging]) for l in rangeX]

    rangeY = collect(minimum(trace[!,:currentAlreadyCharged]):maximum(trace[!,:currentAlreadyCharged]))
    pY = [compute_average(x->x.==l,trace[!,:time],trace[!,:currentAlreadyCharged]) for l in rangeX]
 
    EVs = filter(ev-> ev.arrivalTime>= t_start && ev.departureTime<=t_end, sta.completedEVs)
    avgW = mean([ev.departureWorkload for ev in EVs]);

    pD = sum([ev.departureWorkload>0 for ev in EVs])/length(EVs);

    pB = (trace[end,:blocked]-trace[1,:blocked]) / (trace[end,:arrivals] - trace[1,:arrivals])

    return ChargingStationStatistics(rangeX,pX,rangeY,pY,avgX,avgY,pD,avgW,pB)
end

"""
function get_vehicle_trajectories(sta::ChargingStation,t_start=0.0,t_end=Inf)

Computes the charging trajectories of the vehicles that where charged in sta between t_start and t_end
Returns an 
"""
function get_vehicle_trajectories(sta::ChargingStation,t_start=0.0,t_end=Inf)

    d=OrderedDict{Float64,Array{Array{Float64,1},1}}();

    snaps = filter(snap -> t_start<=snap.t <= t_end ,sta.snapshots)

    for snapshot in snaps

        charging = snapshot.charging;

        for j=1:length(charging)
            index = charging[j].arrivalTime;
            if haskey(d,index)
                push!(d[index],[snapshot.t-charging[j].arrivalTime;charging[j].currentWorkload;charging[j].currentDeadline])
            else
                d[index] = [];
            end
        end
    end

    return d
end

"""
function fairness_index(sa,s)

Computes the Jain Fairness Index of the ratio of vectors sa and s. 

`J = mean(sa./s).^2/(mean((sa./s).^2))`

Used to check the fairness of a policy when sa is the vector of charge obtained by each vehicle and s a vector with the requested energies.
"""
function fairness_index(sa::Vector{Float64},s::Vector{Float64})

    J=1.0;

    if length(sa)>0 && sum(sa)>0
        J = mean(sa./s).^2/(mean((sa./s).^2));
    end
    return J
end

"""
function compute_fairness(sta::ChargingStation,t::Vector{Float64},h::Float64)

Computes the Jain Fairness Index of the ratio between attained service and requested service for the vehicles that traverse a charging station sta. Receives a vector t of times where the index must be computed and a window value h. At each time t, it computes the Jain index for all vehicles finishing charge in [t-h,t].
"""
function compute_fairness(sta::ChargingStation,t::Vector{Float64},h::Float64)

    J=zeros(length(t))

    for i=1:length(t)

        evs = filter(ev->(ev.completionTime<=t[i])&&(ev.completionTime>=t[i]-h),sta.completedEVs);
        sa = [ev.requestedEnergy-ev.departureWorkload for ev in evs];
        s = [ev.requestedEnergy for ev in evs];

        J[i] = fairness_index(sa,s);

    end
    return J;
end

### Projection matrix for imbalance
const P=[2/3 -1/3 -1/3;-1/3 2/3 -1/3;-1/3 -1/3 2/3] 

### Imbalance measure for three-phase analysis
function imbalance_measure(x)
    return x'*P*x
end

### macro called after policy definitions in order to export helper functions and the policy
macro addpolicy(name::String)
    f1 = Symbol("ev_",name);
    f2 = Symbol("ev_",name,"_trace");
    policy = Symbol(name,"_policy");
    eval( quote


        function $f1(lambda,mu,gamma,Tfinal,P=Inf;snapshots=[Inf])
            ev_sim(lambda,mu,gamma,Tfinal,P,$policy,snapshots)
        end


        function $f2(arribos,demandas,salidas,potencias,P=Inf;snapshots=[Inf],salidaReportada=nothing)
            ev_sim_trace(arribos,demandas,salidas,potencias,$policy,P,snapshots,salidaReportada=salidaReportada)
        end

        function $f2(df::DataFrame,P=Inf;snapshots=[Inf])
            ev_sim_trace(df,$policy,P,snapshots)
        end

        export $f1, $f2
        export $policy

    end)
end

### retuns the policy name just for parameter extraction
function get_policy_name(policy::Function)

    name = String(Symbol(policy));
    name = split(name,"_")[1];
    uppercase(name);

end

"""
function generate_Poisson_stream(lambda::Float64,mu::Float64,gamma::Float64,Tfinal::Float64)


Generates a DataFrame with a Poisson Arrival process up to time Tfinal. Returns a DataFrame with arrival times, exponential requested energies of parameter mu and exponential initial laxities of parameter gamma.

The generated DataFrane can be used to construct a TraceArrivalProcess with a given Poisson input. Useful if one wants to test different policies in a Poisson setting but with the same arrival pattern.
"""
function generate_Poisson_stream(lambda::Float64,mu::Float64,gamma::Float64,Tfinal::Float64)

    t=0.0
    arr = Exponential(1/lambda)
    work = Exponential(1/mu)
    lax = Exponential(1/gamma)

    #initial approximate memory allocation
    n=round(Integer,1.2*lambda*Tfinal)
    arrivals = zeros(n)
    demands = zeros(n)
    departures = zeros(n)
    #todas las potencias van a ser 1
    powers = ones(n)

    i=0

    while t<Tfinal

        dt=rand(arr)
        t=t+dt
        i=i+1

        arrivals[i] = t
        demands[i] = rand(work)
        departures[i] = t+demands[i] + rand(lax)

    end

    df=DataFrame(:arrivalTimes=>arrivals[1:i], :requestedEnergies=>demands[1:i], :departureTimes=>departures[1:i], :chargingPowers=>powers[1:i])
    return df
end

"""
function sort_completed_vehicles(evs::Vector{EVinstance})

Sort vehicles by arrival time in a Vector of EVinstances.
"""
function sort_completed_vehicles(evs::Vector{EVinstance})

    arr_times = [ev.arrivalTime for ev in evs]
    perm = sortperm(arr_times)
    return evs[perm]

end

function Base.show(ev::EVinstance)

    println("An EV instance with:")
    println("Arrival time: $(ev.arrivalTime)")
    println("Departure time: $(ev.departureTime)")
    println("Self-reported departure time: $(ev.reportedDepartureTime)")
    println("Requested energy: $(ev.requestedEnergy)")
    println("Current remaining work: $(ev.currentWorkload)")
    println("Current remaining deadline: $(ev.currentDeadline)")
    println("Current remaining deadline as reported: $(ev.currentReportedDeadline)")
    println("Current charging rate: $(ev.chargingPower)")
    println("Remaining energy on departure (if departed): $(ev.departureWorkload)")
    println("Comppletion time (if completed): $(ev.completionTime)")

end

function Base.show(stats::ChargingStationStatistics)

    println("The charging station performance was:")
    println("Avg. charging: $(stats.avgCharging)")
    println("Avg. already charged: $(stats.avgAlreadyCharged)")
    println("Avg. reneged work: $(stats.avgW)")
    println("Missed deadline probability: $(stats.pD)")
    println("Blocking probability: $(stats.pB)")
end

function Base.show(sim::Simulation)

    println("An EV simulation with:")
    for key in keys(sim.parameters)
        println("\t$key: \t\t $(sim.parameters[key])")
    end

end

"""
function savesim(sim::Simulation, file::String)

    Saves simulation to a file.
"""
function savesim(sim::Simulation, file::String)
    io=open(file,"w");
    serialize(io,sim);
    close(io);
end

"""
function loadsim(file::String)

    Load simulation from a file.
"""
function loadsim(file::String)
    io=open(file,"r");
    sim::Simulation = deserialize(io);
    close(io);
    return sim;
end
