#=
ev_sim_trace(arribos,demandas,salidas, potencias,C,policy)

Realiza la simulacion hasta terminar con los vehiculos de la lista.
arribos: lista de tiempos de arribo. Debe estar ordenada.
demandas: lista de demandas de carga (en energia)
salidas: lista de tiempos de salida.
potencias: lista de potencias de carga de los vehiculos
C: potencia maxima combinada
policy: una de las politicas definidas en EVSim
snapshots: tiempo de capturas
salidaReportada: vector opcional que altera los deadlines reportados.
=#
function ev_sim_trace(arrivalTimes::Vector{Float64}, 
                      requestedEnergies::Vector{Float64},
                      departureTimes::Vector{Float64}, 
                      chargingPowers::Vector{Float64},
                      policy::Function,
                      C::Number, 
                      snapshots=[Inf])

    #guardo parametros
    params = Dict(
        "TotalArrivals" => length(arrivalTimes),
        "AvgEnergy" => mean(requestedEnergies),
        "AvgDeadline" => mean(departureTimes-arrivalTimes),
        "SimTime" => departureTimes[end],
        "Capacity" => C,
        "Policy" => get_policy_name(policy),
        "AvgReportedDeadline" => NaN,
        "Snapshots" => length(snapshots)
    )

    arr = TraceArrivalProcess(arrivalTimes,requestedEnergies,departureTimes,chargingPowers)
    sta = ChargingStation(Inf,C,policy; snapshots=snapshots)
    connect!(arr,sta)
    sim = Simulation([arr,sta],params)

    simulate(sim, Tfinal)
    return sim

end


### DataFrame Compatibility

#Recibe un dataframe que tiene:
#arribos, demandas, salidas, potencias y opcionalmente salidaReportada
#se encarga de desarmar el dataframe y llamar a ev_sim_trace anterior
function ev_sim_trace(  df::DataFrame,
                        policy::Function,
                        C::Number,
                        snapshots=[Inf])

    ev_sim_trace(   df[!,:arrivalTimes],
                    df[!,:requestedEnergies],
                    df[!,:departureTimes],
                    df[!,:chargingPowers],
                    policy,
                    C,
                    snapshots)
    
end
