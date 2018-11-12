push!(LOAD_PATH,"simulator")
using EVQueues, CSV, DataFrames

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

#C=30*mean(potencias);
C=150.0;

#simula usando edf a partir de la traza. Cambiar edf por llf, llr, pf, parallel para las otras politicas.
sim_llr = ev_llr_trace(arribos,trabajos,partidas,potencias,C;snapshots=[47000.0])
sim_llf = ev_llf_trace(arribos,trabajos,partidas,potencias,C;snapshots=[47000.0])
sim_edf = ev_edf_trace(arribos,trabajos,partidas,potencias,C;snapshots=[47000.0])

t=collect(60:60:Tfinal);
#media hora de ventana
h=1800.0;

J_llr=compute_fairness(sim_llr,t,h);
J_llf=compute_fairness(sim_llf,t,h);
J_edf=compute_fairness(sim_edf,t,h);

using PGFPlots

fig = Axis([
                Plots.Linear(t/3600,J_edf, style="solid,mark=none,blue", legendentry="EDF"),
                Plots.Linear(t/3600,J_llf, style="solid,mark=none,red", legendentry="LLF"),
                Plots.Linear(t/3600,J_llr, style="solid,mark=none,green", legendentry="LLR"),
           ],
           legendPos="south west", xlabel="Time (h)", ylabel="Fariness Index", xmin=0, xmax=24, ymin=0, ymax=1.1,
    );

save("/home/andres/Escritorio/google_fairness.tex",fig,include_preamble=false)

fig = Axis([
                Plots.Linear(sim_edf.timetrace.T/3600,sim_edf.timetrace.X+sim_edf.timetrace.Y, style="solid,mark=none,blue"),
           ],
           legendPos="south west", xlabel="Time (h)", ylabel="\\# of vehicles", xmin=0, xmax=24, ymin=0,
    );

save("/home/andres/Escritorio/google_evs.tex",fig,include_preamble=false)


sim2 = ev_parallel_trace(arribos,trabajos,partidas,potencias,Inf)

fig = Axis([
                Plots.Linear(sim2.timetrace.T/3600,sim2.timetrace.P, style="solid,mark=none,blue"),
           ],
           legendPos="south west", xlabel="Time (h)", ylabel="Requested Power", xmin=0, xmax=24, ymin=0,
    );

save("/home/andres/Escritorio/google_power.tex",fig,include_preamble=false)

snap = sim_edf.snapshots[1].charging;
w = [ev.currentWorkload for ev in snap]./[ev.chargingPower for ev in snap]/3600;
d = [ev.currentDeadline for ev in snap]/3600;
on = [ev.currentPower>0 for ev in snap];

tau = maximum(d[on]);

fig = Axis([
                Plots.Linear(w[on.==true],d[on.==true], style="mark=o,only marks,azulcito",legendentry="In service"),
                Plots.Linear(w[on.==false],d[on.==false], style="mark=x,only marks,rojito",legendentry="Not in service"),
                Plots.Linear([0;8],[tau,tau],style="dashed,thick,black,mark=none"),
           ],
           legendPos="north west", xlabel="\\sigma (h)", ylabel="\\ŧau (h)", title="EDF",xmin=0,ymin=0,xmax=8,ymax=5,width="\\graphwidth",height="\\graphheight"
    );


save("/home/andres/Escritorio/edf_statespace.tex",fig,include_preamble=false)


snap = sim_llf.snapshots[1].charging;
w = [ev.currentWorkload for ev in snap]./[ev.chargingPower for ev in snap]/3600;
d = [ev.currentDeadline for ev in snap]/3600;
on = [ev.currentPower>0 for ev in snap];

sigma = maximum(-d[on]+w[on]);

fig = Axis([
                Plots.Linear(w[on.==true],d[on.==true], style="mark=o,only marks,azulcito",legendentry="In service"),
                Plots.Linear(w[on.==false],d[on.==false], style="mark=x,only marks,rojito",legendentry="Not in service"),
                Plots.Linear([sigma;8],[0,8-sigma],style="dashed,thick,black,mark=none"),
           ],
           legendPos="north west", xlabel="\\sigma (h)", ylabel="\\ŧau (h)", title="LLF",xmin=0,ymin=0,xmax=8,ymax=5,width="\\graphwidth",height="\\graphheight"
    );

save("/home/andres/Escritorio/llf_statespace.tex",fig,include_preamble=false)


snap = sim_llr.snapshots[1].charging;
w = [ev.currentWorkload for ev in snap]./[ev.chargingPower for ev in snap]/3600;
d = [ev.currentDeadline for ev in snap]/3600;
on = [ev.currentPower>0 for ev in snap];

theta = maximum(d[on]./w[on])

fig = Axis([
                Plots.Linear(w[on.==true],d[on.==true], style="mark=o,only marks,azulcito",legendentry="In service"),
                Plots.Linear(w[on.==false],d[on.==false], style="mark=x,only marks,rojito",legendentry="Not in service"),
                Plots.Linear([0;8],[0,theta*8],style="dashed,thick,black,mark=none"),
           ],
           legendPos="north west", xlabel="\\sigma (h)", ylabel="\\ŧau (h)", title="LLR",xmin=0,ymin=0,xmax=8,ymax=5,width="\\graphwidth",height="\\graphheight"
    );

save("/home/andres/Escritorio/llr_statespace.tex",fig,include_preamble=false)
