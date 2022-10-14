using EVQueues, Distributions, Plots

#Parameters
lambda=60.0;
mu=1.0;
gamma=1.0;
sigma=0.5;
C=Inf;
P=30.0
Tfinal=500.0;

work_rng=Exponential(1.0/mu);
laxity_rng=Exponential(1.0/gamma);
uncertainty_rng=Normal(0.0,sigma)

arr = PoissonArrivalProcess(lambda,work_rng,1.0; initialLaxity = laxity_rng, uncertainty = uncertainty_rng)
sta = ChargingStation(C,P,edfc_policy; snapshots=[Tfinal])
connect!(arr,sta)

params = Dict(
    "ArrivalRate" => lambda,
    "AvgEnergy" => 1.0/mu,
    "AvgDeadline" => 1.0/mu + 1.0/gamma,
    "SimTime" => Tfinal,
    "Capacity" => C,
    "Policy" => "EDFC",
    "uncertainiy_parameter" => sigma,
)

sim = Simulation([arr,sta], params)

simulate(sim, Tfinal)

#Show stats
show(compute_statistics(sta))

#TIme plot of occupation and power
p=plot(sta)
display(p)

#State space of the last snapshot
snap = sta.snapshots[end];

p=stateplot(snap.charging)
display(p)
