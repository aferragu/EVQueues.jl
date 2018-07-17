push!(LOAD_PATH,"simulator")
using EVQueues

mu=1.0;
gamma=2.0;



	c=1;
	lambdai = c*1.0;
	Tfinal = 1.0e6/lambdai;

@time	sim1=ev_edf(lambdai,mu,gamma,Tfinal,c)
@time	sim2=ev_parallel(lambdai,mu,gamma,Tfinal,c)
@time	sim3=ev_llf(lambdai,mu,gamma,Tfinal,c)
#	sim4=ev_llr(lambdai,mu,gamma,Tfinal,c)
#	sim5=ev_pf(lambdai,mu,gamma,Tfinal,c)

compute_statistics!(sim1);
compute_statistics!(sim2);
compute_statistics!(sim3);
