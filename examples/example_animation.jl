using EVQueues, Plots, ProgressMeter

lambda=120.0;
mu=1.0;
gamma=0.5;
#C=80.0;
C=60.0;

Tfinal=60.0;

frames = 24*30;

snaps = collect(range(0.01,stop=Tfinal,length=frames));

sim = ev_edf(lambda,mu,gamma,Tfinal,C,snapshots=snaps)
compute_statistics!(sim)

prog=Progress(length(snaps), dt=1, desc="Creando animacion... ");

azulcito = RGB(0.0,140/256,240/256);

rojito = RGB(240/256,0.0,140/256);

anim = @animate for i=1:length(snaps)

    p=stateplot(sim.snapshots[i].charging, markercolor=[azulcito rojito], xlims=(0,3/mu), ylims=(0,3*(1/mu+1/gamma)))

    xlabel!(p,"Carga remanente");
    ylabel!(p,"Tiempo remanente");
    title!(p,"Población EV - "*sim.parameters["Policy"])

    next!(prog);
end

gif(anim, "/tmp/"*sim.parameters["Policy"]*".gif", fps = 24)
