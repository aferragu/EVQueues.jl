using EVQueues, Distributions, Plots

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


##Simulation with two ev_sim_two_parkings

lambda = 50.0
mu = 1.0
gamma = 1.0

Tfinal = 500.0
Pmax = [20.0,20.0]
policy = edf_policy
routing_policy = routing_by_deadline

#guardo parametros
params = Dict(
    "ArrivalRate" => lambda,
    "AvgEnergy" => 1.0/mu,
    "AvgDeadline" => 1.0/mu + 1.0/gamma,
    "SimTime" => Tfinal,
    "Capacities" => Pmax,
    "Policy" => "EDF",
)

#variables aleatorias de los clientes
work_rng=Exponential(1.0/mu);
laxity_rng=Exponential(1.0/gamma);

arr = PoissonArrivalProcess(lambda,work_rng,1.0; initialLaxity = laxity_rng)
rtr = Router(routing_policy)

connect!(arr,rtr)

sta1 = ChargingStation(Inf,Pmax[1],policy)
sta2 = ChargingStation(Inf,Pmax[2],policy)

connect!(rtr,sta1,sta2)

sim = Simulation([arr,rtr,sta1,sta2], params)

simulate(sim, Tfinal)

p=plot(sta1)
display(p)
p2=plot(sta2)
display(p2)