function update_vehicle(ev::EVinstance,dt::Float64)

    ev.currentWorkload-=ev.currentPower*dt;
    ev.currentDeadline-=dt;
    ev.currentReportedDeadline-=dt;

end

function compute_average(f,T::Vector{Float64},X::Vector{Int64})
    return sum(f(X[1:end-1]).*diff(T))/T[end]
end

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

function fairness_index(sa,s)

    J=1.0;

    if length(sa)>0 && sum(sa)>0
        J = mean(sa./s).^2/(mean((sa./s).^2));
    end
    return J
end

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

const P=[2/3 -1/3 -1/3;-1/3 2/3 -1/3;-1/3 -1/3 2/3] 

function imbalance_measure(x)
    return x'*P*x
end

macro addpolicy(name::String)
    f1 = Symbol("ev_",name);
    f2 = Symbol("ev_",name,"_trace");
    f3 = Symbol("ev_",name,"_uncertain");
    policy = Symbol(name,"_policy");
    eval( quote


        function $f1(lambda,mu,gamma,Tfinal,C=Inf;snapshots=[Inf])
            ev_sim(lambda,mu,gamma,Tfinal,C,$policy,snapshots)
        end


        function $f2(arribos,demandas,salidas,potencias,C=Inf;snapshots=[Inf],salidaReportada=nothing)
            ev_sim_trace(arribos,demandas,salidas,potencias,$policy,C,snapshots,salidaReportada=salidaReportada)
        end

        function $f2(df::DataFrame,C=Inf;snapshots=[Inf])
            ev_sim_trace(df,$policy,C,snapshots)
        end

        function $f3(lambda,mu,gamma,Tfinal,C=Inf,uncertainity_paramter=0.0;snapshots=[Inf])
            ev_sim_uncertain(lambda,mu,gamma,Tfinal,C,$policy,uncertainity_paramter,snapshots)
        end

        export $f1, $f2, $f3
        export $policy

    end)
end

function get_policy_name(policy::Function)

    name = String(Symbol(policy));
    name = split(name,"_")[1];
    uppercase(name);

end

##Genera una traza de arribos Poisson como la que se usa en ev_sim para pasarle
#al ev_sim_trace. De este modo se puede fijar la traza de vehiculos. Devuelve un
#dataframe de arribos.
function generate_Poisson_stream(lambda,mu,gamma,Tfinal)

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

function savesim(sim::Simulation, file::String)
    io=open(file,"w");
    serialize(io,sim);
    close(io);
end

function loadsim(file::String)
    io=open(file,"r");
    sim::Simulation = deserialize(io);
    close(io);
    return sim;
end
