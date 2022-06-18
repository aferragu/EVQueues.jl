function get_largest_deadline(charging::Vector{EVinstance})
    active = filter(ev -> ev.currentPower>0, charging)
    if length(active)>0
        return maximum(deadline.(active))
    else
        return Inf
    end
end

function get_largest_laxity(charging::Vector{EVinstance})
    active = filter(ev -> ev.currentPower>0, charging)
    if length(active)>0
        return maximum(laxity.(active))
    else
        return Inf
    end
end

function get_lowest_inactive_laxity(charging::Vector{EVinstance})
    inactive = filter(ev -> ev.currentPower==0, charging)
    if length(inactive)>0
        return minimum(laxity.(inactive))
    else
        return Inf
    end
end



function ev_sim_two_parkings(lambda,mu,gamma,Tfinal,C,policy,routing_policy,snapshots=[Inf])

    #barra de progreso
    prog=Progress(101, dt=0.5, desc="Simulando... ");

    #guardo parametros
    params = Dict(
        "ArrivalRate" => lambda,
        "AvgEnergy" => 1.0/mu,
        "AvgDeadline" => 1.0/mu + 1.0/gamma,
        "SimTime" => Tfinal,
        "Capacity" => C,
        "Policy" => "EDF",
        "Snapshots" => length(snapshots)
    )

    #variables aleatorias de los clientes
    arr_rng=Exponential(1.0/lambda);
    work_rng=Exponential(1.0/mu);
    deadline_rng=Exponential(1.0/gamma);

    #valores iniciales
    num=convert(Integer,round(3.3*lambda*Tfinal)+length(snapshots));
    T=zeros(num);

    X1=zeros(UInt16,length(T));   #charging vehicles
    X2=zeros(UInt16,length(T));   #charging vehicles

    Y1=zeros(UInt16,length(T));   #already charged
    Y2=zeros(UInt16,length(T));   #already charged

    P1=zeros(Float64,length(T));   #used power
    P2=zeros(Float64,length(T));   #used power

    snaps1 = Array{Snapshot}(undef,0);
    snaps2 = Array{Snapshot}(undef,0);

    t=0.0;

    x1=0;
    x2=0;

    y1=0;
    y2=0;

    p1=0.0;
    p2=0.0;

    T[1]=t;
    X1[1]=x1;
    X2[1]=x2;
    Y1[1]=y1;
    Y2[1]=y2;
    P1[1]=p1;
    P2[1]=p2;

    i=1;    #event counter
    m=1;    #snapshot counter

    charging1 = Array{EVinstance}(undef,0);
    alreadyCharged1 = Array{EVinstance}(undef,0);
    finished1 = Array{EVinstance}(undef,0);

    charging2 = Array{EVinstance}(undef,0);
    alreadyCharged2 = Array{EVinstance}(undef,0);
    finished2 = Array{EVinstance}(undef,0);

    powerAllocation1 = Array{Float64}(undef,0);
    powerAllocation2 = Array{Float64}(undef,0);

    arrivals=0;
    expired=0;

    nextArr = rand(arr_rng);
    nextCharge1 = Inf;
    nextDepON1 = Inf;
    nextDepOFF1 = Inf;
    nextCharge2 = Inf;
    nextDepON2 = Inf;
    nextDepOFF2 = Inf;
    nextSnapshot = snapshots[m];

    dt,caso = findmin([nextArr,nextCharge1,nextDepON1,nextDepOFF1,nextCharge2,nextDepON2,nextDepOFF2,nextSnapshot])

    while t<Tfinal

        t=t+dt;
        nextArr=nextArr-dt;
        nextSnapshot = nextSnapshot - dt;

        map(v->update_vehicle(v,dt),charging1);
        map(v->update_vehicle(v,dt),alreadyCharged1);
        map(v->update_vehicle(v,dt),charging2);
        map(v->update_vehicle(v,dt),alreadyCharged2);


        if caso==1          #arribo
            arrivals=arrivals+1;
            nextArr = rand(arr_rng);

            #sorteo trabajo y deadline
            w=rand(work_rng);
            dep=t+w+rand(deadline_rng);

            ##ruteo
            tau1 = routing_policy(charging1)
            tau2 = routing_policy(charging2)

            if tau1 >= tau2
                push!(charging1,EVinstance(t,dep,w,1.0));
                x1=x1+1;
            else
                push!(charging2,EVinstance(t,dep,w,1.0));
                x2=x2+1;
            end

        elseif caso==2      #charge 1 completed
            x1=x1-1;
            y1=y1+1;

            #guardo el auto que termina
            aux,k = findmin([ev.currentWorkload for ev in charging1]); ##TODO agregar un assert de que aux==0?
            ev = charging1[k];

            push!(finished1,ev);
            push!(alreadyCharged1,ev);
            deleteat!(charging1,k)

            ev.currentPower=0.0;
            ev.departureWorkload=0.0;
            ev.completionTime=t;

        elseif caso==3      #departure without full charge
            expired=expired+1;
            x1=x1-1;

            #guardo el auto que termina
            aux,k = findmin([ev.currentDeadline for ev in charging1]);
            ev=charging1[k];

            push!(finished1,ev);
            deleteat!(charging1,k)

            ev.currentPower=0.0;
            ev.departureWorkload = ev.currentWorkload;
            ev.completionTime=t;

        elseif caso==4      #departure after full charge
            y1=y1-1;
            aux,k = findmin([ev.currentDeadline for ev in alreadyCharged1]);
            deleteat!(alreadyCharged1,k);

        elseif caso==5      #charge 1 completed
            x2=x2-1;
            y2=y2+1;

            #guardo el auto que termina
            aux,k = findmin([ev.currentWorkload for ev in charging2]); ##TODO agregar un assert de que aux==0?
            ev = charging2[k];

            push!(finished2,ev);
            push!(alreadyCharged2,ev);
            deleteat!(charging2,k)

            ev.currentPower=0.0;
            ev.departureWorkload=0.0;
            ev.completionTime=t;

        elseif caso==6      #departure without full charge
            expired=expired+1;
            x2=x2-1;

            #guardo el auto que termina
            aux,k = findmin([ev.currentDeadline for ev in charging2]);
            ev=charging2[k];

            push!(finished2,ev);
            deleteat!(charging2,k)

            ev.currentPower=0.0;
            ev.departureWorkload = ev.currentWorkload;
            ev.completionTime=t;

        elseif caso==7      #departure after full charge
            y2=y2-1;
            aux,k = findmin([ev.currentDeadline for ev in alreadyCharged2]);
            deleteat!(alreadyCharged2,k);

        elseif caso==8      #take snapshot

            snapshot1=Snapshot(t,deepcopy(charging1),deepcopy(alreadyCharged1));
            push!(snaps1,snapshot1);

            snapshot2=Snapshot(t,deepcopy(charging2),deepcopy(alreadyCharged2));
            push!(snaps2,snapshot2);

            if (m<length(snapshots))
                m=m+1;
                nextSnapshot = snapshots[m]-t;
            else
                nextSnapshot = Inf;
            end

        end

        if x1>0
            #Apply the policy to all vehicles. Return total user power
            p1 = policy(charging1,C[1]);

            if minimum([ev.currentWorkload for ev in charging1])==0
                nextCharge1=0;
            else
                nextCharge1 = minimum([ev.currentWorkload/ev.currentPower for ev in charging1]);
            end

            nextDepON1 = minimum([ev.currentDeadline for ev in charging1]);
        else
            nextCharge1 = Inf;
            nextDepON1 = Inf;
            p1=0.0;
        end

        if x2>0
            #Apply the policy to all vehicles. Return total user power
            p2 = policy(charging2,C[2]);

            if minimum([ev.currentWorkload for ev in charging2])==0
                nextCharge2=0;
            else
                nextCharge2 = minimum([ev.currentWorkload/ev.currentPower for ev in charging2]);
            end

            nextDepON2 = minimum([ev.currentDeadline for ev in charging2]);
        else
            nextCharge2 = Inf;
            nextDepON2 = Inf;
            p2=0.0;
        end

        if y1>0
            nextDepOFF1 = minimum([ev.currentDeadline for ev in alreadyCharged1]);
        else
            nextDepOFF1 = Inf;
        end

        if y2>0
            nextDepOFF2 = minimum([ev.currentDeadline for ev in alreadyCharged2]);
        else
            nextDepOFF2 = Inf;
        end

        i=i+1;
        T[i]=t;
        X1[i]=x1;
        Y1[i]=y1;
        P1[i]=p1;
        X2[i]=x2;
        Y2[i]=y2;
        P2[i]=p2;

        dt,caso = findmin([nextArr,nextCharge1,nextDepON1,nextDepOFF1,nextCharge2,nextDepON2,nextDepOFF2,nextSnapshot])

        progreso = ceil(Integer,t/Tfinal*100);
        ProgressMeter.update!(prog,progreso);

    end

    T=T[1:i];
    X1=X1[1:i];
    Y1=Y1[1:i];
    P1=P1[1:i];
    X2=X2[1:i];
    Y2=Y2[1:i];
    P2=P2[1:i];

    pD=expired/arrivals;
    next!(prog);

    trace1 = TimeTrace(T,X1,Y1,P1);
    trace2 = TimeTrace(T,X2,Y2,P2);

    stats1 = SimStatistics([],[],[],[],NaN,NaN,NaN,NaN);
    stats2 = SimStatistics([],[],[],[],NaN,NaN,NaN,NaN);

    return EVSimParallel(params,[trace1,trace2],[finished1,finished2],[snaps1,snaps2],[stats1,stats2])
end
