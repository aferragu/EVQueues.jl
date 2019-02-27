push!(LOAD_PATH,"simulator")
using EVQueues, CSV, DataFrames

data = CSV.read("google_data_power/Google_Test_Data_f.csv",
#                datarow=2,
#                header=["arribo", "arriboAbsoluto", "permanencia", "tiempoCarga"],
                types=[Float64, Float64, Float64, Float64, Float64, Float64])

#filtro hasta Tfinal
Tfinal = 86400.0;

data = filter!(row->row[:arribosAbs]<Tfinal,data);

#ordeno por arribo
sort!(data, [:arribosAbs]);

arribos = data[:,:arribosAbs];
partidas = data[:,:arribosAbs]+data[:,:estadia];
trabajos = data[:,:Energia]*3600;
potencias = data[:,:Potencia];

C=150.0;

#simula usando edf a partir de la traza. Cambiar edf por llf, llr, pf, parallel para las otras politicas.
sim_fifo = ev_fifo_trace(arribos,trabajos,partidas,potencias,C)
sim_llr = ev_llr_trace(arribos,trabajos,partidas,potencias,C)

t=collect(60:60:Tfinal);
#media hora de ventana
h=1800.0;

J_fifo=compute_fairness(sim_fifo,t,h);
J_llr=compute_fairness(sim_llr,t,h);

using Plots


p = plot(   xlabel = "Time",
            ylabel = "J",
            title = "Fairness measure",
            ylim = (0,1)
            )

plot!(p,t,J_fifo,lw=2,label=sim_fifo.parameters["Policy"])
plot!(p,t,J_llr,lw=2,label=sim_llr.parameters["Policy"])

display(p)

p = plot(sim_fifo.timetrace.T,sim_fifo.timetrace.X)
display(p)
