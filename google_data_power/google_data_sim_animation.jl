push!(LOAD_PATH,"simulator")
using EVQueues, CSV, DataFrames, Plots, ProgressMeter, Statistics

function population_plot(i)
    p = plot(   xlims=(0,snaps[end]/3600),
                ylims=(0,maximum(sim_edf.timetrace.X+sim_edf.timetrace.Y)),
                xlabel="Time (hours)",
                ylabel="# vehicles",
                title="Vehicles in the system",
#                legendfont = Plots.Font("sans-serif",9,:hcenter,:vcenter,0.0,RGB{U8}(0.0,0.0,0.0))
                );
    #total pop
    plot!(p, sim_edf.timetrace.T[sim_edf.timetrace.T.<snaps[i]]/3600, sim_edf.timetrace.X[sim_edf.timetrace.T.<snaps[i]]+sim_edf.timetrace.Y[sim_edf.timetrace.T.<snaps[i]],color=:black,label="Total",linewidth=2);

    #pop for each policy
    plot!(p, sim_edf.timetrace.T[sim_edf.timetrace.T.<snaps[i]]/3600, sim_edf.timetrace.X[sim_edf.timetrace.T.<snaps[i]],color=:blue,label="EDF",linewidth=1);
    plot!(p, sim_llf.timetrace.T[sim_llf.timetrace.T.<snaps[i]]/3600, sim_llf.timetrace.X[sim_llf.timetrace.T.<snaps[i]],color=:red,label="LLF",linewidth=1);
    plot!(p, sim_llr.timetrace.T[sim_llr.timetrace.T.<snaps[i]]/3600, sim_llr.timetrace.X[sim_llr.timetrace.T.<snaps[i]],color=:green,label="LLR",linewidth=1);

    return p;
end

function fairness_plot(i)
    t=snaps[snaps.<snaps[i]]*1.0;

    p = plot(   xlim=(0,snaps[end]/3600),
                ylim=(0,1),
                xlabel="Time",
                ylabel="J",
                title="Fairness index",
#                legendfont = Plots.Font("sans-serif",10,:hcenter,:vcenter,0.0,RGB{U8}(0.0,0.0,0.0)),
                legend = :bottomright
                );

    Jedf=compute_fairness(sim_edf,t,1800.0);
    Jllf=compute_fairness(sim_llf,t,1800.0);
    Jllr=compute_fairness(sim_llr,t,1800.0);

    plot!(p,t/3600,Jedf,color=:blue,label="EDF",linewidth=2)
    plot!(p,t/3600,Jllf,color=:red,label="LLF",linewidth=2)
    plot!(p,t/3600,Jllr,color=:green,label="LLR",linewidth=2)

    return p;
end

function state_space_plot(sim,i, label)

    w=[ev.currentWorkload/ev.chargingPower for ev in sim.snapshots[i].charging]/3600;
    d=[ev.currentDeadline for ev in sim.snapshots[i].charging]/3600;
    u=[ev.currentPower for ev in sim.snapshots[i].charging]

    p=scatter( xlims = (0,3*mean(trabajos)/mean(potencias)/3600),
                ylims = (0,3*mean(partidas-arribos)/3600),
                xlabel="Remaining workload (hours)",
                ylabel="Remaining soujourn time (hours)",
                title=label,
                legendfont = font("sans-serif",8),
                legend=:none
                );

    if length(w)>0
        scatter!(p,w[u.>0],d[u.>0],markershape=:circle,markersize=4,color=:blue,label="In service");
        scatter!(p,w[u.==0],d[u.==0],markershape=:circle,markersize=4,color=:red,label="Not in service");
    end

    return p;
end


data = CSV.read("google_data_power/Google_Test_Data_f.csv",
#                datarow=2,
#                header=["arribo", "arriboAbsoluto", "permanencia", "tiempoCarga"],
                types=[Float64, Float64, Float64, Float64, Float64, Float64])

#ordeno por arribo
sort!(data, [:arribosAbs]);

Tfinal = 86400.0;

#filtro 2 dias de autos
idx = data[:arribosAbs].<Tfinal;

arribos = data[idx,:arribosAbs];
partidas = data[idx,:arribosAbs]+data[idx,:estadia];
trabajos = data[idx,:Energia]*3600;
potencias = data[idx,:Potencia];

step=Tfinal/(30*24);
snaps = collect(step:step:Tfinal);

#C=30*mean(potencias);
C=150.0;

#simula usando edf a partir de la traza. Cambiar edf por llf, llr, pf, parallel para las otras politicas.
sim_llr = ev_las_trace(arribos,trabajos,partidas,potencias,C;snapshots=snaps)
sim_llf = ev_lifo_trace(arribos,trabajos,partidas,potencias,C;snapshots=snaps)
sim_edf = ev_edf_trace(arribos,trabajos,partidas,potencias,C;snapshots=snaps)

prog=Progress(length(snaps), dt=1, desc="Creando animacion... ");


anim = @animate for i=1:length(snaps)

    #plot de cantidad de vehiculos en carga
    p1 = population_plot(i);
    p2 = fairness_plot(i);
    p3 = state_space_plot(sim_edf,i, "EDF");
    p4 = state_space_plot(sim_llf,i, "LLF");
    p5 = state_space_plot(sim_llr,i, "LLR");

#    l=@layout [[a;b] [c;d;e]];
    l=@layout [grid(2,1){0.66w} grid(3,1)];
    p=plot(p1,p2,p3,p4,p5,layout=l,size=(1200,900))
    #display(p);
    next!(prog);
end

gif(anim, "/home/andres/Escritorio/anim.gif", fps = 24)
