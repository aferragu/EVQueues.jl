push!(LOAD_PATH,"simulator")
using EVQueues, Plots, Statistics

C=1.0;
mu=1.0;
gamma=0.5;
Nevs=500;

lambda = 1.0;

println("Arrival rate: $lambda")
Tfinal = Nevs/lambda;

sim=ev_parallel(lambda,mu,gamma,Tfinal,C,snapshots = collect(0:0.1:Tfinal))
compute_statistics!(sim);

t=[snap.t for snap in sim.snapshots];
w=[sum([ev.currentWorkload for ev in snap.charging]) for snap in sim.snapshots];

plot(t,w)
