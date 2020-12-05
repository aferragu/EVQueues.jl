using EVQueues, Plots

#tiempos de llegada. Debe estar ordenado.
arribos = [1.0;2.0;3.0];
#tiempos de partidas, correlativo al de arribos.
salidas = [12.0;13.0;14.0];
#tiempos de trabajo, correlativo al de arribos.
trabajos = [4.0;5.0;6.0];
#potencias
potencias = [1.0;1.0;1.0];
#cantidad de cargadores.
C=1.0;

#simula usando edf a partir de la traza. Cambiar edf por llf, llr, pf, parallel para las otras politicas.
sim = ev_edf_trace(arribos,trabajos,salidas,potencias,C,snapshots=[4.0])
compute_statistics!(sim)


#TIme plot of occupation and power
p=plot(sim.timetrace)
display(p)

#CDF of departure attained workloads
p=servicecdf(sim.EVs)
display(p)

#State space of the last snapshot
snap = sim.snapshots[end];

w = [ev.currentWorkload for ev in snap.charging];
d = [ev.currentDeadline for ev in snap.charging];
on = [ev.currentPower>0 for ev in snap.charging];

p = plot(   xlabel = "Remaining workload",
            ylabel = "Remaining soj. time",
            title = "State-space snapshot",
            xlims = (0,3*sim.parameters["AvgEnergy"]),
            ylims = (0,3*sim.parameters["AvgDeadline"])
            )

scatter!(p,w[on.==true],d[on.==true],markershape=:circle,markersize=4,color=:blue,label="In service")
scatter!(p,w[on.==false],d[on.==false],markershape=:circle,markersize=4,color=:red,label="Not in service")

display(p)
