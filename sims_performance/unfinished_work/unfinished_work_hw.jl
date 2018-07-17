push!(LOAD_PATH,"simulator")
using EVQueues, PyPlot

mu=1.0;
gamma=0.5;

beta=1;

rango=[10;20;40;60;80;100;200;500]
lambda = zeros(length(rango));
C=zeros(length(rango));
Wmean1=zeros(C);
Wmean2=zeros(C);
Wmean3=zeros(C);
Wmean4=zeros(C);
Wmean5=zeros(C);

i=0;
for c=rango

	i=i+1;
	println(c)

	lambdai = c;
	C[i]=c;
	lambda[i]=lambdai;
	Tfinal = 5.0e4/lambdai;

	sim1=ev_edf(lambdai,mu,gamma,Tfinal,c)
	sim2=ev_parallel(lambdai,mu,gamma,Tfinal,c)
	sim3=ev_llf(lambdai,mu,gamma,Tfinal,c)
	sim4=ev_llr(lambdai,mu,gamma,Tfinal,c)
	sim5=ev_pf(lambdai,mu,gamma,Tfinal,c)

	compute_statistics!(sim1);
	Wmean1[i]=sim1.avgW;
	compute_statistics!(sim2);
	Wmean2[i]=sim2.avgW;
	compute_statistics!(sim3);
	Wmean3[i]=sim3.avgW;
	compute_statistics!(sim4);
	Wmean4[i]=sim4.avgW;
	compute_statistics!(sim5);
	Wmean5[i]=sim5.avgW;


end

plot(C,Wmean1,label="EDF")
plot(C,Wmean2,label="PS")
plot(C,Wmean3,label="LLF")
plot(C,Wmean4,label="LLR")
plot(C,Wmean5,label="PF")

legend()
