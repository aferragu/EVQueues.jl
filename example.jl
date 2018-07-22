push!(LOAD_PATH,"simulator")
using EVQueues, PyPlot

lambda=120.0;
mu=1.0;
gamma=0.5;
C=80;

Tfinal=1000.0;


@time sim = ev_edf(lambda,mu,gamma,Tfinal,C)
compute_statistics!(sim)

rW = sim.W[:,2];
sW=sort(rW[5000:end]);
k=length(sW);
PyPlot.plot(sW,(1:k)/k,drawstyle="steps")
