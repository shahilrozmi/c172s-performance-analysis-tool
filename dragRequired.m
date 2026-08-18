function [D, CL, CD] = dragRequired(aircraft, atm, V)
% DRAGREQUIRED Calculates the drag force required in steady level flight.
%
% INPUTS:
%   aircraft - Structure containing aircraft data
%   atm      - Structure containing atmospheric properties
%   V        - True airspeed (m/s)
%
% OUTPUTS:
%   D  - Drag force (N)
%   CL - Lift coefficient (-)
%   CD - Drag coefficient (-)
%
% Assumption:
%   Steady, level flight, so Lift = Weight.

%% Input Validation
if any(V(:) <= 0)
    error('Airspeed must be greater than zero.');
end

%% Lift Coefficient
CL = (2 * aircraft.W) ./ ...
    (atm.rho .* V.^2 .* aircraft.S);

%% Drag Coefficient
CD = dragPolar(aircraft, CL);

%% Drag Force
D = 0.5 .* atm.rho .* V.^2 .* aircraft.S .* CD;

end