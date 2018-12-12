push!(LOAD_PATH,"simulator")
using EVQueues, PGFPlots

lambda=30.0;
mu=1.0;
gamma=1/3;
C=Inf;

Tfinal=60.0;


#exact = loadsim("sims_exact_scheduling/exact.sim")

exact = ev_exact(lambda,mu,gamma,Tfinal,C,snapshots=[Tfinal])

EVs = [exact.EVs;exact.snapshots[1].charging];

arribos = [ev.arrivalTime for ev in EVs];
trabajos = [ev.requestedEnergy for ev in EVs];
partidas = [ev.departureTime for ev in EVs];

perm = sortperm(arribos);
arribos=arribos[perm];
trabajos=trabajos[perm];
partidas=partidas[perm];

potencias = ones(size(arribos));

parallel = ev_parallel_trace(arribos,trabajos,partidas,potencias,C,snapshots=[Tfinal]);

peak = ev_peak_trace(arribos,trabajos,partidas,potencias,C,snapshots=[Tfinal])

#parallel = loadsim("sims_exact_scheduling/parallel.sim")
#peak = loadsim("sims_exact_scheduling/peak.sim")

t=sort([arribos;partidas]);
dt=diff(t);

m=length(arribos);
n=length(dt);
P=zeros(m,n);
for i=1:m
    idx = findall( partidas[i].>t.>=arribos[i]);
    P[i,idx].=1;
end

using JuMP, Gurobi
model=Model(solver=GurobiSolver())

@variable(model,x[1:m,1:n]>=0);
@variable(model,auxvar);

@constraint(model,[i=1:m,j=1:n],x[i,j]<=P[i,j]);
@constraint(model,[i=1:m],sum(x[i,:].*dt)==trabajos[i]);
@constraint(model,[j=1:n],sum(x[:,j])<=auxvar);

@objective(model,Min,auxvar)

solve(model);

peak_offline=sum(getvalue(x),dims=1);
peak_offline=peak_offline[:];

fig = Axis([
                Plots.Linear(exact.timetrace.T[1:5:end],exact.timetrace.P[1:5:end], style="solid,mark=none,blue", legendentry="Exact Scheduling"),
                Plots.Linear(parallel.timetrace.T[1:5:end],parallel.timetrace.P[1:5:end], style="solid,mark=none,red", legendentry="Immediate service"),
                Plots.Linear(peak.timetrace.T[1:5:end],peak.timetrace.P[1:5:end], style="solid,mark=none,black", legendentry="Online peak"),
                Plots.Linear(t[1:5:end-1],peak_offline[1:5:end], style="solid,mark=none,green", legendentry="Offline peak"),
           ],
           legendPos="south east", xlabel="Time", ylabel="Power", xmin=0,xmax=60,#width="0.7\\columnwidth", height="0.4\\columnwidth"
    );

save("/home/andres/Documentos/Charlas/performance18_exactscheduling/figuras/peak_shaving.tex",fig,include_preamble=false)

#
# fig = Axis([
#                 Plots.Linear(exact.timetrace.T[1:2:end],exact.timetrace.X[1:2:end], style="solid,mark=none,blue", legendentry="Exact Scheduling"),
#                 Plots.Linear(parallel.timetrace.T[1:2:end],parallel.timetrace.X[1:2:end], style="solid,mark=none,red", legendentry="Immediate service"),
#             #    Plots.Linear(peak.timetrace.T[1:3:end],peak.timetrace.X[1:3:end], style="solid,mark=none,black", legendentry="Online peak"),
#            ],
#            legendPos="south east", xlabel="Time", ylabel="Power", xmin=10,xmax=40,#width="0.7\\columnwidth", height="0.4\\columnwidth"
#     );
#
# save("/home/andres/Escritorio/pruebas/test.tex",fig,include_preamble=true)
