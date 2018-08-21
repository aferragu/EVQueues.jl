push!(LOAD_PATH,"simulator")
using EVQueues, Plots, ProgressMeter

lambda=120.0;
mu=1.0;
gamma=0.5;
C=80;

Tfinal=100.0;
snaps = collect(0.1:.5:100.0);

sim = ev_llf(lambda,mu,gamma,Tfinal,C,snapshots=snaps)

prog=Progress(length(snaps), dt=1, desc="Creando animacion... ");


anim = @animate for i=1:length(snaps)

    #plot de cantidad de vehiculos en carga
    p1 = plot(sim.T[sim.T.<snaps[i]],sim.X[sim.T.<snaps[i]],xlims=(0,Tfinal),ylims=(0,maximum(sim.X)),color=:blue,legend=:none)

    #CDF de las cargas remanentes
    j=sim.J[i];
    sw = sort(sim.W[max(1,j-200):j,2]);
    n=length(sw);


    p2 = plot(sw,(1:n)/n,line=:steppost,color=:blue,legend=:none,xlim=(0,1))

    w=sim.workloads[i];
    d=sim.deadlinesON[i];
    u=sim.U[i];

    p3=scatter(w[u.>0],d[u.>0],markershape=:square,color=:blue,legend=:none,xlims = (0,5/mu), ylims = (0,5/gamma));
    scatter!(p3,w[u.==0],d[u.==0],markershape=:square,color=:red,legend=:none);

    l=@layout [[a;b] c];
    p=plot(p1,p2,p3,layout=l,size=(1600,800))
    #display(p);
    next!(prog);
end

gif(anim, "/home/andres/Escritorio/anim.gif", fps = 10)
