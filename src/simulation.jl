mutable struct Simulation

    agents::Array{EVQueues.Agent}

end

function simulate(sim::Simulation, Tfinal::Float64=Inf; snapshots::Vector{Float64} = Float64[])

    prog=Progress(101, dt=0.5, desc="Simulando... ");

    agents=sim.agents

    T=Float64[]
    t=0.0
    push!(T,t)

    isempty(snapshots) ? nextSnapshot = Inf : nextSnapshot = snapshots[1];

    nextEvents = get_next_event.(agents)
    dt,idx = findmin([u[1] for u in nextEvents])
    event = nextEvents[idx][2]
    handler = agents[idx]

    while t<Tfinal

        t=t+dt
        nextSnapshot = nextSnapshot - dt

        update_state!.(agents, dt)
        handle_event(handler,t,event)
        trace_state!.(agents,t)

        nextEvents = get_next_event.(agents)
        dt,idx = findmin([u[1] for u in nextEvents])
        event = nextEvents[idx][2]
        handler = agents[idx]
    
        if isapprox(nextSnapshot,0,atol=1e-8)
            ##add snapshot


            
            snapshots = snapshots[2:end]
            isempty(snapshots) ? nextSnapshot = Inf : nextSnapshot = snapshots[1];
        
        end

        progress = ceil(Integer,t/Tfinal*100);
        ProgressMeter.update!(prog,progress);
    end

end


