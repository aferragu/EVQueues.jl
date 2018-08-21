push!(LOAD_PATH,"simulator")
using EVQueues, CSV, DataFrames

data = CSV.read("google_data/Google_Test_Data_filtered.csv",
                datarow=2,
                header=["arribo", "arriboAbsoluto", "permanencia", "tiempoCarga"],
                types=[Float64, Float64, Float64, Float64])

#ordeno por arribo
sort!(data, [:arriboAbsoluto]);


Tfinal = 86400.0;

#filtro 2 dias de autos
idx = data[:arriboAbsoluto].<Tfinal;

arribos = data[idx,:arriboAbsoluto];
partidas = data[idx,:arriboAbsoluto]+data[idx,:permanencia];
trabajos = data[idx,:tiempoCarga];

C=30;

#simula usando edf a partir de la traza. Cambiar edf por llf, llr, pf, parallel para las otras politicas.
sim_llr = ev_llr_trace(arribos,trabajos,partidas,C)
sim_llf = ev_llf_trace(arribos,trabajos,partidas,C)
sim_edf = ev_edf_trace(arribos,trabajos,partidas,C)

t=collect(60:60:Tfinal);
#media hora de ventana
h=1800.0;

J_llr=compute_fairness(sim_llr,t,h);
J_llf=compute_fairness(sim_llf,t,h);
J_edf=compute_fairness(sim_edf,t,h);

using PGFPlots


fig = Axis([
    Plots.Linear(t/86400*24,J_llr, legendentry="LLR"),
    Plots.Linear(t/86400*24,J_llf, legendentry="LLF"),
    Plots.Linear(t/86400*24,J_edf, legendentry="EDF"),
    ], legendPos="north east", xlabel="time (hours)", ylabel="Fairness index", xmin=0.0, xmax=24, ymin=0, ymax=1.1)

save("fairness_index.tex",fig,include_preamble=false)
