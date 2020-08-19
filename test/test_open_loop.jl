push!(LOAD_PATH,"simulator")
using EVQueues, Plots

lambda=120.0;
mu=1.0;
gamma=0.5;

C=60.0;

Tfinal=1000.0;

sim = ev_llf(lambda,mu,gamma,Tfinal,C,snapshots=[Tfinal])
compute_statistics!(sim)

#sim2 = ev_edffixed(lambda,mu,gamma,Tfinal,C,snapshots=[Tfinal])
#compute_statistics!(sim2)
