function update_vehicle(ev::EVinstance,dt::Float64)

    ev.currentWorkload-=ev.currentPower*dt;
    ev.currentDeadline-=dt;

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
