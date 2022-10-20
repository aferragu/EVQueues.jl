"""
Simulation controller

Receives an Array of Agents and sets up the simulation. Call simulate(sim::Simulation, Tfinal::Float64=Inf) to start running the simulation itself.
Optionally, store the simulation parameters in a user defined Dict for easy record purposes.

Constructor:

- Simulation(agents::Array{Agent}; params=Dict()::Dict) = new(agents,params)
"""
mutable struct Simulation

    agents::Array{Agent}
    parameters::Dict

    Simulation(agents::Array{Agent}; params=Dict()::Dict) = new(agents,params)

end

"""
function simulate(sim::Simulation, Tfinal::Float64=Inf)

Runs the simulation defined in object sim calling each agent and following the stream of events. The simulation is stopped whenever there are now more events or Tfinal is reached.
The agents on the object sim are updated accordingly and all their traces are filled.
"""
function simulate(sim::Simulation, Tfinal::Float64=Inf)

    prog=Progress(101, dt=0.5, desc="Simulating... ");

    agents=sim.agents
    t=0.0

    ##agent events
    nextEvents = get_next_event.(agents)
    dt,idx = findmin([u[1] for u in nextEvents])
    eventType = nextEvents[idx][2]
    handlerAgent = agents[idx]
    
    while t<Tfinal && eventType != :Nothing

        t=t+dt
    
        update_state!.(agents, dt)
        handle_event(handlerAgent,t,eventType)
        trace_state!.(agents,t)

        ##agent events
        nextEvents = get_next_event.(agents)
        dt,idx = findmin([u[1] for u in nextEvents])
        eventType = nextEvents[idx][2]
        handlerAgent = agents[idx]
        
        progress = ceil(Integer,t/Tfinal*100);
        ProgressMeter.update!(prog,progress);

    end

end


