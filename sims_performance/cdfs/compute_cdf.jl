push!(LOAD_PATH,"simulator")
using EVQueues, PyPlot, PGFPlots

function compute_cdf(W)
    sW = sort(W);
    k = length(sW);
    return sW,collect(1:k)/k
end

lambda=120.0;
mu=1.0;
gamma=0.5;
C=80.0;

Tfinal=500.0;

edf = ev_edf(lambda,mu,gamma,Tfinal,C)
compute_statistics!(edf)

llf = ev_llf(lambda,mu,gamma,Tfinal,C)
compute_statistics!(llf)

llr = ev_llr(lambda,mu,gamma,Tfinal,C)
compute_statistics!(llr)

#calculo la CDF
k=10000;      #cuantos saco del comienzo para sacar el transitorio

Wedf,Fedf = compute_cdf([ev.departureWorkload for ev in edf.EVs][k:end]);
PyPlot.plot(Wedf,Fedf,drawstyle="steps")

tauast = -1/mu*log(1-C*mu/lambda);
Fedf_teo = 1-exp.(-mu*(Wedf+tauast))
PyPlot.plot(Wedf,Fedf_teo)


figure()
Wllf,Fllf = compute_cdf([ev.departureWorkload for ev in llf.EVs][k:end]);
PyPlot.plot(Wllf,Fllf,drawstyle="steps")

sigmaast = -1/mu*log(C*mu/lambda);
Fllf_teo = (1-exp.(-mu*(Wllf))).*(Wllf.<sigmaast) + (Wllf.>sigmaast);
PyPlot.plot(Wllf,Fllf_teo)

figure()
Wllr,Fllr = compute_cdf([ev.departureWorkload for ev in llr.EVs][k:end]);
PyPlot.plot(Wllr,Fllr,drawstyle="steps")

theta = C*mu/lambda;
Fllr_teo = 1-exp.(-mu*(Wllr/(1-theta)));
PyPlot.plot(Wllr,Fllr_teo)

paso = 500;
fig = Axis([
    Plots.Linear(Wedf[1:paso:end],Fedf[1:paso:end], legendentry="CDF of reneged work in EDF"),
    Plots.Linear(Wedf[1:paso:end],Fedf_teo[1:paso:end], legendentry="Fluid prediction"),
    ], legendPos="north east", xlabel=L"\sigma_r")

save("sims_performance/cdfs/edf_cdf.tex",fig,include_preamble=false)


fig = Axis([
    Plots.Linear(Wllf[1:paso:end],Fllf[1:paso:end], legendentry="CDF of reneged work in LLF"),
    Plots.Linear(Wllf[1:paso:end],Fllf_teo[1:paso:end], legendentry="Fluid prediction"),
    ], legendPos="north east", xlabel=L"\sigma_r")

save("sims_performance/cdfs/llf_cdf.tex",fig,include_preamble=false)


fig = Axis([
    Plots.Linear(Wllr[1:paso:end],Fllr[1:paso:end], legendentry="CDF of reneged work in LLR"),
    Plots.Linear(Wllr[1:paso:end],Fllr_teo[1:paso:end], legendentry="Fluid prediction"),
    ], legendPos="north east", xlabel=L"\sigma_r")

save("sims_performance/cdfs/llr_cdf.tex",fig,include_preamble=false)
