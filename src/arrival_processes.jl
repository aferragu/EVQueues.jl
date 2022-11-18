#Abstract Arrival Process type
abstract type ArrivalProcess <: Agent end

#Generic function to connect an ArrivalProcess to its next stage (router, charger, etc.)
function connect!(arr::ArrivalProcess, a::Agent)
    arr.sink = a
end

#Internal function to record the state in the trace DataFrame
function trace_state!(arr::ArrivalProcess, t::Float64)
    push!(arr.trace, [t,arr.totalArrivals, arr.totalEnergy])
end

"""
PoissonArrivalProcess Agent

Generates a Poisson Arrival process of EVinstances with given intensity, requested energy (a Distribution) and charging power (either a Float64 for uniform charging powers or a Distribution)

Additional parameters are the initial laxity (Distribution), the total sojourn time (Distribution) and deadline uncertainty (Distribution). Sojourn time takes precedence over laxity if both are defined.

If arrivals are spatial, a position distribution to sample initial positions of vehicles and their velocities can be specified.

Constructor:

PoissonArrivalProcess(  intensity::Float64, 
                        requestedEnergy::Distribution, 
                        chargingPower::Union{Distribution,Float64};
                        initialLaxity::Union{Distribution,Nothing} = nothing,
                        sojournTime::Union{Distribution,Nothing} = nothing, 
                        uncertainty::Union{Distribution,Nothing} = nothing
                        positionDistribution::Union{Distribution,Nothing} = nothing,
                        velocity::Float64 = NaN)
"""
mutable struct PoissonArrivalProcess <: ArrivalProcess

    #attributes
    intensity::Float64
    requestedEnergy::Distribution
    chargingPower::Union{Distribution,Float64}

    initialLaxity::Union{Distribution,Nothing}
    sojournTime::Union{Distribution,Nothing}
    uncertainty::Union{Distribution,Nothing}
    positionDistribution::Union{Distribution,Nothing}
    velocity::Float64

    #sink
    sink::Union{Agent, Nothing}

    #state
    timeToNextEvent::Float64
    nextEventType::Symbol

    #tracing
    trace::DataFrame
    totalArrivals::Float64
    totalEnergy::Float64

    function PoissonArrivalProcess( intensity::Float64, 
                                    requestedEnergy::Distribution, 
                                    chargingPower::Union{Distribution,Float64};
                                    initialLaxity::Union{Distribution,Nothing} = nothing, 
                                    sojournTime::Union{Distribution,Nothing} = nothing, 
                                    uncertainty::Union{Distribution,Nothing} = nothing,
                                    positionDistribution::Union{Distribution,Nothing} = nothing,
                                    velocity::Float64 = NaN)

        firstArrival = rand(Exponential(1/intensity))
        trace = DataFrame(time=[0.0], totalArrivals=[0.0], totalEnergy=[0.0])
        new(intensity, requestedEnergy, chargingPower, initialLaxity, sojournTime, uncertainty, positionDistribution, velocity, nothing, firstArrival,:Arrival, trace, 0.0,0.0);

    end

end

#handles the event at time t
function handle_event(arr::PoissonArrivalProcess, t::Float64, params...)

    @assert isapprox(arr.timeToNextEvent,0.0,atol=tol) "Called handle_event in ArrivalProcess but timeToNextEvent>0"
    arr.totalArrivals = arr.totalArrivals + 1

    energy = rand(arr.requestedEnergy)
    arr.totalEnergy = arr.totalEnergy + energy

    if (arr.chargingPower isa Float64)
        power = arr.chargingPower
    else
        power = rand(arr.chargingPower)
    end

    if arr.initialLaxity===nothing && arr.sojournTime===nothing
        departure = Inf
    elseif arr.initialLaxity===nothing
        sojournTime = rand(arr.sojournTime)
        departure = t + sojournTime
    else
        laxity = rand(arr.initialLaxity)
        departure = t + energy/power + laxity
    end
    
    if  arr.uncertainty !== nothing
        uncertainty_value = rand(arr.uncertainty)
        reportedDepartureTime = departure + uncertainty_value
    else
        reportedDepartureTime = departure
    end

    if arr.positionDistribution !== nothing
        initialPosition = rand(arr.positionDistribution)
    else
        initialPosition = [NaN,NaN]
    end
    newEV = EVinstance(t,departure,energy,power; reportedDepartureTime = reportedDepartureTime, initialPosition = initialPosition, velocity = arr.velocity)

    handle_event(arr.sink, t, :Arrival, newEV)
    arr.timeToNextEvent = rand(Exponential(1/arr.intensity))

end


