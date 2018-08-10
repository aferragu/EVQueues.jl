#=
ev_sim_trace(arribos,demandas,tiempos,C,policy)

Realiza la simulacion hasta terminar con los vehiculos de la lista.
arribos: lista de tiempos de arribo. Debe estar ordenada.
demandas: lista de demandas de carga, en tiempo.
salidas: lista de tiempos de salida
C: no. de cargadores simultaneos.
policy: una de las politicas definidas en EVSim
=#
function ev_sim_trace(arribos,demandas,salidas,policy,C,snapshots)

    num = length(arribos); #no. de vehiculos a procesar.
    prog=Progress(num+1, dt=0.5, desc="Simulando... ");

    eventos = 3*num+1+length(snapshots);

    #valores iniciales
    T=zeros(eventos);
    X=Array{UInt16}(length(T));   #charging vehicles
    Y=Array{UInt16}(length(T));   #already charged
    W=zeros(num,4);               #estadisticas de cada vehiculo

    t=0.0;
    x=0;
    y=0;

    T[1]=t;
    X[1]=x;
    Y[1]=y;
    i=1;    #event counter
    j=0;    #finished job counter
    m=1;    #snapshot counter

    workloads = Array{Float64}(0);
    workloadsOrig = Array{Float64}(0);
    deadlinesOrig = Array{Float64}(0);
    U = Array{Float64}(0); #charging rates 0<=U<=1
    deadlinesON = Array{Float64}(0);
    deadlinesOFF = Array{Float64}(0);
    arrivals=0;
    expired=0;

    #inicializo snapshots para que si no hay ninguno igual se cree.
    workloads_snapshot = Array{Array{Float64}}(0);
    deadlinesON_snapshot = Array{Array{Float64}}(0);
    U_snapshot = Array{Union{Float64,Vector{Float64}}}(0);
    j_snapshot =  Array{Int64}(0);

    nextArr = arribos[arrivals+1]-t; #inicializo al primer arribo
    nextCharge = Inf;
    nextDepON = Inf;
    nextDepOFF = Inf;

    nextSnapshot = snapshots[m]; #tiempo al cual hacer snapshot del estado

    dt,caso = findmin([nextArr;nextCharge;nextDepON;nextDepOFF;nextSnapshot])

    while dt<Inf

        t=t+dt;
        nextArr=nextArr-dt
        nextSnapshot = nextSnapshot - dt;

        workloads = workloads - U*dt;
        deadlinesON = deadlinesON - dt;
        deadlinesOFF = deadlinesOFF - dt;

        if caso==1          #arribo
            arrivals=arrivals+1;
            if arrivals<num
                nextArr = arribos[arrivals+1]-t;
            else
                nextArr = Inf;
            end

            x=x+1;
            workloads = [workloads;demandas[arrivals]];
            workloadsOrig = [workloadsOrig;workloads[end]];
            deadlinesON = [deadlinesON;salidas[arrivals]-t];
            deadlinesOrig = [deadlinesOrig;deadlinesON[end]];

        elseif caso==2      #charge completed
            x=x-1;
            y=y+1;
            aux,k = findmin(workloads)
            workloads = [workloads[1:k-1];workloads[k+1:end]];
            #anoto la carga relativa
            j=j+1;
            W[j,:] = [workloadsOrig[k] 0.0 deadlinesOrig[k] t];
            workloadsOrig = [workloadsOrig[1:k-1];workloadsOrig[k+1:end]];
            deadlinesOFF = [deadlinesOFF;deadlinesON[k]];
            deadlinesON = [deadlinesON[1:k-1];deadlinesON[k+1:end]]
            deadlinesOrig = [deadlinesOrig[1:k-1];deadlinesOrig[k+1:end]];
        elseif caso==3      #departure without full charge
            expired=expired+1;
            x=x-1;
            aux,k = findmin(deadlinesON);
            w=workloads[k];
            j=j+1;
            W[j,:] = [workloadsOrig[k] w deadlinesOrig[k] t];
            workloads = [workloads[1:k-1];workloads[k+1:end]];
            workloadsOrig = [workloadsOrig[1:k-1];workloadsOrig[k+1:end]];
            deadlinesON = [deadlinesON[1:k-1];deadlinesON[k+1:end]];
            deadlinesOrig = [deadlinesOrig[1:k-1];deadlinesOrig[k+1:end]];
        elseif caso==4      #departure after full charge
            y=y-1;
            aux,k = findmin(deadlinesOFF);
            deadlinesOFF = [deadlinesOFF[1:k-1];deadlinesOFF[k+1:end]]
        elseif caso==5      #take snapshot
            push!(workloads_snapshot,workloads);
            push!(deadlinesON_snapshot,deadlinesON);
            push!(U_snapshot,policy(workloads,deadlinesON,C)*1.0);
            push!(j_snapshot,j);

            if (m<length(snapshots))
                m=m+1;
                nextSnapshot = snapshots[m]-t;
            else
                nextSnapshot = Inf;
            end

        end

        #update charging rates
        U = policy(workloads,deadlinesON,C);

        if x>0
            nextCharge = minimum(workloads./U);
            nextDepON = minimum(deadlinesON);
        else
            nextCharge = Inf;
            nextDepON = Inf;
        end

        if y>0
            nextDepOFF = minimum(deadlinesOFF);
        else
            nextDepOFF = Inf;
        end

        i=i+1;
        T[i]=t;
        X[i]=x;
        Y[i]=y;

        dt,caso = findmin([nextArr;nextCharge;nextDepON;nextDepOFF;nextSnapshot])

        update!(prog,arrivals);
    end

    T=T[1:i];
    X=X[1:i];
    Y=Y[1:i];
    W=W[1:j,:];

    pD=expired/arrivals;

    next!(prog);

    #rangeX,pX,rangeY,pY,avgX,avgY,avgW = compute_statistics(T,X,Y,W,pD)
    #return EVSim(T,X,Y,W,pD,rangeX,pX,rangeY,pY,avgX,avgY,avgW)
    #return EVSim(T,X,Y,W,pD,workloads_snapshot,deadlinesON_snapshot,U_snapshot)
    return EVSim(T,X,Y,W,pD,workloads_snapshot,deadlinesON_snapshot,U_snapshot,j_snapshot)
end
