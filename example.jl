push!(LOAD_PATH,"simulator")
using EVQueues, Plots

lambda=120.0;
mu=1.0;
gamma=1.0;
C=60.0;

Tfinal=1000.0;


sim = ev_mw(lambda,mu,gamma,Tfinal,C,snapshots=[Tfinal])
compute_statistics!(sim)


#TIme plot of occupation and power
p1 = plot(  xlabel="Time",
            ylabel="# vehicles",
            title="Vehicles in charge")

plot!(p1, sim.timetrace.T, sim.timetrace.X,lt=:steppost,linewidth=2,legend=:none);

p2 = plot(  xlabel="Time",
            ylabel="# vehicles",
            title="Vehicles already charged")

plot!(p2, sim.timetrace.T, sim.timetrace.Y,lt=:steppost,linewidth=2,legend=:none);

p3 = plot(  xlabel="Time",
            ylabel="P (kW)",
            title="Consumed power")

plot!(p3, sim.timetrace.T, sim.timetrace.P,lt=:steppost,linewidth=2,legend=:none);

l=@layout [a;b;c];
p=plot(p1,p2,p3,layout=l)
display(p)

#CDF of departure attained workloads

Sa = sort([ev.departureWorkload for ev in sim.EVs]);
n = length(Sa);
p = plot(   xlabel="w (kWh)",
            ylabel="P(Sa⩽w)",
            title="Attained work CDF")

plot!(p,Sa,(1:n)/n,lt=:steppost,legend=:none)
display(p)

#State space of the last snapshot
snap = sim.snapshots[end];

w = [ev.currentWorkload for ev in snap.charging];
d = [ev.currentDeadline for ev in snap.charging];
on = [ev.currentPower>0 for ev in snap.charging];

p = plot(   xlabel = "Remaining workload",
            ylabel = "Remaining soj. time",
            title = "State-space snapshot")

scatter!(p,w[on.==true],d[on.==true],markershape=:circle,markersize=4,color=:blue,label="In service")
scatter!(p,w[on.==false],d[on.==false],markershape=:circle,markersize=4,color=:red,label="Not in service")

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
