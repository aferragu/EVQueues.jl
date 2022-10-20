module EVQueues

using ProgressMeter, Distributions, Serialization, DataFrames

export  PoissonArrivalProcess, TraceArrivalProcess,
        ChargingStation,
        Router,
        Simulation,
        connect!,
        simulate,
        EVinstance,
        Snapshot,
        ChargingStationStatistics,
        compute_statistics,
        get_vehicle_trajectories,
        compute_fairness,
        generate_Poisson_stream,
        sort_completed_vehicles,
        loadsim,
        savesim



const tol = sqrt(eps()) #tolerance for checking next event times reaching 0.

include("types.jl") ##General type definitions
include("arrival_processes.jl") #defines arrival processes
include("charging_stations.jl") #defines charging stations
include("routing_agents.jl") #defines routing agents
include("simulation.jl") #defines simulator

include("utilities.jl") #various helper functions
include("policies.jl")  #policy implementations

include("ev_sim.jl")  #helper function to simulate a simple case with Poisson arrivals
include("ev_sim_trace.jl") #helper function to simulate a simple case with trace given arrivals

include("plot_recipes.jl") #plot recipes


end #end module
