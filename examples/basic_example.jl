using EVQueues, Distributions, Plots

#Parameters
lambda=120.0;
mu=1.0;
gamma=1.0;
C=Inf;
P=60.0
Tfinal=1000.0;

work_distribution = Exponential(1/mu)
laxity_distribution = Exponential(1/gamma)

#Agents
arr = PoissonArrivalProcess(lambda, work_distribution, 1.0; initialLaxity = laxity_distribution)
sta = ChargingStation(C, P, edf_policy, snapshots=[Tfinal])
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

sim = Simulation([arr,sta], params=params)

#Simulate
simulate(sim, Tfinal)

#Show stats
show(compute_statistics(sta))

#TIme plot of occupation and power
p=plot(sta)
display(p)

#CDF of departure attained workloads
p=servicecdf(sta.completedEVs)
display(p)

#State space of the last snapshot
snap = sta.snapshots[end];

p=stateplot(snap.charging)
display(p)

#fairness measure over time

t=collect(0:10:Tfinal);
h=20.0;
J=compute_fairness(sta,t,h)

p = plot(   xlabel = "Time",
            ylabel = "J",
            title = "Fairness measure",
            ylim = (0,1)
            )

plot!(p,t,J,lw=2,legend=:none)
display(p)
