push!(LOAD_PATH,"simulator")
using EVQueues, PyPlot#PGFPlots, PyPlot #, StatsBase

lambda=120.0;
mu=1.0;
gamma=0.5;
C=80;

Tfinal=100.0;


@time sim = ev_edf(lambda,mu,gamma,Tfinal,C)
compute_statistics!(sim)
#@time sim2 = ev_llf(lambda,mu,gamma,Tfinal,C)
#compute_statistics!(sim2)


#plot using PyPlot and then save using PGFPlots
# PyPlot.plot(sim.workloads, sim.deadlinesON, "*", label="All")
# PyPlot.plot(sim.workloads[sim.U.==1],sim.deadlinesON[sim.U.==1], "*", label="In service")
# PyPlot.plot(sim.workloads[sim.U.==0],sim.deadlinesON[sim.U.==0], "*", label="Not in service")

#density of workloads
# sW=sort(sim.W[5000:end,2]);
# k=length(sW);
# PyPlot.plot(sW,(1:k)/k,drawstyle="steps")

rW = sim.W[:,2];
sW=sort(rW[5000:end]);
k=length(sW);
PyPlot.plot(sW,(1:k)/k,drawstyle="steps")


# fig = Axis([
#     Plots.Linear(sim.workloads[sim.U.==1],sim.deadlinesON[sim.U.==1], onlyMarks=true, style="azulcito", legendentry="In service"),
#     Plots.Linear(sim.workloads[sim.U.==0],sim.deadlinesON[sim.U.==0], onlyMarks=true, style="rojito", legendentry="Not in service"),
#     ], legendPos="north east", xlabel=L"\sigma", ylabel=L"\tau")
#
# save("edf.tex",fig,include_preamble=false)

# quiver(sim.workloads[sim.U.==1],sim.deadlinesON[sim.U.==1],-sim.U[sim.U.==1],-ones(size(sim.U[sim.U.==1])),color="red", scale=20, angles="xy")
# quiver(sim.workloads[sim.U.<1],sim.deadlinesON[sim.U.<1],-sim.U[sim.U.<1],-ones(size(sim.U[sim.U.<1])),color="blue", scale=20, angles="xy")
# axis("square")
# grid()
#figure()
#quiver(sim.workloads[sim.U.==0],sim.deadlinesON[sim.U.==0]-sim.workloads[sim.U.==0],-sim.U[sim.U.==0],-ones(size(sim.U[sim.U.==0]))+-sim.U[sim.U.==0],color="red", scale=100, angles="xy")
#quiver(sim.workloads[sim.U.>0],sim.deadlinesON[sim.U.>0]-sim.workloads[sim.U.>0],-sim.U[sim.U.>0],-ones(size(sim.U[sim.U.>0]))+sim.U[sim.U.>0],color="blue", scale=100, angles="xy")

#print(sim)
#
#  figure()
#  h=fit(Histogram,sim.W[:,2])
#  bar(h.edges[1][1:end-1],h.weights)
# #
# k=collect(0:3*lambda/mu);
# p=1.0;
# P=zeros(k,Float64);
# P[1]=p;
#
# for i=2:length(k)
#  p=p*lambda/(min(k[i],C)*mu+k[i]*gamma);
#  P[i]=p;
# end
# P=P/sum(P);
# stem(k,P)

#plot(sim.W[:,1],sim.W[:,2],"o")
#plot(sim2.W[:,1],sim2.W[:,2],"or")
#figure()
#plot3D(sim.W[:,1],sim.W[:,2],sim.W[:,3],"or")
#plot3D(sim.W[:,1],sim.W[:,3]-sim.W[:,1],sim.W[:,2],"or")
