push!(LOAD_PATH,"simulator")
using EVQueues, PGFPlots

lambda=50.0;
mu=1.0;
gamma=1/3;
#C=80.0;
C=Inf;

Tfinal=24.0;


sim = ev_exact(lambda,mu,gamma,Tfinal,C,snapshots=[Tfinal])
compute_statistics!(sim)

t=sim.timetrace.T;
x=sim.timetrace.X;
y=sim.timetrace.Y;
p=sim.timetrace.P;

fig = Axis([    Plots.Linear(t[1:10:end],p[1:10:end], style="solid,mark=none,thick,verdecito!50!white"),
           ],
           legendPos="south east", xlabel="Tiempo", ylabel="\\# Cargadores activos (potencia)", xmin=0, xmax=24, ymin=0,ymax=75, width="\\columnwidth"
    );

save("/home/andres/Documentos/Charlas/cugre18/figuras/exact_scheduling.tex",fig,include_preamble=false)
