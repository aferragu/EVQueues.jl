mutable struct Router <: Agent

    #attributes
    routingPolicy::Function

    #sinks
    sinks::Union{Vector{Agent},Nothing}

    #state
    timeToNextEvent::Float64 #for compatibility
    nextEventType::Symbol

    #tracing
    trace::DataFrame
    totalArrivals::Int64
    totalEnergy::Float64
    routedArrivals::Vector{Int64}
    routedEnergy::Vector{Float64}    

    function Router(routingPolicy::Function)
        trace = DataFrame(time=0.0,totalarrivals=0,totalEnergy=0.0,routedArrivals=Vector{Vector{Float64}}(undef,0), routedEnergy=Vector{Vector{Float64}}(undef,0))
        return new(routingPolicy, Agent[],Inf,:Nothing,trace,0,0.0,Int64[],Float64[])
    end

end

function connect!(rtr::Router,agents...)
    push!(rtr.sinks,agents...)
    push!(rtr.routedArrivals, zeros(Int64, length(agents))...)
    push!(rtr.routedEnergy, zeros(length(agents))...)
end

function update_state!(rtr::Router, dt::Float64)
    rtr.timeToNextEvent = rtr.timeToNextEvent-dt
end

function trace_state!(rtr::Router,t::Float64)
    push!(rtr.trace, [t,rtr.totalArrivals, rtr.totalEnergy, rtr.routedArrivals, rtr.routedEnergy])
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
        idx = rtr.routingPolicy(convert.(ChargingStation,rtr.sinks))

        #update tracing
        rtr.routedArrivals[idx] = rtr.routedArrivals[idx] + 1
        rtr.routedEnergy[idx] = rtr.routedEnergy[idx] + newEV.requestedEnergy

        #pass event to selected sink
        handle_event(rtr.sinks[idx], t, :Arrival, newEV)
    
    end

end
