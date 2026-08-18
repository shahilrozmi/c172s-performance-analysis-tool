function cruise = pohCruisePerformance( ...
        pressureAltitude_ft, rpm, deltaISA_C, weight_lb, ...
        speedFairingsInstalled)
%POHCRUISEPERFORMANCE Return a traceable C172S POH cruise reference.
%
%   CRUISE = POHCRUISEPERFORMANCE(ALTITUDE_FT, RPM, DELTAISA_C,
%   WEIGHT_LB, SPEEDFAIRINGSINSTALLED) interpolates Figure 5-8 percent
%   MCP, KTAS, and fuel flow. Figure 5-8 is referenced to 2550 lb with
%   speed fairings installed.
%
%   Published configuration corrections:
%   - Without speed fairings, 2 KTAS is subtracted.
%   - At reduced weight, the POH states approximately +1 knot per 150 lb
%     below maximum gross weight for 55%-75% power and approximately
%     +1 knot per 125 lb below maximum for power below 65%.
%
%   Those published ranges overlap from 55% through less than 65% MCP.
%   This function does not silently choose between contradictory rules:
%   the selected-weight speed is returned as NaN in the overlap. Weight
%   correction above 75% MCP is also unavailable because it is not
%   published. The uncorrected 2550-lb Figure 5-8 reference is always
%   returned.

    if nargin < 4 || isempty(weight_lb)
        weight_lb = 2550;
    end
    if nargin < 5 || isempty(speedFairingsInstalled)
        speedFairingsInstalled = true;
    end

    validateattributes(weight_lb, {'numeric'}, ...
        {'real', 'finite', 'scalar', 'positive', '<=', 2550}, ...
        mfilename, 'weight_lb', 4);
    validateattributes(speedFairingsInstalled, {'logical', 'numeric'}, ...
        {'scalar'}, mfilename, 'speedFairingsInstalled', 5);
    if isnumeric(speedFairingsInstalled) && ...
            ~ismember(speedFairingsInstalled, [0, 1])
        error('pohCruisePerformance:InvalidFairingFlag', ...
            'speedFairingsInstalled must be true/false or 1/0.');
    end
    speedFairingsInstalled = logical(speedFairingsInstalled);

    data = pohCruiseData();
    point = pohCruiseTableLookup( ...
        pressureAltitude_ft, rpm, deltaISA_C);
    if ~isscalar(point.percentMCP)
        error('pohCruisePerformance:ScalarInputsRequired', ...
            'Interactive cruise performance requires scalar inputs.');
    end

    fairingCorrection_KTAS = 0;
    if ~speedFairingsInstalled
        fairingCorrection_KTAS = -data.noFairingSpeedDecrease_KTAS;
    end

    referenceKTAS = point.trueAirspeed_KTAS;
    fairingAdjustedReferenceKTAS = ...
        referenceKTAS + fairingCorrection_KTAS;
    weightReduction_lb = point.referenceWeight_lb - weight_lb;

    weightCorrection_KTAS = 0;
    selectedConfigurationKTAS = fairingAdjustedReferenceKTAS;
    weightCorrectionApplied = false;
    weightCorrectionAvailable = true;

    if weightReduction_lb == 0
        weightCorrectionRule = ...
            'No weight correction: selected weight equals 2550-lb POH reference.';
        weightCorrectionStatus = 'not required';
    elseif point.percentMCP < 55
        weightCorrection_KTAS = weightReduction_lb / ...
            data.reducedWeightCorrection.lowerRuleWeightPerKnot_lb;
        selectedConfigurationKTAS = fairingAdjustedReferenceKTAS + ...
            weightCorrection_KTAS;
        weightCorrectionApplied = true;
        weightCorrectionRule = ...
            '+1 KTAS per 125 lb below 2550 lb (published approximate rule below 65% MCP).';
        weightCorrectionStatus = 'applied - POH approximate correction';
    elseif point.percentMCP >= 65 && point.percentMCP <= 75
        weightCorrection_KTAS = weightReduction_lb / ...
            data.reducedWeightCorrection.upperRuleWeightPerKnot_lb;
        selectedConfigurationKTAS = fairingAdjustedReferenceKTAS + ...
            weightCorrection_KTAS;
        weightCorrectionApplied = true;
        weightCorrectionRule = ...
            '+1 KTAS per 150 lb below 2550 lb (published approximate 55%-75% rule).';
        weightCorrectionStatus = 'applied - POH approximate correction';
    elseif point.percentMCP >= 55 && point.percentMCP < 65
        weightCorrection_KTAS = NaN;
        selectedConfigurationKTAS = NaN;
        weightCorrectionAvailable = false;
        weightCorrectionRule = ...
            ['Not applied: the POH rules overlap from 55% to below 65% ' ...
             'MCP and specify different weight increments.'];
        weightCorrectionStatus = 'unavailable - contradictory published ranges';
    else
        weightCorrection_KTAS = NaN;
        selectedConfigurationKTAS = NaN;
        weightCorrectionAvailable = false;
        weightCorrectionRule = ...
            'Not applied: the POH publishes no reduced-weight correction above 75% MCP.';
        weightCorrectionStatus = 'unavailable - outside published correction';
    end

    if point.percentMCP <= 75
        mixtureCondition = 'recommended lean mixture';
    else
        mixtureCondition = 'full rich (required above 75% MCP)';
    end

    cruise = point;
    cruise.weight_lb = weight_lb;
    cruise.speedFairingsInstalled = speedFairingsInstalled;
    cruise.referenceKTAS = referenceKTAS;
    cruise.fairingCorrection_KTAS = fairingCorrection_KTAS;
    cruise.fairingAdjustedReferenceKTAS = fairingAdjustedReferenceKTAS;
    cruise.weightReduction_lb = weightReduction_lb;
    cruise.weightCorrection_KTAS = weightCorrection_KTAS;
    cruise.weightCorrectionApplied = weightCorrectionApplied;
    cruise.weightCorrectionAvailable = weightCorrectionAvailable;
    cruise.weightCorrectionRule = weightCorrectionRule;
    cruise.weightCorrectionStatus = weightCorrectionStatus;
    cruise.selectedConfigurationKTAS = selectedConfigurationKTAS;
    cruise.mixtureCondition = mixtureCondition;
    cruise.configurationNote = ...
        'Figure 5-8 base values are for 2550 lb with speed fairings installed.';
    cruise.weightCorrectionSource = ...
        data.reducedWeightCorrection.source;
end
