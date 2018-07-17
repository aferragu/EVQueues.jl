push!(LOAD_PATH,"simulator")
using EVQueues, PyPlot
using PGFPlots

C=80;
mu=1.0;
gamma=0.5;
Tfinal=200.0;

reps=30;

rango=collect(0.8:.02:1.2)*C
n=length(rango);
lambdas=zeros(n);
Wedf=zeros(n,reps);
Wps=zeros(n,reps);
Wllr=zeros(n,reps);
Wllf=zeros(n,reps);
#Wmean5=zeros(C);

i=0;
@time for lambda=rango
	i=i+1;
	println(lambda)
	lambdas[i]=lambda;

	for j=1:reps
		edf=ev_edf(lambda,mu,gamma,Tfinal,C)
		ps=ev_parallel(lambda,mu,gamma,Tfinal,C)
		llf=ev_llf(lambda,mu,gamma,Tfinal,C)
		llr=ev_llr(lambda,mu,gamma,Tfinal,C)
#	sim5=ev_pf(lambda,mu,gamma,Tfinal,c)

		compute_statistics!(edf);
		Wedf[i,j]=edf.avgW;
		compute_statistics!(ps);
		Wps[i,j]=ps.avgW;
		compute_statistics!(llf);
		Wllf[i,j]=llf.avgW;
		compute_statistics!(llr);
		Wllr[i,j]=llr.avgW;
	end

end

aWedf = mean(Wedf,2);
aWps = mean(Wps,2);
aWllf = mean(Wllf,2);
aWllr = mean(Wllr,2);

PyPlot.plot(lambdas/C,aWedf,"*",label="EDF")
PyPlot.plot(lambdas/C,aWps,"*",label="PS")
PyPlot.plot(lambdas/C,aWllf,"*",label="LLF")
PyPlot.plot(lambdas/C,aWllr,"*",label="LLR")

legend()

PyPlot.plot(lambdas/C,max.(1-C./lambdas,0))

fig = Axis([
    Plots.Linear(lambdas/C,aWedf[:], legendentry="EDF"),
	Plots.Linear(lambdas/C,aWps[:], legendentry="PS"),
	Plots.Linear(lambdas/C,aWllf[:], legendentry="LLF"),
	Plots.Linear(lambdas/C,aWllr[:], legendentry="LLR"),
	Plots.Linear(lambdas/C,max.(1-C./lambdas,0), legendentry="Fluid Limit")
    ], legendPos="south east", xlabel=L"\rho/C", ylabel="Fraction of reneged work")

save("comparison.tex",fig,include_preamble=false)
