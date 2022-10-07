using EVQueues, Distributions

function routing_by_free_spaces(phases::Vector{ChargingStation})

    free_spaces = map(phase->phase.chargingSpots-phase.occupation, phases)
    _,idx = findmin(free_spaces)
    return idx
    
end

function random_routing(phases::Vector{ChargingStation})

    d=DiscreteUniform(1,length(phases))
    return rand(d)
end

lambda=30.0
C = [15;15;15] #tot 45 chargers

mu=1.0
gamma=1000000
Tfinal=500.0


params = Dict(
    "ArrivalRate" => lambda,
    "AvgEnergy" => 1.0/mu,
    "AvgDeadline" => 1.0/mu + 1.0/gamma,
    "SimTime" => Tfinal,
    "Capacity" => C,
)

#variables aleatorias de los clientes
work_rng=Exponential(1.0/mu);
laxity_rng=Exponential(1.0/gamma);

arr = PoissonArrivalProcess(lambda,work_rng,laxity_rng,1.0)

rtr = Router(random_routing)

connect!(arr,rtr)

phase1 = ChargingStation(C[1],C[1])
phase2 = ChargingStation(C[2],C[3])
phase3 = ChargingStation(C[2],C[3])
phases = [phase1,phase2,phase3]

connect!(rtr,phases...)

sim = Simulation([arr,rtr,phase1,phase2,phase3], params)

simulate(sim, Tfinal)

t=phase1.trace[!,:time]
x1=phase1.trace[!,:occupation]
x2=phase2.trace[!,:occupation]
x3=phase3.trace[!,:occupation]

p=plot(t,x1)
plot!(p,t,x2)
plot!(p,t,x3)
display(p)

p2=plot(x1,x2,x3)
display(p2)