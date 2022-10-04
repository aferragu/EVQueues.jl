mutable struct Simulation

    agents::Array{EVQueues.Agent}
    parameters::Dict

end

function simulate(sim::Simulation, Tfinal::Float64=Inf; snapshots::Vector{Float64} = Float64[])

    prog=Progress(101, dt=0.5, desc="Simulating... ");

    agents=sim.agents

    T=Float64[]
    t=0.0
    push!(T,t)

    isempty(snapshots) ? nextSnapshot = Inf : nextSnapshot = snapshots[1];

    nextEvents = get_next_event.(agents)
    dt,idx = findmin([u[1] for u in nextEvents])
    event = nextEvents[idx][2]
    handler = agents[idx]
    takeSnap=false

    while t<Tfinal

        t=t+dt
        nextSnapshot = nextSnapshot - dt

        if isapprox(nextSnapshot,0,atol=1e-8) ##Must take snapshot
            takeSnap=true
        end

        update_state!.(agents, dt)
        if takeSnap==false
            handle_event(handler,t,event)
        end
        trace_state!.(agents,t)

        nextEvents = get_next_event.(agents)
        dtEvents,idx = findmin([u[1] for u in nextEvents])
        event = nextEvents[idx][2]
        handler = agents[idx]
    
        if takeSnap==true
            ##add snapshot
            take_snapshot!.(agents,t)
            snapshots = snapshots[2:end]
            isempty(snapshots) ? nextSnapshot = Inf : nextSnapshot = snapshots[1];
            takeSnap=false
        end

        dt = min(dtEvents,nextSnapshot)

        progress = ceil(Integer,t/Tfinal*100);
        ProgressMeter.update!(prog,progress);
    end

end


