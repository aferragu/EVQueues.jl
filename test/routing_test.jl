using EVQueues

function get_largest_deadline_inservice(sta::ChargingStation)
    active = filter(ev -> ev.currentPower>0, sta.charging)
    if length(active)>0
        return maximum([ev.currentDeadline for ev in active])
    else
        return Inf
    end
end

function routing_by_deadline(stations::Vector{ChargingStation})

    deadlines = get_largest_deadline_inservice.(stations)
    _,idx = findmax(deadlines)
    return idx
end


arr = TraceArrivalProcess([1.0,2.0], [4.0,3.0], [10.0,12.0], [1.0,1.0])
rtr = Router(routing_by_deadline)
connect!(arr,rtr)

sta1 = ChargingStation(Inf,1.0, edf_policy)
sta2 = ChargingStation(Inf,1.0, edf_policy)
connect!(rtr,sta1,sta2)

sim = Simulation([arr,rtr,sta1,sta2], Dict())

simulate(sim)


