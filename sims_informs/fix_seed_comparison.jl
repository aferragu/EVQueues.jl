push!(LOAD_PATH,"simulator")
using EVQueues, Plots, Random

lambda=150.0;
mu=1.0;
gamma=0.5;
C=75.0;

Tfinal=100.0;

Random.seed!(1234);

edf = ev_edf(lambda,mu,gamma,Tfinal,C)
compute_statistics!(edf)

Random.seed!(1234);

lifo = ev_lifo(lambda,mu,gamma,Tfinal,C)
compute_statistics!(lifo)


edf_evs = sort(edf.EVs,by=ev->ev.arrivalTime)
lifo_evs = sort(lifo.EVs,by=ev->ev.arrivalTime)

n=13000;

edf_evs = edf_evs[1:n]
lifo_evs = lifo_evs[1:n]

S_edf = [ev.requestedEnergy for ev in edf_evs];
S_lifo = [ev.requestedEnergy for ev in lifo_evs];

Sr_edf = [ev.departureWorkload for ev in edf_evs];
Sr_lifo = [ev.departureWorkload for ev in lifo_evs];

Sa_edf = S_edf - Sr_edf
Sa_lifo = S_lifo - Sr_lifo

scatter(S_edf,S_lifo)
scatter(Sa_edf,Sa_lifo)
