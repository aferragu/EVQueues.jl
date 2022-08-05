mutable struct Router <: Agent

    #attributes
    routingPolicy::Function

    #sinks
    sinks::Union{Vector{Agent},Nothing}

    #state
    timeToNextEvent::Float64 #for compatibility
    nextEventType::Symbol

    #tracing
    totalArrivals::Int64
    totalEnergy::Float64
    routedArrivals::Vector{Int64}
    routedEnergy::Vector{Float64}    

    function Router(routingPolicy)
        return new(routingPolicy, Agent[],Inf,:Nothing,0.0,0.0,Float64[],Float64[])
    end

end

function connect!(rtr::Router,agents...)
    for sta in agents
        push!(rtr.sinks,sta)
    end
    push!(rtr.routedArrivals, zeros(Int64, length(agents))...)
    push!(rtr.routedEnergy, zeros(length(agents))...)
end

function update_state!(rtr::Router, dt::Float64)
    #nothing to do, routers do not have state
end

function get_traces(rtr::Router)::Vector{Float64}
    return rtr.totalArrivals, rtr.totalEnergy, rtr.routedArrivals, rtr.routedEnergy
end

#handles the event at time t with type "event"
function handle_event(rtr::Router, t::Float64, params...)

    eventType = params[1]

    if eventType === :Arrival

        #new arrival comes. Expects EV as second parameters
        newEV = params[2]::EVinstance

        #update tracing
        rtr.totalArrivals = rtr.totalArrivals + 1
        rtr.totalEnergy = rtr.totalEnergy + newEV.requestedEnergy

        #apply routing policy. Returns idx of agent to route to.
        idx = rtr.routingPolicy(rtr.sinks)

        #update tracing
        rtr.routedArrivals[idx] = rtr.routedArrivals[idx] + 1
        rtr.routedEnergy[idx] = rtr.routedEnergy[idx] + newEV.requestedEnergy

        #pass event to selected sink
        handle_event(rtr.sinks[idx], t, :Arrival, newEV)
    
    end

end
