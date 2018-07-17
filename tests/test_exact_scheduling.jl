push!(LOAD_PATH,"simulator")
using EVQueues, PyPlot

lambda=100.0;
mu=1.0;
gamma=0.2;

Tfinal=100.0;

#@time sim = ev_parallel(lambda,mu,gamma,Tfinal,C)
@time sim = ev_exact(lambda,mu,gamma,Tfinal)
@time sim2 = ev_exact(lambda,mu,999999.0,Tfinal)

#@time compute_statistics!(sim)
