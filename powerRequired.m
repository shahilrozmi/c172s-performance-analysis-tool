function [PR_W, D_N, CL, CD] = powerRequired(aircraft, atm, V_mps)
%POWERREQUIRED Calculate power required for steady level flight.
%
%   PR_W = POWERREQUIRED(AIRCRAFT, ATM, V_MPS) returns the aerodynamic
%   power required at the specified true airspeed.
%
%   [PR_W, D_N, CL, CD] also returns drag force, lift coefficient, and
%   drag coefficient.
%
%   Model:
%       PR = D V
%
%   The same expression is used as the shallow-climb approximation when
%   climb angle is less than approximately 20 degrees.

    if ~isstruct(aircraft) || ~isscalar(aircraft)
        error('powerRequired:InvalidAircraft', ...
            'aircraft must be a scalar structure.');
    end
    if ~isstruct(atm) || ~isscalar(atm)
        error('powerRequired:InvalidAtmosphere', ...
            'atm must be a scalar structure.');
    end
    if ~isfield(atm, 'rho')
        error('powerRequired:MissingDensity', ...
            'atm must contain the field atm.rho.');
    end

    validateattributes(atm.rho, {'numeric'}, ...
        {'real', 'finite', 'positive', 'scalar'}, ...
        mfilename, 'atm.rho', 2);
    validateattributes(V_mps, {'numeric'}, ...
        {'real', 'finite', 'positive', 'nonempty'}, ...
        mfilename, 'V_mps', 3);

    [D_N, CL, CD] = dragRequired(aircraft, atm, V_mps);
    PR_W = D_N .* V_mps;
end
