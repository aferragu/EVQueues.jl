push!(LOAD_PATH,"simulator")
using EVQueues, PyPlot

#tiempos de llegada. Debe estar ordenado.
arribos = [1.0;2.0;3.0];
#tiempos de partidas, correlativo al de arribos.
partidas = [12.0;13.0;14.0];
#tiempos de trabajo, correlativo al de arribos.
trabajos = [4.0;5.0;6.0];
#cantidad de cargadores.
C=1;

#simula usando edf a partir de la traza. Cambiar edf por llf, llr, pf, parallel para las otras politicas.
sim = ev_edf_trace(arribos,trabajos,partidas,C,snapshots=[2.0])
compute_statistics!(sim)

#Ploteo la salida como escalera. where=post es para que se mantenga constante a la derecha del intervalo.
#sim.X tiene los vehiculos cargando.
#sim.Y tiene los vehiculos finalizados.
PyPlot.step(sim.T,sim.X,where="post")
PyPlot.step(sim.T,sim.Y,where="post")
