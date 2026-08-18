function [CD, k] = dragPolar(aircraft, CL)
% DRAGPOLAR Calculates drag coefficient using a parabolic drag polar.
%
% INPUTS:
%   aircraft - Aircraft structure containing CD0, e, and AR
%   CL       - Lift coefficient (-)
%
% OUTPUTS:
%   CD - Drag coefficient (-)
%   k  - Induced drag factor (-)

%% Induced Drag Factor
k = 1 / (pi * aircraft.e * aircraft.AR);

%% Drag Polar
CD = aircraft.CD0 + k .* CL.^2;

end