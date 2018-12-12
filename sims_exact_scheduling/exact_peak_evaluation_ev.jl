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

#exact = loadsim("sims_exact_scheduling/exact.sim")

exact = ev_exact_trace(arribos,trabajos,partidas,potencias,C,snapshots=[Tfinal])

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
    P[i,idx].=potencias[i];
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
                Plots.Linear(exact.timetrace.T[1:end]/3600,exact.timetrace.P[1:end], style="solid,mark=none,blue", legendentry="Exact Scheduling"),
                Plots.Linear(parallel.timetrace.T[1:end]/3600,parallel.timetrace.P[1:end], style="solid,mark=none,red", legendentry="Immediate service"),
                Plots.Linear(peak.timetrace.T[1:end]/3600,peak.timetrace.P[1:end], style="solid,mark=none,black", legendentry="Online peak"),
                Plots.Linear(t[1:end-1]/3600,peak_offline[1:end], style="solid,mark=none,green", legendentry="Offline peak"),
           ],
           legendPos="north east", xlabel="Time (h)", ylabel="Power (kW)", xmin=0,xmax=24, ymin=0,width="0.8\\columnwidth", height="0.48\\columnwidth"
    );

save("/home/andres/Documentos/Charlas/performance18_exactscheduling/figuras/peak_shaving_ev.tex",fig,include_preamble=false)


fig = Axis([
            Plots.Linear(t2[1:end]/3600,p2[1:end], style="solid,mark=none,green", legendentry="Offline peak"),
           ],
           legendPos="south east", xlabel="Time", ylabel="Power", xmin=10,xmax=40,#width="0.7\\columnwidth", height="0.4\\columnwidth"
    );

save("/home/andres/Escritorio/pruebas/test.tex",fig,include_preamble=true)
