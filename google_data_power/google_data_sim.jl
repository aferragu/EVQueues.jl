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
sim_llr = ev_llr_trace(arribos,trabajos,partidas,potencias,C)
sim_llf = ev_llf_trace(arribos,trabajos,partidas,potencias,C)
sim_edf = ev_edf_trace(arribos,trabajos,partidas,potencias,C)

t=collect(60:60:Tfinal);
#media hora de ventana
h=1800.0;

J_llr=compute_fairness(sim_llr,t,h);
J_llf=compute_fairness(sim_llf,t,h);
J_edf=compute_fairness(sim_edf,t,h);

using Plots


p = plot(   xlabel = "Time",
            ylabel = "J",
            title = "Fairness measure",
            ylim = (0,1)
            )

plot!(p,t,J_llr,lw=2,label="LLR")
plot!(p,t,J_llf,lw=2,label="LLF")
plot!(p,t,J_edf,lw=2,label="EDF")

display(p)

p = plot(sim_llr.timetrace.T,sim_llr.timetrace.X)
display(p)
