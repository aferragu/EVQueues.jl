push!(LOAD_PATH,"simulator")
using EVQueues, CSV, DataFrames, PyPlot

data = CSV.read("google_data/Google_Test_Data_pot.csv",
                datarow=1,
                header=["arribo", "arriboAbsoluto", "permanencia", "tiempoCarga"],
                types=[Float64, Float64, Float64, Float64])

#ordeno por arribo
sort!(data);

arribos = data[:arribo];
partidas = data[:arribo]+data[:permanencia];
trabajos = data[:tiempoCarga];

C=3000;

#simula usando edf a partir de la traza. Cambiar edf por llf, llr, pf, parallel para las otras politicas.
sim = ev_llf_trace(arribos,trabajos,partidas,C)
compute_statistics!(sim)

#Ploteo la salida como escalera. where=post es para que se mantenga constante a la derecha del intervalo.
#sim.X tiene los vehiculos cargando.
#sim.Y tiene los vehiculos finalizados.
PyPlot.step(sim.T,sim.X,where="post")
PyPlot.step(sim.T,sim.Y,where="post")

figure()

worig = sim.W[:,1];
sworig=sort(worig);
k=length(sworig);
PyPlot.plot(sworig,(1:k)/k,drawstyle="steps")

figure()
rW = sim.W[:,2];
sW=sort(rW);
k=length(sW);
PyPlot.plot(sW,(1:k)/k,drawstyle="steps")
