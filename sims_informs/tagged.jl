push!(LOAD_PATH,"simulator")
using EVQueues, Plots

lambda=40.0;
mu=1.0;
gamma=0.5;
C=20.0;

Tfinal=50.0;

snaps = collect(0:.01:Tfinal)

sim = ev_lifo(lambda,mu,gamma,Tfinal,C,snapshots=snaps)
compute_statistics!(sim)


d=Dict{Float64,Array{Array{Float64,1},1}}();

for i=1:length(sim.snapshots)

    charging = sim.snapshots[i].charging;

    for j=1:length(charging)

        index = charging[j].arrivalTime;

        if haskey(d,index)
            push!(d[index],[sim.snapshots[i].t-charging[j].arrivalTime;charging[j].currentWorkload;charging[j].currentDeadline])
        else
            d[index] = [];
        end
    end
end

d=sort(collect(d), by=x->x[1])

d=[v[2] for v in d]

p=plot();

using StatsBase

K = sample((500:1500),100)

for k=K

    trace = d[k];

    t = [z[1] for z in trace]
    sigma = [z[2] for z in trace]
    tau = [z[3] for z in trace]

    p=plot!(t,sigma)
    #p=plot!(t,tau)
end

display(p)
