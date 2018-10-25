push!(LOAD_PATH,"simulator")
using EVQueues, Plots, ProgressMeter

lambda=40.0;
mu=1.0;
gamma=1/3;
#C=80.0;
C=60.0;

Tfinal=60.0;

frames = 24*45;

snaps = collect(range(0.01,stop=Tfinal,length=frames));

sim = ev_parallel(lambda,mu,gamma,Tfinal,C,snapshots=snaps)
compute_statistics!(sim)

prog=Progress(length(snaps), dt=1, desc="Creando animacion... ");

azulcito = RGB(0.0,140/256,240/256);

rojito = RGB(240/256,0.0,140/256);


anim = @animate for i=1:length(snaps)

    w = [ev.currentWorkload for ev in sim.snapshots[i].charging];
    d = [ev.currentDeadline for ev in sim.snapshots[i].charging];
    u = [ev.currentPower>0 for ev in sim.snapshots[i].charging];

    p=scatter(w[u.>0],d[u.>0],markershape=:circle,color=azulcito,label="En servicio",xlims = (0,4), ylims = (0,3), size=(1000,600));
    scatter!(p,w[u.==0],d[u.==0],markershape=:circle,color=rojito,label="En espera");

    xlabel!(p,"Carga remanente");
    ylabel!(p,"Tiempo remanente");
    title!(p,"Población EV - Carga paralela - Baja carga")

    next!(prog);
end

gif(anim, "/home/andres/Escritorio/underload.gif", fps = 24)
