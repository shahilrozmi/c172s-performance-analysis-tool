function sweep = climbAltitudeSweep(altitudeStep_ft)
%CLIMBALTITUDESWEEP Evaluate the published POH climb envelope.
%
%   SWEEP = CLIMBALTITUDESWEEP() evaluates the C172S Figure 5-6 climb
%   reference every 250 ft from sea level to 12,000 ft. Curves are produced
%   for the four published outside-air-temperature columns and for ISA.

    if nargin < 1 || isempty(altitudeStep_ft)
        altitudeStep_ft = 250;
    end

    validateattributes(altitudeStep_ft, {'numeric'}, ...
        {'real', 'finite', 'positive', 'scalar', '<=', 12000}, ...
        mfilename, 'altitudeStep_ft', 1);

    altitude_ft = 0:altitudeStep_ft:12000;
    if altitude_ft(end) ~= 12000
        altitude_ft = [altitude_ft, 12000];
    end

    oatColumns_C = [-20, 0, 20, 40];
    rateOfClimb_fpm = nan(numel(altitude_ft), numel(oatColumns_C));
    standardDayRateOfClimb_fpm = nan(size(altitude_ft));
    climbSpeed_KIAS = nan(size(altitude_ft));

    for altitudeIndex = 1:numel(altitude_ft)
        altitude = altitude_ft(altitudeIndex);
        isaAtmosphereAtAltitude = ...
            atmosphereAtPressureAltitude(altitude, 0);

        standardDay = pohClimbPerformance(altitude, 0);
        standardDayRateOfClimb_fpm(altitudeIndex) = ...
            standardDay.rateOfClimb_fpm;
        climbSpeed_KIAS(altitudeIndex) = standardDay.climbSpeed_KIAS;

        for temperatureIndex = 1:numel(oatColumns_C)
            deltaISA_C = oatColumns_C(temperatureIndex) - ...
                isaAtmosphereAtAltitude.isaTemperature_C;

            try
                point = pohClimbPerformance(altitude, deltaISA_C);
                rateOfClimb_fpm(altitudeIndex, temperatureIndex) = ...
                    point.rateOfClimb_fpm;
            catch ME
                if ~startsWith(ME.identifier, ...
                        'pohClimbPerformance:TemperatureOutsidePOH')
                    rethrow(ME)
                end
                % The 12,000-ft/40-C POH entry is not published. Values
                % requiring that corner remain NaN rather than extrapolated.
            end
        end
    end

    sweep = struct( ...
        'altitude_ft', altitude_ft, ...
        'oatColumns_C', oatColumns_C, ...
        'rateOfClimb_fpm', rateOfClimb_fpm, ...
        'standardDayRateOfClimb_fpm', standardDayRateOfClimb_fpm, ...
        'climbSpeed_KIAS', climbSpeed_KIAS, ...
        'source', 'C172S POH Figure 5-6');
end
