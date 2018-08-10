push!(LOAD_PATH,"simulator")
using EVQueues, CSV, DataFrames, Plots, ProgressMeter

data = CSV.read("google_data/Google_Test_Data_filtered.csv",
                datarow=2,
                header=["arribo", "arriboAbsoluto", "permanencia", "tiempoCarga"],
                types=[Float64, Float64, Float64, Float64])

#ordeno por arribo
sort!(data, [:arriboAbsoluto]);

#filtro 2 dias de autos
Tfinal = 86400;
idx = data[:arriboAbsoluto].<Tfinal;

arribos = data[idx,:arriboAbsoluto];
partidas = data[idx,:arriboAbsoluto]+data[idx,:permanencia];
trabajos = data[idx,:tiempoCarga];

C=30;

snaps = collect(120:120:Tfinal);
#simula usando edf a partir de la traza. Cambiar edf por llf, llr, pf, parallel para las otras politicas.
sim = ev_llr_trace(arribos,trabajos,partidas,C;snapshots=snaps)
compute_statistics!(sim)


prog=Progress(length(snaps), dt=1, desc="Creando animacion... ");

J=zeros(length(snaps));

anim = @animate for i=1:length(snaps)

    #plot de cantidad de vehiculos en carga
    p1 = plot(sim.T[sim.T.<snaps[i]],sim.X[sim.T.<snaps[i]],xlims=(0,Tfinal),ylims=(0,maximum(sim.X)),color=:blue,legend=:none,linewidth=3)

    #Fairness index de los que terminan
    t=snaps[snaps.<snaps[i]]*1.0;
    J=compute_fairness(sim,t,1800.0);

    p2 = plot(legend=:none,xlim=(0,Tfinal),ylim=(0,1))

    plot!(p2,t,J,line=:steppost,color=:blue,linewidth=3)

    w=sim.workloads[i];
    d=sim.deadlinesON[i];
    u=sim.U[i];

    p3=scatter(xlims = (0,3*mean(trabajos)), ylims = (0,3*mean(partidas-arribos)));

    if length(w)>0
        scatter!(p3,w[u.>0],d[u.>0],markershape=:square,color=:blue,legend=:none);
        scatter!(p3,w[u.==0],d[u.==0],markershape=:square,color=:red,legend=:none);
    end

    l=@layout [[a;b] c];
    p=plot(p1,p2,p3,layout=l,size=(1600,800))
    #display(p);
    next!(prog);
end

gif(anim, "google_data/anim.gif", fps = 24)
