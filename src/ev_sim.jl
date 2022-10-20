"""
function ev_sim(lambda::Float64,mu::Float64,gamma::Float64,Tfinal::Float64,P::Float64,policy::Function,snapshots=Float64[]::Vector{Float64})

Helper function to create a simulation with a single Poisson Arrival process of intensity lambda, exponential energy demands of parameter mu and initial laxity also exponential of parameter gamma. The arrival process is fed to an infinite parking lot with maximum power P. Simulates the system up to Tfinal using the given scheduling policy and optionally takes snapshots if the times are given.
"""
function ev_sim(lambda::Float64,mu::Float64,gamma::Float64,Tfinal::Float64,P::Float64,policy::Function,snapshots=Float64[]::Vector{Float64})

    #guardo parametros
    params = Dict(
        "ArrivalRate" => lambda,
        "AvgEnergy" => 1.0/mu,
        "AvgDeadline" => 1.0/mu + 1.0/gamma,
        "SimTime" => Tfinal,
        "Capacity" => P,
        "Policy" => get_policy_name(policy),
        "Snapshots" => length(snapshots)
    )

    
    #variables aleatorias de los clientes
    work_rng=Exponential(1.0/mu);
    laxity_rng=Exponential(1.0/gamma);

    #Proceso de arribos
    arr = PoissonArrivalProcess(lambda,work_rng,1.0; initialLaxity = laxity_rng)
    sta = ChargingStation(Inf,P,policy; snapshots=snapshots)
    connect!(arr,sta)
    sim = Simulation([arr,sta], params=params)

    simulate(sim, Tfinal)
    return sim
    
end
