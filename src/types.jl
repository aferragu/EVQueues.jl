abstract type Agent  end

#Internal function that returns the time of next event of an agent and its type.
function get_next_event(agent::Agent)::Tuple{Float64,Symbol}
    return agent.timeToNextEvent, agent.nextEventType
end

#update state after dt time units (redefine if necessary for more complex Agents)
function update_state!(agent::Agent, dt::Float64)
    agent.timeToNextEvent = agent.timeToNextEvent-dt
end

function take_snapshot!(agent::Agent,t::Float64)
    #do nothing unless redefined
end

"""
EVinstance object.

An EV with a given arrival time, departure time, requested energy and charging power.
Optionally a reported departure time, initial position and velocity can be specified.

Upon simulation, more internal parameters are filled. These are:

* currentWorkload::Float64 - remaining energy to fulfill the vehicle.
* currentDeadline::Float64 - remaining time until deadline expiration.
* currentReportedDeadline::Float64 - remaining time until reported deadline expiration.
* currentPower::Float64 - current charging power.
* departureWorkload::Float64 - remaining energy to fulfill at the moment of departure.
* completionTime::Float64 - when fully serviced, completion time of service.
* currentPosition::Vector{Float64} - current position.

Constructor:

- EVinstance(   arrivalTime::Float64,
                departureTime::Float64,
                requestedEnergy::Float64,
                chargingPower::Float64;
                reportedDepartureTime=reportedDeparture::Float64 = NaN,
                initialPosition::Vector{Float64} = [NaN,NaN],
                velocity::Float64 = NaN)
"""
mutable struct EVinstance
    arrivalTime::Float64
    departureTime::Float64
    reportedDepartureTime::Float64
    requestedEnergy::Float64
    chargingPower::Float64
    initialPosition::Vector{Float64}
    velocity::Float64
    currentWorkload::Float64
    currentDeadline::Float64
    currentReportedDeadline::Float64
    currentPower::Float64
    departureWorkload::Float64
    completionTime::Float64
    currentPosition::Vector{Float64}

    EVinstance( arrivalTime::Float64,
                departureTime::Float64,
                requestedEnergy::Float64,
                chargingPower::Float64;
                reportedDepartureTime=reportedDeparture::Float64 = NaN,
                initialPosition::Vector{Float64} = [NaN,NaN],
                velocity::Float64 = NaN) = new( arrivalTime,
                                                departureTime,
                                                reportedDepartureTime,
                                                requestedEnergy,
                                                chargingPower,
                                                initialPosition,
                                                velocity,
                                                requestedEnergy,
                                                departureTime-arrivalTime,
                                                reportedDepartureTime-arrivalTime,
                                                0.0,
                                                NaN,
                                                NaN,
                                                initialPosition)
end

"""
Snapshot object

Stores the time and the currently charging vehicles and currently already charged vehicles present in a ChargingStation
"""
mutable struct Snapshot
    t::Float64                          #snapshot time
    charging::Array{EVinstance}         #vehicles in the system in charge
    alreadyCharged::Array{EVinstance}   #already charged vehicles still present
    incoming::Array{EVinstance}         #incoming vehicles: assigned but not yet arrived
end

"""
ChargingStationStatistics object

Stores occupation statistics of a ChargingStation. See compute_statistics on how to get them.

Fields stored:

* rangeCharging,pCharging: distribution of the number of actively charging vehicles.
* rangeAlreadyCharged,pAlreadyCharged: distribution of the number of already charged vehicles.
* avgCharging: mean value of actively charging vehicles
* avgAlreadyCharged: mean value of already charged vehicles
* pD: empirical probability of deadline expiration before full charge.
* avgW: average unfulfilled energy upon vehicle departure.
* pB: blocking probability (for finite space charging stations).

"""
mutable struct ChargingStationStatistics
    rangeCharging::Vector{Int64}
    pCharging::Vector{Float64}
    rangeAlreadyCharged::Vector{Int64}
    pAlreadyCharged::Vector{Float64}
    avgCharging::Float64
    avgAlreadyCharged::Float64
    pD::Float64
    avgW::Float64
    pB::Float64
end
