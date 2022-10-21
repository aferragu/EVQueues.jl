using EVQueues, Distributions, Plots

default(size=(800,800))

function plot_positions(stations,i,xlims=(-1,1),ylims=(-1,1))

    p=plot(xlims=xlims, ylims=ylims, legend=:none, aspectratio=:equal, axis=([], false))

    for j in eachindex(stations)
        sta=stations[j]
        pos = sta.position
        incoming = sta.snapshots[i].incoming
        charging = sta.snapshots[i].charging
        currentPower = sum([ev.currentPower for ev in charging])
        reqPower = sum([ev.chargingPower for ev in charging]) + sum([ev.chargingPower for ev in incoming])

        if reqPower>currentPower
            scatter!(p,[pos[1]], [pos[2]], marker=:circle, markeralpha = 0.2, markersize=reqPower, color=:red, xlims=(-1,1), ylims=(-1,1))
        end
        scatter!(p,[pos[1]], [pos[2]], marker=:circle, markeralpha = 0.4, markersize=currentPower, xlims=(-1,1), ylims=(-1,1), legend=:none, color=:blue)

        scatter!(p,[ev.currentPosition[1] for ev in incoming], [ev.currentPosition[2] for ev in incoming], marker=:square, markersize=2, color=:green)
        
        
        for ev in incoming
            plot!(p,[ev.currentPosition[1], pos[1]], [ev.currentPosition[2], pos[2]], color=:gray, alpha=0.5)
        end
    end
    return p
end

function shortest_distance(sta::Vector{ChargingStation},ev::EVinstance)

    ev_pos = ev.currentPosition
    sta_pos = [station.position for station in sta]

    distances = zeros(length(sta_pos))

    for i in eachindex(sta_pos)
        distances[i] = sqrt(sum((ev_pos-sta_pos[i]).^2))
    end

    _,idx = findmin(distances)

    return idx

end

#Parameters
area = 4.0
lambda = 20.0;
mu=1.0;

C=Inf;
P=10.0
Tfinal=20.0;

work_distribution = Exponential(1/mu)
position_distribution = Product([Uniform(-1.0,1.0),Uniform(-1.0,1.0)])
#Agents
arr = PoissonArrivalProcess(lambda*area, work_distribution, 1.0; positionDistribution = position_distribution, velocity=1.0)

Ns = 10
sta = ChargingStation[]

for i=1:Ns
    pos = rand(position_distribution)
    push!(sta,ChargingStation(C, P, fifo_policy, snapshots=collect(0:.05:Tfinal), position=pos))
end

rtr = Router(shortest_distance)

connect!(arr,rtr)
connect!(rtr,sta...)
sim = Simulation([arr,rtr,sta...])

#Simulate
simulate(sim, Tfinal)

anim = @animate for i=1:length(sta[1].snapshots)
    p=plot_positions(sta,i)
end

gif(anim, fps = 8)
