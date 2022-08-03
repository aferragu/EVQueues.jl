function ev_sim(lambda,mu,gamma,Tfinal,C,policy,snapshots=[Inf])

    #barra de progreso
    prog=Progress(101, dt=0.5, desc="Simulando... ");

    #guardo parametros
    params = Dict(
        "ArrivalRate" => lambda,
        "AvgEnergy" => 1.0/mu,
        "AvgDeadline" => 1.0/mu + 1.0/gamma,
        "SimTime" => Tfinal,
        "Capacity" => C,
        "Policy" => get_policy_name(policy),
        "Snapshots" => length(snapshots)
    )

    
    #variables aleatorias de los clientes
    work_rng=Exponential(1.0/mu);
    laxity_rng=Exponential(1.0/gamma);

    #Proceso de arribos
    arr = PoissonArrivalProcess(lambda,work_rng,laxity_rng,1.0)
    sta = ChargingStation(10000,C,policy)
    connect!(arr,sta)
    agents = [arr,sta]::Vector{Agent}
    #valores para traza
    num=convert(Integer,round(3.3*lambda*Tfinal)+length(snapshots));
    T=zeros(num);
    X=zeros(UInt16,length(T));   #charging vehicles
    Y=zeros(UInt16,length(T));   #already charged
    P=zeros(Float64,length(T));   #used power

    snaps = Array{Snapshot}(undef,0);

    t=0.0
    T[1]=t;
    X[1]=0;
    Y[1]=0;
    P[1]=0.0;

    i=1;    #event counter
    m=1;    #snapshot counter

    ##TODO: consider snapshots
    nextSnapshot = snapshots[m];
    
    #nextEvent
    nextEvents = get_next_event.(agents)
    dt,idx = findmin([u[1] for u in nextEvents])
    event = nextEvents[idx][2]
    handler = agents[idx]
    
    while t<Tfinal

        t=t+dt;
        nextSnapshot = nextSnapshot - dt;

        update_state!.(agents, dt)

        handle_event(handler,t,event)

        # snapshot=Snapshot(t,deepcopy(charging),deepcopy(alreadyCharged));
        # push!(snaps,snapshot);

        # if (m<length(snapshots))
        #     m=m+1;
        #     nextSnapshot = snapshots[m]-t;
        # else
        #     nextSnapshot = Inf;
        # end


        i=i+1;
        T[i]=t;
        X[i]=length(sta.charging);
        Y[i]=length(sta.alreadyCharged);
        P[i]=sta.currentPower;

        nextEvents = get_next_event.(agents)
        dt,idx = findmin([u[1] for u in nextEvents])
        event = nextEvents[idx][2]
        handler = agents[idx]
    
        progreso = ceil(Integer,t/Tfinal*100);
        ProgressMeter.update!(prog,progreso);

    end

    T=T[1:i];
    X=X[1:i];
    Y=Y[1:i];
    P=P[1:i];

    next!(prog);

    trace = TimeTrace(T,X,Y,P);
    stats = SimStatistics([],[],[],[],NaN,NaN,NaN,NaN);
    return EVSim(params,trace,sta.completedEVs,snaps,stats)
end