"""
TraceArrivalProcess Agent

Generates an Arrival process of EVinstances with the given arrival times, requested energies, departure times, charging powers and, optionally, reported departure times. Optionally also vehicles may arriva at some position and velocities that may be used by Routers to decide the best station to attach to.

Constructors:

- TraceArrivalProcess(  arrivalTimes::Vector{Float64}, 
                        requestedEnergies::Vector{Float64},
                        departureTimes::Vector{Float64}, 
                        chargingPowers::Vector{Float64};
                        reportedDepartureTimes::Vector{Float64} = Float64[],
                        initialPosition::Array{Array{Float64}},
                        velocities::Array{Float64})

- TraceArrivalProcess(data::DataFrame) where the DataFrame data must have the same column names than the previous constructor.


"""
mutable struct TraceArrivalProcess <: ArrivalProcess

    #attributes
    arrivalTimes::Vector{Float64}
    requestedEnergies::Vector{Float64}
    departureTimes::Vector{Float64}
    chargingPowers::Vector{Float64}
    reportedDepartureTimes::Vector{Float64}
    initialPositions::Vector{Vector{Float64}}
    velocities::Vector{Float64}

    #sink
    sink::Union{Agent, Nothing}

    #state
    timeToNextEvent::Float64
    nextEventType::Symbol

    #tracing
    trace::DataFrame
    totalArrivals::Int64
    totalEnergy::Float64

    function TraceArrivalProcess(   arrivalTimes::Vector{Float64}, 
                                    requestedEnergies::Vector{Float64},
                                    departureTimes::Vector{Float64}, 
                                    chargingPowers::Vector{Float64};
                                    reportedDepartureTimes::Vector{Float64} = Float64[],
                                    initialPositions::Vector{Vector{Float64}} = Vector{Float64}[],
                                    velocities::Vector{Float64} = Float64[]
            )

        @assert issorted(arrivalTimes) "Arrival times must be sorted"
        trace = DataFrame(time=[0.0], totalArrivals=[0.0], totalEnergy=[0.0])

        if isempty(reportedDepartureTimes)
            reportedDepartureTimes = copy(departureTimes)
        end

        if isempty(initialPositions)
            initialPositions = [[NaN,NaN] for i=1:length(arrivalTimes)]
        end

        if isempty(velocities)
            velocities = [NaN for i=1:length(arrivalTimes)]
        end
        
        arr = new(arrivalTimes, requestedEnergies, departureTimes, chargingPowers, reportedDepartureTimes, initialPositions, velocities, nothing, arrivalTimes[1],:Arrival,trace,0.0,0.0)

        return arr
    end

    function TraceArrivalProcess(data::DataFrame)

        sort!(data,:arrivalTimes)
        if columnindex(data, :reportedDepartureTimes) == 0
            reportedDepartureTimes = Float64[]
        else
            reportedDepartureTimes = data[!,:reportedDepartureTimes]
        end

        if columnindex(data, :initialPositions) == 0
            initialPositions = Vector{Float64}[]
        else
            initialPositions = data[!,:initialPositions]
        end

        if columnindex(data, :velocities) == 0
            velocities = Float64[]
        else
            velocities = data[!,:velocities]
        end

        arr = TraceArrivalProcess(data[!,:arrivalTimes], data[!,:requestedEnergies], data[!,:departureTimes], data[!,:chargingPowers]; reportedDepartureTimes = reportedDepartureTimes, initialPositions = initialPositions, velocities = velocities)

        return arr

    end

end

#handles the event at time t
function handle_event(arr::TraceArrivalProcess, t::Float64, params...)
    
    @assert isapprox(arr.timeToNextEvent,0.0,atol=eps()) "At time $t Called handle_event in TraceArrivalProcess but nextArrival=$(arr.timeToNextEvent)>0"
    arr.totalArrivals = arr.totalArrivals + 1

    energy = arr.requestedEnergies[arr.totalArrivals]
    power = arr.chargingPowers[arr.totalArrivals]
    departure = arr.departureTimes[arr.totalArrivals]
    reportedDeparture = arr.reportedDepartureTimes[arr.totalArrivals]
    initialPosition = arr.initialPositions[arr.totalArrivals]
    velocity = arr.velocities[arr.totalArrivals]

    arr.totalEnergy = arr.totalEnergy + energy

    newEV = EVinstance(t,departure,energy,power; reportedDepartureTime = reportedDeparture, initialPosition = initialPosition, velocity = velocity)
    
    handle_event(arr.sink, t, :Arrival, newEV)
    
    if arr.totalArrivals < length(arr.arrivalTimes)
        arr.timeToNextEvent = arr.arrivalTimes[arr.totalArrivals+1] - t
    else
        arr.timeToNextEvent = Inf
        arr.nextEventType = :Nothing
    end
    
end
