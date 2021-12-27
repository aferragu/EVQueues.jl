using EVQueues, Plots, Random

lambda=120.0;
mu=1.0;
gamma=0.5;

C=60.0;

Tfinal=1000.0;

sim = ev_edf(lambda,mu,gamma,Tfinal,C,snapshots=[Tfinal])
compute_statistics!(sim)

sim2 = ev_lifo(lambda,mu,gamma,Tfinal,C,snapshots=[Tfinal])
compute_statistics!(sim2)

att1 = [ev.requestedEnergy - ev.departureWorkload for ev in sim.EVs[30000:end]]
att2 = [ev.requestedEnergy - ev.departureWorkload for ev in sim2.EVs[30000:end]]

scatter(att1,att2)
