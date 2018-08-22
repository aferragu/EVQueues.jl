push!(LOAD_PATH,"simulator")
using EVQueues, Plots, ProgressMeter

function create_frame(sim,snaps,i)

    p1 = plot(  xlims=(0,Tfinal),
                ylims=(0,maximum(sim.X)),
                xlabel="Time",
                ylabel="# vehicles",
                title="Vehicles in charge")

    plot!(p1, sim.T[sim.T.<snaps[i]], sim.X[sim.T.<snaps[i]],color=:blue,legend=:none,linewidth=2);

    #Fairness index de los que terminan
    t=snaps[snaps.<snaps[i]]*1.0;
    J=compute_fairness(sim,t,10.0);

    p2 = plot(  legend=:none,
                xlim=(0,Tfinal),
                ylim=(0,1),
                xlabel="Time",
                ylabel="J",
                title="Fairness index");

    plot!(p2,t,J,color=:blue,linewidth=2)

    w=sim.workloads[i];
    d=sim.deadlinesON[i];
    u=sim.U[i];

    p3=scatter( xlims = (0,3/mu),
                ylims = (0,3/gamma),
                xlabel="Remaining workload",
                ylabel="Remaining soujourn time",
                title="EV population",
                legendfont = Plots.Font("sans-serif",12,:hcenter,:vcenter,0.0,RGB{U8}(0.0,0.0,0.0))
                );

    if length(w)>0
        scatter!(p3,w[u.>0],d[u.>0],markershape=:circle,markersize=4,color=:blue,label="In service");
        scatter!(p3,w[u.==0],d[u.==0],markershape=:circle,markersize=4,color=:red,label="Not in service");
    end

    l=@layout [[a;b] c];
    p=plot(p1,p2,p3,layout=l,size=(1600,800))

end


##Parametros comunes
lambda=120.0;
mu=1.0;
gamma=0.5;
C=80;

Tfinal=50.0;
step=Tfinal/(24*30);
snaps = collect(step:step:Tfinal);

sim = ev_edf(lambda,mu,gamma,Tfinal,C,snapshots=snaps)

prog=Progress(length(snaps), dt=1, desc="Creando animacion... ");

anim = @animate for i=1:length(snaps)

    create_frame(sim,snaps,i)
    next!(prog);
end

gif(anim, "animations/output/anim_edf.gif", fps = 24)
savesim(sim,"animations/output/edf.sim")

p=create_frame(sim,snaps,length(snaps));
savefig(p,"animations/output/edf.png");
