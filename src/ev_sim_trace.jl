"""
function ev_sim_trace(arrivalTimes::Vector{Float64}, 
    requestedEnergies::Vector{Float64},
    departureTimes::Vector{Float64}, 
    chargingPowers::Vector{Float64},
    policy::Function,
    P::Float64, 
    snapshots=[Inf])

Helper function to create a simulation with a single Trace Arrival process with the given parameters and a single ChargingStation with infinite space, given policy and maximum power P. Simulates the system up to the end of the trace and optionally takes snapshots if the times are given.
"""
function ev_sim_trace(arrivalTimes::Vector{Float64}, 
                      requestedEnergies::Vector{Float64},
                      departureTimes::Vector{Float64}, 
                      chargingPowers::Vector{Float64},
                      policy::Function,
                      P::Float64, 
                      snapshots=[Inf])

    #guardo parametros
    params = Dict(
        "TotalArrivals" => length(arrivalTimes),
        "AvgEnergy" => mean(requestedEnergies),
        "AvgDeadline" => mean(departureTimes-arrivalTimes),
        "SimTime" => departureTimes[end],
        "Capacity" => P,
        "Policy" => get_policy_name(policy),
        "AvgReportedDeadline" => NaN,
        "Snapshots" => length(snapshots)
    )

    arr = TraceArrivalProcess(arrivalTimes,requestedEnergies,departureTimes,chargingPowers)
    sta = ChargingStation(Inf,P,policy; snapshots=snapshots)
    connect!(arr,sta)
    sim = Simulation([arr,sta],params=params)

    simulate(sim, Tfinal)
    return sim

end


"""
function ev_sim_trace(df::DataFrame, policy::Function, P::Float64, snapshots=[Inf])

Helper function to create a simulation with a single Trace Arrival process defined by the DataFrame df (see TraceArrivalProcess) and a single ChargingStation with infinite space, given policy and maximum power P. Simulates the system up to the end of the trace and optionally takes snapshots if the times are given.
"""
function ev_sim_trace(  df::DataFrame,
                        policy::Function,
                        P::Float64,
                        snapshots=[Inf])

    ev_sim_trace(   df[!,:arrivalTimes],
                    df[!,:requestedEnergies],
                    df[!,:departureTimes],
                    df[!,:chargingPowers],
                    policy,
                    P,
                    snapshots)
    
end
