using EVQueues, PGFPlots

lambda=120.0;
mu=1.0;
gamma=0.5;
#C=80.0;
C=60.0;

Tfinal=100.0;


edf = ev_edf(lambda,mu,gamma,Tfinal,C,snapshots=[Tfinal])
llf = ev_llf(lambda,mu,gamma,Tfinal,C,snapshots=[Tfinal])
llr = ev_llr(lambda,mu,gamma,Tfinal,C,snapshots=[Tfinal])

#compute_statistics!(sim)

fig = Axis([
                Plots.Linear([ev.requestedEnergy for ev in edf.EVs][6000:10:end],[ev.requestedEnergy-ev.departureWorkload for ev in edf.EVs][6000:10:end], style="solid,only marks=true,blue", legendentry="EDF"),
                Plots.Linear([ev.requestedEnergy for ev in llf.EVs][6000:10:end],[ev.requestedEnergy-ev.departureWorkload for ev in llf.EVs][6000:10:end], style="solid,only marks=true,red", legendentry="LLF"),
                Plots.Linear([ev.requestedEnergy for ev in llr.EVs][6000:10:end],[ev.requestedEnergy-ev.departureWorkload for ev in llr.EVs][6000:10:end], style="solid,only marks=true,green", legendentry="LLR"),
           ],
           legendPos="north west", xlabel="Requested Service (\$S\$)", ylabel="Attained Service (\$S_r\$)", xmin=0, xmax=3, ymin=0, ymax=3, width="0.7\\columnwidth", height="0.4\\columnwidth"
    );

save("/tmp/sigma_compare.tex",fig,include_preamble=false)
