import Random

function simple_test_policy(policy::Function)
    #Arrival times, must be ordered
    arrivals = [1.0;2.0;3.0];
    #Departure times, correlative to arrivals.
    departures = [12.0;13.0;14.0];
    #Requested energies
    energies = [4.0;5.0;6.0];
    #Charging powers
    powers = [1.0;1.0;1.0];


    arr = TraceArrivalProcess(arrivals, energies, departures, powers)

    #Max power
    P=1.0;
    sta = ChargingStation(Inf, P, policy)

    connect!(arr,sta)

    sim = Simulation([arr,sta])

    #Simulate
    simulate(sim)

    return [ev.completionTime for ev in sort_completed_vehicles(sta.completedEVs)]

end


@testset "Policies Test" begin

    #Priority based
    @test simple_test_policy(EVQueues.edf_policy) == [5.0,10.0,14.0]
    @test simple_test_policy(EVQueues.llf_policy) == [12.0,13.0,9.0]
    @test simple_test_policy(EVQueues.llr_policy) == [12.0,13.0,9.0]
    @test simple_test_policy(EVQueues.fifo_policy) == [5.0,10.0,14.0]
    @test simple_test_policy(EVQueues.lifo_policy) == [12.0,13.0,9.0]
    @test simple_test_policy(EVQueues.lar_policy) == [5.0,10.0,14.0]
    @test simple_test_policy(EVQueues.las_policy) == [12.0,13.0,9.0]
    @test simple_test_policy(EVQueues.ratio_policy) == [12.0,13.0,9.0]
    @test simple_test_policy(EVQueues.lrpt_policy) == [12.0,13.0,9.0]
    @test simple_test_policy(EVQueues.mw_policy) == [12.0,13.0,9.0]

    #Non-priority based
    @test simple_test_policy(EVQueues.parallel_policy) == [10.5,13.0,14.0]
    @test simple_test_policy(EVQueues.pf_policy) == [12.0,13.0,14.0]
    @test simple_test_policy(EVQueues.exact_policy) == [12.0,13.0,14.0]

end;

function simple_test_routing(policy::Function)
    #Arrival times, must be ordered
    arrivals = [1.0;2.0;3.0];
    #Departure times, correlative to arrivals.
    departures = [12.0;13.0;14.0];
    #Requested energies
    energies = [4.0;5.0;6.0];
    #Charging powers
    powers = [1.0;1.0;1.0];

    arr = TraceArrivalProcess(arrivals, energies, departures, powers)
    rtr = Router(policy)

    connect!(arr,rtr)
    
    P=1.0
    C=1.0
    sta1 = ChargingStation(C, P, fifo_policy)
    sta2 = ChargingStation(C, P, fifo_policy)

    connect!(rtr,sta1,sta2)

    sim = Simulation([arr,rtr,sta1,sta2])

    Random.seed!(111)
    #Simulate
    simulate(sim)

    return [sta1.arrivals, sta2.arrivals]
end

@testset "Routing policies Test" begin
    
    @test simple_test_routing(EVQueues.least_loaded_phase_routing) == [2,1]
    @test simple_test_routing(EVQueues.random_routing) == [3,0]
    @test simple_test_routing(EVQueues.free_spaces_routing) == [2,1]
    
end;

