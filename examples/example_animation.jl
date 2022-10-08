using EVQueues, Distributions, Plots, ProgressMeter

lambda=120.0;
mu=1.0;
gamma=0.5;
C=Inf
P=60.0;

Tfinal=60.0;

frames = 24*30;

snaps = collect(range(0.01,stop=Tfinal,length=frames));

work_distribution = Exponential(1/mu)
laxity_distribution = Exponential(1/gamma)

#Agents
arr = PoissonArrivalProcess(lambda, work_distribution, laxity_distribution, 1.0)
sta = ChargingStation(C, P, edf_policy, snapshots=snaps)
connect!(arr,sta)

params = Dict(
        "ArrivalRate" => lambda,
        "AvgEnergy" => 1.0/mu,
        "AvgDeadline" => 1.0/mu + 1.0/gamma,
        "SimTime" => Tfinal,
        "Capacity" => C,
        "MaxPower" => P,
        "Policy" => "EDF",
    )

sim = Simulation([arr,sta], params)

#Simulate
simulate(sim, Tfinal)

show(compute_statistics(sta))

prog=Progress(length(snaps), dt=1, desc="Creando animacion... ");

azulcito = RGB(0.0,140/256,240/256);

rojito = RGB(240/256,0.0,140/256);

anim = @animate for i=1:length(snaps)

    p=stateplot(sta.snapshots[i].charging, markercolor=[azulcito rojito], xlims=(0,3/mu), ylims=(0,3*(1/mu+1/gamma)))

    xlabel!(p,"Carga remanente");
    ylabel!(p,"Tiempo remanente");
    title!(p,"Población EV - "*sim.parameters["Policy"])

    next!(prog);
end

gif(anim, "/tmp/"*sim.parameters["Policy"]*".gif", fps = 24)
