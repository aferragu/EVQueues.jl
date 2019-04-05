push!(LOAD_PATH,"simulator")
using EVQueues, Plots, Statistics

C=100.0;
mu=1.0;
gamma=1.0;
Nevs=20000;

lambda = 90.0;

println("Arrival rate: $lambda")
Tfinal = Nevs/lambda;
println("Tfinal: $Tfinal")

sim=ev_edf(lambda,mu,gamma,Tfinal,C,snapshots = collect(0:0.01:Tfinal))
compute_statistics!(sim);

t=[snap.t for snap in sim.snapshots];

tau=zeros(length(sim.snapshots));

for i=1:length(sim.snapshots)
    snap = sim.snapshots[i];
    ev = snap.charging;
    aux=filter(u->u.currentPower>0,ev);
    if(length(aux)>=C)
        tau[i]=maximum([ev.currentDeadline for ev in aux])
    else
        tau[i]=Inf;
    end

end


p=zeros(length(sim.snapshots));

for i=1:length(sim.snapshots)
    snap = sim.snapshots[i];
    evs = snap.charging;
    if(length(evs)>0)
        p[i]=sum([ev.currentPower for ev in evs])
    else
        p[i]=0.0;
    end

end

plot(t,p)

w = [ev.currentWorkload for ev in sim.snapshots[end].charging];
d = [ev.currentDeadline for ev in sim.snapshots[end].charging];
u = [ev.currentPower>0 for ev in sim.snapshots[end].charging];

scatter(w[u.>0],d[u.>0],markershape=:circle,color=:blue,label="En servicio",xlims = (0,4), ylims = (0,3), size=(1000,600));
scatter!(w[u.==0],d[u.==0],markershape=:circle,color=:red,label="En espera");
