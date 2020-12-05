using EVQueues, Plots

lambda=120.0;
mu=1.0;
gamma=1.0;
C=60.0;

Tfinal=1000.0;


sim = ev_edf(lambda,mu,gamma,Tfinal,C,snapshots=[Tfinal])
compute_statistics!(sim)


#TIme plot of occupation and power
p=plot(sim.timetrace)
display(p)

#CDF of departure attained workloads
p=servicecdf(sim.EVs)
display(p)

#State space of the last snapshot
snap = sim.snapshots[end];

p=stateplot(snap.charging)
display(p)

#fairness measure over time

t=collect(0:10:Tfinal);
h=20.0;
J=compute_fairness(sim,t,h)

p = plot(   xlabel = "Time",
            ylabel = "J",
            title = "Fairness measure",
            ylim = (0,1)
            )

plot!(p,t,J,lw=2,legend=:none)

display(p)
