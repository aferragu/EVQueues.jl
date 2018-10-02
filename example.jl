push!(LOAD_PATH,"simulator")
using EVQueues, PyPlot

lambda=120.0;
mu=1.0;
gamma=0.5;
C=80.0;

Tfinal=1000.0;


sim = ev_llf(lambda,mu,gamma,Tfinal,C,snapshots=[Tfinal])
#compute_statistics!(sim)

#rW = sim.W[:,2];
#sW=sort(rW[5000:end]);
#k=length(sW);
#PyPlot.plot(sW,(1:k)/k,drawstyle="steps")
