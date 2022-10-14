abstract type ArrivalProcess <: Agent end

#Connects an Arrival Process with its next step
function connect!(arr::ArrivalProcess, a::Agent)
    arr.sink = a
end

function trace_state!(arr::ArrivalProcess, t::Float64)
    push!(arr.trace, [t,arr.totalArrivals, arr.totalEnergy])
end

### Poisson Arrival Process
#   Random arrivals as a Poisson process with general deadline and work distributions.
mutable struct PoissonArrivalProcess <: ArrivalProcess

    #attributes
    intensity::Float64
    requestedEnergy::Distribution
    chargingPower::Union{Distribution,Float64}

    initialLaxity::Union{Distribution,Nothing}
    sojournTime::Union{Distribution,Nothing}
    uncertainty::Union{Distribution,Nothing}

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
                                    uncertainty::Union{Distribution,Nothing} = nothing)

        firstArrival = rand(Exponential(1/intensity))
        trace = DataFrame(time=[0.0], totalArrivals=[0.0], totalEnergy=[0.0])
        new(intensity, requestedEnergy, chargingPower, initialLaxity, sojournTime, uncertainty, nothing, firstArrival,:Arrival, trace, 0.0,0.0);

    end

end

#handles the event at time t with type "event"
function handle_event(arr::PoissonArrivalProcess, t::Float64, params...)

    @assert isapprox(arr.timeToNextEvent,0.0,atol=eps()) "Called handle_event in ArrivalProcess but timeToNextEvent>0"
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
        newEV = EVinstance(t,departure,energy,power; reportedDepartureTime = departure+uncertainty_value)
    else
        newEV = EVinstance(t,departure,energy,power)
    end

    handle_event(arr.sink, t, :Arrival, newEV)
    arr.timeToNextEvent = rand(Exponential(1/arr.intensity))

end


### Trace Arrival process
#   Given a trace (vectors or DataFrame) of arrival times, energies, deadlines and charging powers,
#   constructs the corresponding arrival process.
mutable struct TraceArrivalProcess <: ArrivalProcess

    #attributes
    arrivalTimes::Vector{Float64}
    requestedEnergies::Vector{Float64}
    departureTimes::Vector{Float64}
    chargingPowers::Vector{Float64}

    #sink
    sink::Union{Agent, Nothing}

    #state
    timeToNextEvent::Float64
    nextEventType::Symbol

    #tracing
    trace::DataFrame
    totalArrivals::Int64
    totalEnergy::Float64

    function TraceArrivalProcess(arrivalTimes::Vector{Float64}, requestedEnergies::Vector{Float64} ,departureTimes::Vector{Float64}, chargingPowers::Vector{Float64})

        @assert issorted(arrivalTimes) "Arrival times must be sorted"
        trace = DataFrame(time=[0.0], totalArrivals=[0.0], totalEnergy=[0.0])
        new(arrivalTimes, requestedEnergies, departureTimes, chargingPowers, nothing, arrivalTimes[1],:Arrival,trace,0.0,0.0)

    end

    function TraceArrivalProcess(data::DataFrame)

        sort!(data,:arrivalTimes)
        TraceArrivalProcess(data[!,:arrivalTimes], data[!,:requestedEnergies], data[!,:departureTimes], data[!,:chargingPowers])

    end

end

#handles the event at time t with type "event"
function handle_event(arr::TraceArrivalProcess, t::Float64, params...)
    
    @assert isapprox(arr.timeToNextEvent,0.0,atol=eps()) "At time $t Called handle_event in TraceArrivalProcess but nextArrival=$(arr.timeToNextEvent)>0"
    arr.totalArrivals = arr.totalArrivals + 1

    energy = arr.requestedEnergies[arr.totalArrivals]
    power = arr.chargingPowers[arr.totalArrivals]
    departure = arr.departureTimes[arr.totalArrivals]

    arr.totalEnergy = arr.totalEnergy + energy

    newEV = EVinstance(t,departure,energy,power)
    handle_event(arr.sink, t, :Arrival, newEV)
    
    if arr.totalArrivals < length(arr.arrivalTimes)
        arr.timeToNextEvent = arr.arrivalTimes[arr.totalArrivals+1] - t
    else
        arr.timeToNextEvent = Inf
        arr.nextEventType = :Nothing
    end
    
end
