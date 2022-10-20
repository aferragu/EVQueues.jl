using EVQueues, DataFrames, Plots

#Arrival times, must be ordered
arrivals = [1.0;2.0;3.0];
#Departure times, correlative to arrivals.
departures = [12.0;13.0;14.0];
#Requested energies
energies = [4.0;5.0;6.0];
#Charging powers
powers = [1.0;1.0;1.0];

data = DataFrame(:arrivalTimes => arrivals, :departureTimes => departures, :requestedEnergies => energies, :chargingPowers => powers)

arr = TraceArrivalProcess(data)

#Max power
P=1.0;
sta = ChargingStation(Inf, P, fifo_policy, snapshots=[10.5,12.5])

connect!(arr,sta)

sim = Simulation([arr,sta])

#Simulate
simulate(sim)

#Show stats
show(compute_statistics(sta))

#TIme plot of occupation and power
p=plot(sta)
display(p)

#State space of the second snapshot
snap = sta.snapshots[2];
p=stateplot(snap.charging)
display(p)