function setting = pohCruiseAtPower( ...
        pressureAltitude_ft, targetPercentMCP, deltaISA_C)
%POHCRUISEATPOWER Invert Figure 5-8 for RPM at a requested power.
%
%   SETTING = POHCRUISEATPOWER(ALTITUDE_FT, TARGETPERCENTMCP,
%   DELTAISA_C) finds the engine RPM that reproduces the requested percent
%   maximum continuous power within the published C172S POH Figure 5-8
%   cruise envelope. The returned KTAS and fuel flow are evaluated through
%   the same centralized interpolation path as the rest of the project.
%
%   No RPM or altitude extrapolation is permitted. A target power that is
%   not attainable within the common published RPM range at the requested
%   altitude is rejected.

    if nargin < 3 || isempty(deltaISA_C)
        deltaISA_C = 0;
    end

    validateattributes(pressureAltitude_ft, {'numeric'}, ...
        {'real', 'finite', 'scalar'}, mfilename, ...
        'pressureAltitude_ft', 1);
    validateattributes(targetPercentMCP, {'numeric'}, ...
        {'real', 'finite', 'scalar', 'positive'}, mfilename, ...
        'targetPercentMCP', 2);
    validateattributes(deltaISA_C, {'numeric'}, ...
        {'real', 'finite', 'scalar'}, mfilename, 'deltaISA_C', 3);

    data = pohCruiseData();
    altitudeGrid_ft = data.altitudeGrid_ft;
    if pressureAltitude_ft < altitudeGrid_ft(1) || ...
            pressureAltitude_ft > altitudeGrid_ft(end)
        error('pohCruiseAtPower:AltitudeOutsidePOH', ...
            ['pressureAltitude_ft must remain within the published ' ...
             'Figure 5-8 range of 2000 to 12000 ft.']);
    end
    if deltaISA_C < data.deltaISAColumns_C(1) || ...
            deltaISA_C > data.deltaISAColumns_C(end)
        error('pohCruiseAtPower:TemperatureOutsidePOH', ...
            'deltaISA_C must remain between -20 and +20 deg C.');
    end

    [minimumRPM, maximumRPM] = commonPublishedRPMRange( ...
        pressureAltitude_ft, data);
    lowerPoint = pohCruiseTableLookup( ...
        pressureAltitude_ft, minimumRPM, deltaISA_C);
    upperPoint = pohCruiseTableLookup( ...
        pressureAltitude_ft, maximumRPM, deltaISA_C);
    minimumPower_pct = lowerPoint.percentMCP;
    maximumPower_pct = upperPoint.percentMCP;
    powerTolerance_pct = 1e-10;

    if targetPercentMCP < minimumPower_pct - powerTolerance_pct || ...
            targetPercentMCP > maximumPower_pct + powerTolerance_pct
        error('pohCruiseAtPower:PowerOutsidePOH', ...
            ['%.1f%% MCP is outside the published Figure 5-8 power ' ...
             'range of %.1f%% to %.1f%% at %.0f ft and ISA %+.1f C. ' ...
             'RPM extrapolation is disabled.'], ...
            targetPercentMCP, minimumPower_pct, maximumPower_pct, ...
            pressureAltitude_ft, deltaISA_C);
    end

    if abs(targetPercentMCP - minimumPower_pct) <= powerTolerance_pct
        solvedRPM = minimumRPM;
    elseif abs(targetPercentMCP - maximumPower_pct) <= powerTolerance_pct
        solvedRPM = maximumRPM;
    else
        lowerRPM = minimumRPM;
        upperRPM = maximumRPM;
        for iteration = 1:60
            trialRPM = 0.5 * (lowerRPM + upperRPM);
            trialPoint = pohCruiseTableLookup( ...
                pressureAltitude_ft, trialRPM, deltaISA_C);
            if trialPoint.percentMCP < targetPercentMCP
                lowerRPM = trialRPM;
            else
                upperRPM = trialRPM;
            end
        end
        solvedRPM = 0.5 * (lowerRPM + upperRPM);
    end

    point = pohCruiseTableLookup( ...
        pressureAltitude_ft, solvedRPM, deltaISA_C);
    if point.percentMCP <= 75
        mixtureCondition = 'recommended lean mixture';
    else
        mixtureCondition = 'full rich (required above 75% MCP)';
    end

    setting = point;
    setting.targetPercentMCP = targetPercentMCP;
    setting.solvedRPM = solvedRPM;
    setting.powerResidual_pct = point.percentMCP - targetPercentMCP;
    setting.publishedMinimumRPM = minimumRPM;
    setting.publishedMaximumRPM = maximumRPM;
    setting.publishedMinimumPower_pct = minimumPower_pct;
    setting.publishedMaximumPower_pct = maximumPower_pct;
    setting.mixtureCondition = mixtureCondition;
    setting.classification = ...
        'POH FIGURE 5-8 INVERSION/INTERPOLATION; NO EXTRAPOLATION';
    setting.source = ...
        'C172S POH/AFM Figure 5-8 (Sheets 1 and 2)';
end

function [minimumRPM, maximumRPM] = commonPublishedRPMRange( ...
        pressureAltitude_ft, data)
%COMMONPUBLISHEDRPMRANGE Return the valid RPM interval at an altitude.

    exactTolerance_ft = 1e-9;
    exactIndex = find(abs(data.altitudeGrid_ft - ...
        pressureAltitude_ft) <= exactTolerance_ft, 1);

    if ~isempty(exactIndex)
        rpmValues = data.rpmGrid{exactIndex};
        minimumRPM = rpmValues(1);
        maximumRPM = rpmValues(end);
        return
    end

    lowerIndex = find(data.altitudeGrid_ft < ...
        pressureAltitude_ft, 1, 'last');
    upperIndex = lowerIndex + 1;
    lowerRPM = data.rpmGrid{lowerIndex};
    upperRPM = data.rpmGrid{upperIndex};
    minimumRPM = max(lowerRPM(1), upperRPM(1));
    maximumRPM = min(lowerRPM(end), upperRPM(end));
end