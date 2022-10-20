# EVQueues.jl

A policy simulator to evaluate deadline based scheduling policies for EV charging in a parking lot. Discrete-event simulator, supports synthetic Poisson arrivals and trace driven simulations.

A typical simulation involves:

 - An Arrival Process (Posson generated or Trace driven) that generates EVinstances.
 - One or multiple ChargingStations with given charging spots and power limitations and a policy (such as edf_policy). Check the `src/policies.jl` to see already defined policies or set your own.
 - If multiple charging stations are defined, a Router that determines how to choose one. Check the `src/policies.jl` to see already defined routing policies or set your own.
 - A Simulation object that collects all the above agents. Calling `simulate` on this object will perform the simulation.
 
Each object has a trace DataFrame that stores all the required information after simulation.

Check the `/examples` folder to see usage examples.

Developed by Andres Ferragut, Universidad ORT Uruguay

