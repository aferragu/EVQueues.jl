module EVQueues

using ProgressMeter, Distributions, Serialization, JuMP, GLPK, DataFrames, DataStructures

export  compute_statistics!, get_vehicle_trajectories, compute_fairness, generate_Poisson_stream, ev_sim_trace,
        EVSim, loadsim, savesim


include("types.jl") ##General type definitions
include("arrival_processes.jl")
include("charging_stations.jl")
include("routing_agents.jl")

include("utilities.jl") ##codigo con utilidades varias
include("policies.jl")  ##codigo que implementa las politicas

include("ev_sim.jl")  ##codigo del simulador comun
include("ev_sim_trace.jl") ##codigo del simulador a partir de trazas
include("ev_sim_uncertain.jl") ##codigo del simulador con incertidumbre en el deadline

include("ev_sim_two_parkings.jl")
include("ev_sim_three_phase.jl")

include("plot_recipes.jl") ##plots


end #end module
