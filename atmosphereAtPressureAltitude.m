function atm = atmosphereAtPressureAltitude(pressureAltitude_ft, deltaISA_C)
%ATMOSPHEREATPRESSUREALTITUDE Return atmosphere at pressure altitude.
%
%   Pressure is the ISA pressure at the requested pressure altitude.
%   Temperature is offset from ISA by DELTAISA_C, and density and speed of
%   sound are recomputed using the actual temperature.

    if nargin < 2 || isempty(deltaISA_C)
        deltaISA_C = 0;
    end

    validateattributes(pressureAltitude_ft, {'numeric'}, ...
        {'real', 'finite', 'nonnegative', 'scalar'}, ...
        mfilename, 'pressureAltitude_ft', 1);
    validateattributes(deltaISA_C, {'numeric'}, ...
        {'real', 'finite', 'scalar'}, mfilename, 'deltaISA_C', 2);

    FT_TO_M = 0.3048;
    R_AIR = 287.05287;
    GAMMA_AIR = 1.4;

    altitude_m = pressureAltitude_ft * FT_TO_M;
    atm = isaAtmosphere(altitude_m);
    atm.isaTemperature_K = atm.T;
    atm.isaTemperature_C = atm.T - 273.15;
    atm.deltaISA_C = deltaISA_C;
    atm.pressureAltitude_ft = pressureAltitude_ft;

    atm.T = atm.T + deltaISA_C;
    if atm.T <= 0
        error('atmosphereAtPressureAltitude:InvalidTemperature', ...
            'Actual temperature must be greater than absolute zero.');
    end

    atm.temperature_C = atm.T - 273.15;
    atm.rho = atm.P / (R_AIR * atm.T);
    atm.a = sqrt(GAMMA_AIR * R_AIR * atm.T);
end
