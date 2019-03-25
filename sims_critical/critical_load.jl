push!(LOAD_PATH,"simulator")
using EVQueues, Plots, Statistics

C=60.0;
mu=1.0;
gamma=0.5;
Nevs=15000*20;
trim = Integer(0.1*Nevs);

#reps=30;

rango=collect(0.9:0.01:1.1)*C
n=length(rango);
lambdas=zeros(n);
avgW=zeros(n);
avgW2=zeros(n);

i=0;
for lambda=rango
	global i=i+1;
	println("Arrival rate: $lambda")
	lambdas[i]=lambda;

	Tfinal = Nevs/lambda;
	sim=ev_parallel(lambda,mu,gamma,Tfinal,C)
	sim2=ev_las(lambda,mu,gamma,Tfinal,C)

	compute_statistics!(sim);
	compute_statistics!(sim2);

	avgW[i] = mean([ev.departureWorkload for ev in sim.EVs][trim:end])
	avgW2[i] = mean([ev.departureWorkload for ev in sim2.EVs][trim:end])

end

plot!(lambdas/C,max.(1 .- C./lambdas,0))
plot!(lambdas/C,avgW)
plot!(lambdas/C,avgW2)
