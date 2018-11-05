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

#C=30*mean(potencias);
C=Inf;

sim = ev_peak_trace(arribos,trabajos,partidas,potencias,C)

#using Plots

#p = plot(sim.timetrace.T/3600,sim.timetrace.P)
#display(p)
