abstract type ArrivalProcess <: Agent end

#Connects an Arrival Process with its next step
function connect!(arr::ArrivalProcess, a::Agent)
    arr.sink = a
end


### Poisson Arrival Process
#   Random arrivals as a Poisson process with general deadline and work distributions.

mutable struct PoissonArrivalProcess <: ArrivalProcess

    #attributes
    intensity::Float64
    requestedEnergy::Distribution
    initialLaxity::Distribution
    chargingPower::Union{Distribution,Float64}

    #sink
    sink::Union{Agent, Nothing}

    #state
    nextArrival::Float64

    #tracing
    totalArrivals::Float64
    totalEnergy::Float64

    function PoissonArrivalProcess(intensity::Float64,requestedEnergy::Distribution, initialLaxity::Distribution, chargingPower::Union{Distribution,Float64})

        nextArrival = rand(Exponential(1/intensity))
        new(intensity, requestedEnergy, initialLaxity, chargingPower, nothing, nextArrival,0.0,0.0)

    end

end

#update state after dt time units
function update_state!(arr::PoissonArrivalProcess, dt::Float64)
    arr.nextArrival = arr.nextArrival-dt
end

function get_traces!(arr::PoissonArrivalProcess)::Vector{Float64}
    return [arr.totalArrivals, arr.totalEnergy]
end

#returns the time of next event and names
function get_next_event(arr::PoissonArrivalProcess)::Tuple{Float64,Symbol}
    return arr.nextArrival,:Arrival
end

#handles the event at time t with type "event"
function handle_event(arr::PoissonArrivalProcess, t::Float64, params...)

    @assert nextArrival = 0 "Called handle_event in ArrivalProcess but nextArrival>0"
    arr.totalArrivals = arr.totalArrivals + 1

    energy = rand(arr.requestedEnergy)
    arr.totalEnergy = arr.totalEnergy + arr.energy

    if (arr.chargingPower isa Float64)
        power = arr.chargingPower
    else
        power = rand(arr.chargingPower)
    end
    laxity = rand(arr.initialLaxity)
    departure = t +energy/power + laxity

    newEV = EVinstance(t,departure,energy,power)
    handle_event(arr.sink, t, :Arrival, newEV)

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
    nextArrival::Float64

    #tracing
    totalArrivals::Float64
    totalEnergy::Float64

    function TraceArrivalProcess(arrivalTimes::Vector{Float64}, requestedEnergies::Vector{Float64} ,departureTimes::Vector{Float64}, chargingPowers::Vector{Float64})

        nextArrival = rand(Exponential(1/intensity))
        @assert issorted(arrivalTimes) "Arrival times must be sorted"
        new(arrivalTimes, requestedEnergies, departureTimes, chargingPowers, nothing, nextArrival,0.0,0.0)

    end

    function TraceArrivalProcess(data::DataFrame)

        sort!(data,:arrivalTimes)
        nextArrival = data[:arrivalTimes][1]
        new(data[:arrivalTimes], data[:requestedEnergies], data[:departureTimes], data[:chargingPowers], nothing, nextArrival,0.0,0.0)

    end

end

#update state after dt time units
function update_state!(arr::PoissonArrivalProcess, dt::Float64)
    arr.nextArrival = arr.nextArrival-dt
end

function get_traces!(arr::PoissonArrivalProcess)::Vector{Float64}
    return [arr.totalArrivals, arr.totalEnergy]
end

#returns the time of next event and names
function get_next_event(arr::PoissonArrivalProcess)::Tuple{Float64,Symbol}
    return arr.nextArrival,:Arrival
end

#handles the event at time t with type "event"
function handle_event(arr::PoissonArrivalProcess, t::Float64, params...)
    
    @assert nextArrival = 0 "Called handle_event in ArrivalProcess but nextArrival>0"
    arr.totalArrivals = arr.totalArrivals + 1

    energy = arr.data[:requestedEnergies][arr.totalArrivals]
    power = arr.data[:chargingPower][arr.totalArrivals]
    departure = arr.data[:departureTimes][arr.totalArrivals]

    arr.totalEnergy = arr.totalEnergy + energy

    newEV = EVinstance(t,departure,energy,power)
    handle_event(arr.sink, t, :Arrival, newEV)

end

