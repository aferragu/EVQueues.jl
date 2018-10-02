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
        "Policy" => policy,
        "SnapshotTimes" => snapshots
    )

    #variables aleatorias de los clientes
    arr_rng=Exponential(1.0/lambda);
    work_rng=Exponential(1.0/mu);
    deadline_rng=Exponential(1.0/gamma);

    #valores iniciales
    num=round(3.3*lambda*Tfinal);
    T=zeros(num);
    X=Array{UInt16}(length(T));   #charging vehicles
    Y=Array{UInt16}(length(T));   #already charged
    P=Array{Float64}(length(T));   #used power

    snaps = Array{Snapshot}(0);

    t=0.0;
    x=0;
    y=0;
    p=0.0;

    T[1]=t;
    X[1]=x;
    Y[1]=y;
    P[1]=p;

    i=1;    #event counter
    m=1;    #snapshot counter

    charging = Array{EVinstance}(0);
    alreadyCharged = Array{EVinstance}(0);
    finished = Array{EVinstance}(0);

    powerAllocation = Array{Float64}(0);

    arrivals=0;
    expired=0;

    nextArr = rand(arr_rng);
    nextCharge = Inf;
    nextDepON = Inf;
    nextDepOFF = Inf;
    nextSnapshot = snapshots[m];

    dt,caso = findmin([nextArr;nextCharge;nextDepON;nextDepOFF;nextSnapshot])

    while t<Tfinal

        t=t+dt;
        nextArr=nextArr-dt;
        nextSnapshot = nextSnapshot - dt;

        map(v->update_vehicle(v,dt),charging);
        map(v->update_vehicle(v,dt),alreadyCharged);


        if caso==1          #arribo
            arrivals=arrivals+1;
            nextArr = rand(arr_rng);
            x=x+1;

            #sorteo trabajo y deadline
            w=rand(work_rng);
            dep=t+w+rand(deadline_rng);
            push!(charging,EVinstance(t,dep,w,1.0););

        elseif caso==2      #charge completed
            x=x-1;
            y=y+1;

            #guardo el auto que termina
            aux,k = findmin([ev.currentWorkload for ev in charging]); ##TODO agregar un assert de que aux==0?
            ev = charging[k];

            push!(finished,ev);
            push!(alreadyCharged,ev);
            deleteat!(charging,k)

            ev.currentPower=0.0;
            ev.departureWorkload=0.0;
            ev.completionTime=t;

        elseif caso==3      #departure without full charge
            expired=expired+1;
            x=x-1;

            #guardo el auto que termina
            aux,k = findmin([ev.currentDeadline for ev in charging]);
            ev=charging[k];

            push!(finished,ev);
            deleteat!(charging,k)

            ev.currentPower=0.0;
            ev.departureWorkload = ev.currentWorkload;
            ev.completionTime=t;

        elseif caso==4      #departure after full charge
            y=y-1;
            aux,k = findmin([ev.currentDeadline for ev in alreadyCharged]);
            deleteat!(alreadyCharged,k);

        elseif caso==5      #take snapshot

            snapshot=Snapshot(t,charging,alreadyCharged);
            push!(snaps,snapshot);

            if (m<length(snapshots))
                m=m+1;
                nextSnapshot = snapshots[m]-t;
            else
                nextSnapshot = Inf;
            end

        end

        powerAllocation = policy(charging,C);
        for i=1:length(charging)
            charging[i].currentPower=powerAllocation[i]
        end
        p = sum(powerAllocation);

        if x>0

            nextCharge = minimum([ev.currentWorkload/ev.currentPower for ev in charging]);
            nextDepON = minimum([ev.currentDeadline for ev in charging]);
        else
            nextCharge = Inf;
            nextDepON = Inf;
        end

        if y>0
            nextDepOFF = minimum([ev.currentDeadline for ev in alreadyCharged]);
        else
            nextDepOFF = Inf;
        end

        i=i+1;
        T[i]=t;
        X[i]=x;
        Y[i]=y;
        P[i]=p;

        dt,caso = findmin([nextArr;nextCharge;nextDepON;nextDepOFF;nextSnapshot])

        progreso = ceil(Int64,t/Tfinal*100);
        update!(prog,progreso);

    end

    T=T[1:i];
    X=X[1:i];
    Y=Y[1:i];
    P=P[1:i];

    pD=expired/arrivals;
    next!(prog);

    trace = TimeTrace(T,X,Y,P);
    stats = SimStatistics([],[],[],[],0.0,0.0,pD,0.0);
    return EVSim(params,trace,finished,snaps,stats)
end
