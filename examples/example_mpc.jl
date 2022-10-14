using EVQueues, Distributions, Plots, JuMP, GLPK

### MPC peak minimizer policy.
function peak_policy(evs::Array{EVinstance},C::Number)

    U=zeros(length(evs));

    idx = sortperm([ev.currentReportedDeadline for ev in evs]);

    sigma = [ev.currentWorkload for ev in evs][idx];
    tau = [ev.currentReportedDeadline for ev in evs][idx];
    deltat=diff([0;tau]);
    power = [ev.chargingPower for ev in evs][idx];
    n=length(evs);

    m=Model(GLPK.Optimizer)

    @variable(m,x[1:n,1:n]>=0)
    @variable(m,auxvar)

    @constraint(m,[i=1:n,j=i+1:n],x[i,j]==0)

    @constraint(m,[i=1:n,j=1:i],x[i,j]<=power[i])
    @constraint(m,[i=1:n],sum(x[i,:].*deltat)==sigma[i])
    @constraint(m,sum(x,dims=1).<=auxvar)

    @objective(m,Min,auxvar)

    optimize!(m)

    U[idx] = max.(value.(x)[:,1],0.0);

    for i=1:length(evs)
        evs[i].currentPower = U[i]
    end

    return sum(U);

end

#Parameters
lambda=20.0;
mu=1.0;
gamma=0.5;
C=Inf;
P=Inf;
Tfinal=24.0;

work_distribution = Exponential(1/mu)
laxity_distribution = Exponential(1/gamma)

#Agents
arr = PoissonArrivalProcess(lambda, work_distribution, 1.0; initialLaxity = laxity_distribution)
sta = ChargingStation(C, P, peak_policy)
connect!(arr,sta)

params = Dict(
        "ArrivalRate" => lambda,
        "AvgEnergy" => 1.0/mu,
        "AvgDeadline" => 1.0/mu + 1.0/gamma,
        "SimTime" => Tfinal,
        "Capacity" => C,
        "MaxPower" => P,
        "Policy" => "EDF",
    )

sim = Simulation([arr,sta], params)

#Simulate
simulate(sim, Tfinal)

#Show stats
show(compute_statistics(sta))

#TIme plot of occupation and power
p=plot(sta)
display(p)
