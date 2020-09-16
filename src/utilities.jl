function update_vehicle(ev::EVinstance,dt::Float64)

    ev.currentWorkload-=ev.currentPower*dt;
    ev.currentDeadline-=dt;
    ev.currentReportedDeadline-=dt;

end

function compute_average(f,T::Vector{Float64},X::Vector{UInt16})
    return sum(f(X[1:end-1]).*diff(T))/T[end]
end

function compute_statistics!(sim::EVSim)
    sim.stats.avgX = compute_average(x->x,sim.timetrace.T,sim.timetrace.X);
    sim.stats.avgY = compute_average(x->x,sim.timetrace.T,sim.timetrace.Y);

    sim.stats.avgW = mean([ev.departureWorkload for ev in sim.EVs]);

    rangeX = collect(minimum(sim.timetrace.X):maximum(sim.timetrace.X))
    pX = [compute_average(x->x.==l,sim.timetrace.T,sim.timetrace.X) for l in rangeX]
    sim.stats.rangeX = rangeX;
    sim.stats.pX=pX;

    rangeY = collect(minimum(sim.timetrace.Y):maximum(sim.timetrace.Y))
    pY = [compute_average(x->x.==l,sim.timetrace.T,sim.timetrace.Y) for l in rangeY]
    sim.stats.rangeY = rangeY;
    sim.stats.pY=pY;

    sim.stats.pD = sum([ev.departureWorkload>0 for ev in sim.EVs])/length(sim.EVs);

    return nothing
end

function fairness_index(sa,s)

    J=1.0;

    if length(sa)>0 && sum(sa)>0
        J = mean(sa./s).^2/(mean((sa./s).^2));
    end
    return J
end

function compute_fairness(sim::EVSim,t::Vector{Float64},h::Float64)

    J=zeros(length(t))

    for i=1:length(t)

        evs = filter(ev->(ev.completionTime<=t[i])&&(ev.completionTime>=t[i]-h),sim.EVs);
        sa = [ev.requestedEnergy-ev.departureWorkload for ev in evs];
        s = [ev.requestedEnergy for ev in evs];

        J[i] = fairness_index(sa,s);

    end
    return J;
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


        function $f2(arribos,demandas,salidas,potencias,C=Inf;snapshots=[Inf])
            ev_sim_trace(arribos,demandas,salidas,potencias,$policy,C,snapshots)
        end

        function $f3(lambda,mu,gamma,Tfinal,C=Inf,uncertainity_paramter=0.0;snapshots=[Inf])
            ev_sim_uncertain(lambda,mu,gamma,Tfinal,C,$policy,uncertainity_paramter,snapshots)
        end

        export $f1, $f2, $f3

    end)
end

function get_policy_name(policy::Function)

    name = String(Symbol(policy));
    name = split(name,"_")[1];
#    name = split(name,".")[2];
    uppercase(name);

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
