push!(LOAD_PATH,"simulator")
using EVQueues, Plots, Statistics

mu=1.0;
gamma=2.0;
Nevs=15000*30;
trim = Integer(0.2*Nevs);

#reps=30;

rango=[1;2;5;10;20;50;100;200;500]*1.0;
n=length(rango);
lambdas=rango;
Cs=rango;
avgW=zeros(n);
avgW2=zeros(n);

for i=1:n

	lambda = lambdas[i];
	println("Arrival rate: $lambda")
	C=Cs[i];
	println("Capacity: $C")

	Tfinal = Nevs/lambda;
	println("Tfinal: $Tfinal")

	sim=ev_edf(lambda,mu,gamma,Tfinal,C)
	sim2=ev_lifo(lambda,mu,gamma,Tfinal,C)

	compute_statistics!(sim);
	compute_statistics!(sim2);

	avgW[i] = mean([ev.departureWorkload for ev in sim.EVs][trim:end])
	avgW2[i] = mean([ev.departureWorkload for ev in sim2.EVs][trim:end])

end

scatter(lambdas,avgW,xscale = :log10,yscale=:log10)
scatter!(lambdas,avgW2,xscale = :log10,yscale=:log10)
