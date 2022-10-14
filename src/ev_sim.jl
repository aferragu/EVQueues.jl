function ev_sim(lambda,mu,gamma,Tfinal,C,policy,snapshots=[Inf])

    #guardo parametros
    params = Dict(
        "ArrivalRate" => lambda,
        "AvgEnergy" => 1.0/mu,
        "AvgDeadline" => 1.0/mu + 1.0/gamma,
        "SimTime" => Tfinal,
        "Capacity" => C,
        "Policy" => get_policy_name(policy),
        "Snapshots" => length(snapshots)
    )

    
    #variables aleatorias de los clientes
    work_rng=Exponential(1.0/mu);
    laxity_rng=Exponential(1.0/gamma);

    #Proceso de arribos
    arr = PoissonArrivalProcess(lambda,work_rng,1.0; initialLaxity = laxity_rng)
    sta = ChargingStation(Inf,C,policy; snapshots=snapshots)
    connect!(arr,sta)
    sim = Simulation([arr,sta], params)

    simulate(sim, Tfinal)
    return sim
    
end
