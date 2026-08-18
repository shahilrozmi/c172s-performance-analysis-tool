function atm = isaAtmosphere(h_m)
%ISAATMOSPHERE Calculate International Standard Atmosphere properties.
%
%   ATM = ISAATMOSPHERE(H_M) returns temperature, pressure, density, and
%   speed of sound in SI units. The model is valid in the troposphere from
%   0 to 11,000 m geometric altitude.

    validateattributes(h_m, {'numeric'}, ...
        {'real', 'finite', 'nonnegative', '<=', 11000, 'nonempty'}, ...
        mfilename, 'h_m', 1);

    T0_K = 288.15;
    P0_Pa = 101325;
    lapseRate_Kpm = 0.0065;
    gasConstant_JpkgK = 287.05287;
    gravity_mps2 = 9.80665;
    gammaAir = 1.4;

    atm.T = T0_K - lapseRate_Kpm .* h_m;
    atm.P = P0_Pa .* (atm.T ./ T0_K) .^ ...
        (gravity_mps2 / (lapseRate_Kpm * gasConstant_JpkgK));
    atm.rho = atm.P ./ (gasConstant_JpkgK .* atm.T);
    atm.a = sqrt(gammaAir * gasConstant_JpkgK .* atm.T);
end
