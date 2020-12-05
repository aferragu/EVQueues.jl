using RecipesBase

@userplot StatePlot

@recipe function f(p::StatePlot)

    evs = p.args[1]

    xguide --> "Remaining workload"
    yguide --> "Remaining deadline"
    markershape --> :circle

    w = [ev.currentWorkload for ev in evs];
    d = [ev.currentDeadline for ev in evs];
    u = [ev.currentPower>0 for ev in evs];

    @series begin

        seriestype := :scatter
        label := "Charging"
        seriescolor := :blue

        w[u.>0], d[u.>0]
    end

    @series begin

        seriestype := :scatter
        label := "Waiting"
        seriescolor := :red

        w[u.==0], d[u.==0]
    end

end

@userplot ReversedStatePlot

@recipe function f(p::ReversedStatePlot)

    evs = p.args[1]

    xguide --> "Attained workload"
    yguide --> "Sojourn time"
    markershape --> :circle

    w = [ev.requestedEnergy - ev.currentWorkload for ev in evs];
    d = [ev.departureTime - ev.arrivalTime - ev.currentDeadline for ev in evs];
    u = [ev.currentPower>0 for ev in evs];

    @series begin

        seriestype := :scatter
        label := "Charging"
        seriescolor --> :blue

        w[u.>0], d[u.>0]
    end

    @series begin

        seriestype := :scatter
        label := "Waiting"
        seriescolor --> :red

        w[u.==0], d[u.==0]
    end

end

@userplot struct ServicePlot{T<:Tuple{AbstractVector}}
    args::T
end

@recipe function f(p::ServicePlot{Tuple{Array{EVQueues.EVinstance,1}}})

    evs = p.args[1]

    xguide --> "Requested Energy"
    yguide --> "Attained Energy"
    markershape --> :circle

    S = [ev.requestedEnergy for ev in evs];
    Sa = [ev.requestedEnergy-ev.departureWorkload for ev in evs];

    @series begin

        seriestype := :scatter
        label --> "Charged EVs"

        S,Sa
    end

end

@userplot ServiceCDF

@recipe function f(p::ServiceCDF)

    evs = p.args[1]

    xguide --> "Attained service"
    yguide --> "CDF"
    legend --> :bottomright

    S = sort([ev.requestedEnergy for ev in evs])
    Sa = sort([ev.requestedEnergy-ev.departureWorkload for ev in evs])
    n=length(Sa)

    @series begin

        seriestype := :steppost
        label := "Attained service"
        Sa,(1:n)/n
    end

    @series begin

        seriestype := :steppost
        label := "Requested service"
        S,(1:n)/n
    end

end

@recipe function f(trace::EVQueues.TimeTrace)

    T=trace.T
    X=trace.X
    Y=trace.Y
    P=trace.P

    size --> (600,800)
    xguide --> "Time"
    legend := :none
    layout := (3,1)

    @series begin

        subplot := 1
        seriestype := :steppost
        title --> "#EV in charge"
        T,X
    end

    @series begin

        subplot := 2
        seriestype := :steppost
        title --> "#EV already charged"
        T,Y
    end

    @series begin

        subplot := 3
        seriestype := :steppost
        title --> "Charging Power"
        T,P
    end

end
