using EVQueues, Distributions, Plots

lambda=30.0
C = [15;15;15] #tot 45 chargers

mu=1.0
Tfinal=500.0


params = Dict(
    "ArrivalRate" => lambda,
    "AvgEnergy" => 1.0/mu,
    "AvgDeadline" => 1.0/mu,
    "SimTime" => Tfinal,
    "Capacity" => C,
)

#variables aleatorias de los clientes
work_rng=Exponential(1.0/mu);
laxity_rng=Dirac(0.0);

arr = PoissonArrivalProcess(lambda,work_rng,1.0; initialLaxity = laxity_rng)

rtr = Router(free_spaces_routing)

connect!(arr,rtr)

phase1 = ChargingStation(C[1],C[1])
phase2 = ChargingStation(C[2],C[3])
phase3 = ChargingStation(C[2],C[3])
phases = [phase1,phase2,phase3]

connect!(rtr,phases...)

sim = Simulation([arr,rtr,phase1,phase2,phase3], params=params)

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