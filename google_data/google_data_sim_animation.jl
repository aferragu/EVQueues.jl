push!(LOAD_PATH,"simulator")
using EVQueues, CSV, DataFrames, Plots, ProgressMeter

function population_plot(i)
    p = plot(   xlims=(0,snaps[end]/3600),
                ylims=(0,maximum(sim_edf.X+sim_edf.Y)),
                xlabel="Time (hours)",
                ylabel="# vehicles",
                title="Vehicles in the system",
                legendfont = Plots.Font("sans-serif",9,:hcenter,:vcenter,0.0,RGB{U8}(0.0,0.0,0.0))
                );
    #total pop
    plot!(p, sim_edf.T[sim_edf.T.<snaps[i]]/3600, sim_edf.X[sim_edf.T.<snaps[i]]+sim_edf.Y[sim_edf.T.<snaps[i]],color=:black,label="Total",linewidth=2);

    #pop for each policy
    plot!(p, sim_edf.T[sim_edf.T.<snaps[i]]/3600, sim_edf.X[sim_edf.T.<snaps[i]],color=:blue,label="EDF",linewidth=1);
    plot!(p, sim_llf.T[sim_llf.T.<snaps[i]]/3600, sim_llf.X[sim_llf.T.<snaps[i]],color=:red,label="LLF",linewidth=1);
    plot!(p, sim_llr.T[sim_llr.T.<snaps[i]]/3600, sim_llr.X[sim_llr.T.<snaps[i]],color=:green,label="LLR",linewidth=1);

    return p;
end

function fairness_plot(i)
    t=snaps[snaps.<snaps[i]]*1.0;

    p = plot(   xlim=(0,snaps[end]/3600),
                ylim=(0,1),
                xlabel="Time",
                ylabel="J",
                title="Fairness index",
                legendfont = Plots.Font("sans-serif",10,:hcenter,:vcenter,0.0,RGB{U8}(0.0,0.0,0.0)));

    Jedf=compute_fairness(sim_edf,t,1800.0);
    Jllf=compute_fairness(sim_llf,t,1800.0);
    Jllr=compute_fairness(sim_llr,t,1800.0);

    plot!(p,t/3600,Jedf,color=:blue,label="EDF",linewidth=2)
    plot!(p,t/3600,Jllf,color=:red,label="LLF",linewidth=2)
    plot!(p,t/3600,Jllr,color=:green,label="LLR",linewidth=2)

    return p;
end

function state_space_plot(sim,snaps,i, label)
    w=sim.workloads[i]/3600;
    d=sim.deadlinesON[i]/3600;
    u=sim.U[i];

    p=scatter( xlims = (0,3*mean(trabajos)/3600),
                ylims = (0,3*mean(partidas-arribos)/3600),
                xlabel="Remaining workload (hours)",
                ylabel="Remaining soujourn time (hours)",
                title=label,
                legendfont = Plots.Font("sans-serif",8,:hcenter,:vcenter,0.0,RGB{U8}(0.0,0.0,0.0)),
                legend=:none
                );

    if length(w)>0
        scatter!(p,w[u.>0],d[u.>0],markershape=:circle,markersize=4,color=:blue,label="In service");
        scatter!(p,w[u.==0],d[u.==0],markershape=:circle,markersize=4,color=:red,label="Not in service");
    end

    return p;
end

##Leo datos para simulacion
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

step=Tfinal/(30*24);
snaps = collect(step:step:Tfinal);

#simula usando cada politica a partir de la traza.
sim_edf = ev_edf_trace(arribos,trabajos,partidas,C;snapshots=snaps)
sim_llf = ev_llf_trace(arribos,trabajos,partidas,C;snapshots=snaps)
sim_llr = ev_llr_trace(arribos,trabajos,partidas,C;snapshots=snaps)


prog=Progress(length(snaps), dt=1, desc="Creando animacion... ");


anim = @animate for i=1:length(snaps)

    #plot de cantidad de vehiculos en carga
    p1 = population_plot(i);
    p2 = fairness_plot(i);
    p3 = state_space_plot(sim_edf,snaps,i, "EDF");
    p4 = state_space_plot(sim_llf,snaps,i, "LLF");
    p5 = state_space_plot(sim_llr,snaps,i, "LLR");

#    l=@layout [[a;b] [c;d;e]];
    l=@layout [grid(2,1){0.66w} grid(3,1)];
    p=plot(p1,p2,p3,p4,p5,layout=l,size=(1200,900))
    #display(p);
    next!(prog);
end

gif(anim, "google_data/anim.gif", fps = 24)
