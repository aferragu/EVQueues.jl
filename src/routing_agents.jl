"""
Router Agent

When connected to an Arrival Process as its sink, receives the flow of EVinstances and routes them according to the routing policy defined in its constructor. Must be connected to one or several ChargingStations before use.

Constructors:

- Router(routingPolicy::Function)

See examples/example_two_parkings.jl for a complete use case.

"""
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

#Generic function to connect an ArrivalProcess to its next stage (router, charger, etc.)
function connect!(rtr::Router,agents...)
    push!(rtr.sinks,agents...)
    push!(rtr.routedArrivals, zeros(Int64, length(agents))...)
    push!(rtr.routedEnergy, zeros(length(agents))...)
end

#Internal function to record the state in the trace DataFrame
function trace_state!(rtr::Router,t::Float64)
    push!(rtr.trace, [t,rtr.totalArrivals, rtr.totalEnergy, rtr.routedArrivals, rtr.routedEnergy])
end

#handles the event at time t
function handle_event(rtr::Router, t::Float64, params...)

    eventType = params[1]

    if eventType === :Arrival

        #new arrival comes. Expects EV as second parameters
        newEV = params[2]::EVinstance

        #update tracing
        rtr.totalArrivals = rtr.totalArrivals + 1
        rtr.totalEnergy = rtr.totalEnergy + newEV.requestedEnergy

        #apply routing policy. Returns idx of agent to route to.
        idx = rtr.routingPolicy(convert.(ChargingStation,rtr.sinks),newEV)

        #update tracing
        rtr.routedArrivals[idx] = rtr.routedArrivals[idx] + 1
        rtr.routedEnergy[idx] = rtr.routedEnergy[idx] + newEV.requestedEnergy

        #pass event to selected sink
        handle_event(rtr.sinks[idx], t, :Arrival, newEV)
    
    end

end
