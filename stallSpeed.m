function Vs_mps = stallSpeed(aircraft, atm)
%STALLSPEED Calculate flaps-up stall speed in equivalent/true airspeed.
%
%   VS_MPS = STALLSPEED(AIRCRAFT, ATM) uses the local density in ATM, so
%   the result is true airspeed at the requested atmospheric condition.

    requiredAircraftFields = {'W', 'S', 'CLmax'};
    for k = 1:numel(requiredAircraftFields)
        if ~isfield(aircraft, requiredAircraftFields{k})
            error('stallSpeed:MissingAircraftField', ...
                'aircraft.%s is required.', requiredAircraftFields{k});
        end
    end
    if ~isfield(atm, 'rho')
        error('stallSpeed:MissingDensity', ...
            'atm.rho is required.');
    end

    validateattributes(aircraft.W, {'numeric'}, ...
        {'real', 'finite', 'positive', 'scalar'});
    validateattributes(aircraft.S, {'numeric'}, ...
        {'real', 'finite', 'positive', 'scalar'});
    validateattributes(aircraft.CLmax, {'numeric'}, ...
        {'real', 'finite', 'positive', 'scalar'});
    validateattributes(atm.rho, {'numeric'}, ...
        {'real', 'finite', 'positive', 'scalar'});

    Vs_mps = sqrt((2 * aircraft.W) / ...
        (atm.rho * aircraft.S * aircraft.CLmax));
end
