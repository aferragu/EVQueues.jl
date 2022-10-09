mutable struct Simulation

    agents::Array{Agent}
    parameters::Dict

    Simulation(agents::Array{Agent})  = new(agents,Dict())

end

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


