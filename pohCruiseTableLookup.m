function point = pohCruiseTableLookup(pressureAltitude_ft, rpm, deltaISA_C)
%POHCRUISETABLELOOKUP Interpolate C172S POH Figure 5-8 data.
%
%   POINT = POHCRUISETABLELOOKUP(ALTITUDE_FT, RPM, DELTAISA_C) returns
%   percent maximum continuous power, true airspeed, and fuel flow from
%   C172S POH Figure 5-8. Interpolation is linear in RPM, pressure
%   altitude, and ISA temperature offset. Extrapolation is prohibited.
%
%   Inputs may be scalars or equal-sized arrays. Scalar inputs are
%   expanded to match an array input.
%
%   Output fields:
%       percentMCP       - percent maximum continuous power
%       trueAirspeed_KTAS
%       fuelFlow_GPH
%       pressureAltitude_ft, rpm, deltaISA_C
%       source, interpolationMethod

    if nargin < 3 || isempty(deltaISA_C)
        deltaISA_C = 0;
    end

    validateattributes(pressureAltitude_ft, {'numeric'}, ...
        {'real', 'finite', 'nonempty'}, mfilename, ...
        'pressureAltitude_ft', 1);
    validateattributes(rpm, {'numeric'}, ...
        {'real', 'finite', 'positive', 'nonempty'}, ...
        mfilename, 'rpm', 2);
    validateattributes(deltaISA_C, {'numeric'}, ...
        {'real', 'finite', 'nonempty'}, ...
        mfilename, 'deltaISA_C', 3);

    [pressureAltitude_ft, rpm, deltaISA_C] = expandScalarInputs( ...
        pressureAltitude_ft, rpm, deltaISA_C);

    data = pohCruiseData();

    if any(pressureAltitude_ft(:) < data.altitudeGrid_ft(1) | ...
           pressureAltitude_ft(:) > data.altitudeGrid_ft(end))
        error('pohCruiseTableLookup:AltitudeOutsidePOH', ...
            ['pressureAltitude_ft must remain within the POH cruise ' ...
             'range of 2,000 to 12,000 ft.']);
    end

    if any(deltaISA_C(:) < data.deltaISAColumns_C(1) | ...
           deltaISA_C(:) > data.deltaISAColumns_C(end))
        error('pohCruiseTableLookup:TemperatureOutsidePOH', ...
            'deltaISA_C must remain between -20 and +20 deg C.');
    end

    queryAltitude_ft = double(pressureAltitude_ft(:));
    queryRPM = double(rpm(:));
    queryDeltaISA_C = double(deltaISA_C(:));

    mcpTables = {data.mcpCold_pct, data.mcpISA_pct, data.mcpHot_pct};
    ktasTables = {data.ktasCold, data.ktasISA, data.ktasHot};
    gphTables = {data.gphCold, data.gphISA, data.gphHot};

    mcpColumns = interpolateAllTemperatureColumns( ...
        queryAltitude_ft, queryRPM, data, mcpTables);
    ktasColumns = interpolateAllTemperatureColumns( ...
        queryAltitude_ft, queryRPM, data, ktasTables);
    gphColumns = interpolateAllTemperatureColumns( ...
        queryAltitude_ft, queryRPM, data, gphTables);

    invalid = any(isnan(mcpColumns), 2) | ...
        any(isnan(ktasColumns), 2) | any(isnan(gphColumns), 2);
    if any(invalid)
        firstInvalid = find(invalid, 1, 'first');
        error('pohCruiseTableLookup:RPMOutsidePOH', ...
            ['RPM %.1f is outside the published POH cruise envelope at ' ...
             'a pressure altitude of %.1f ft. Extrapolation is disabled.'], ...
            queryRPM(firstInvalid), queryAltitude_ft(firstInvalid));
    end

    percentMCP = interpolateTemperature( ...
        queryDeltaISA_C, mcpColumns);
    trueAirspeed_KTAS = interpolateTemperature( ...
        queryDeltaISA_C, ktasColumns);
    fuelFlow_GPH = interpolateTemperature( ...
        queryDeltaISA_C, gphColumns);

    outputSize = size(pressureAltitude_ft);
    point = struct( ...
        'percentMCP', reshape(percentMCP, outputSize), ...
        'trueAirspeed_KTAS', reshape(trueAirspeed_KTAS, outputSize), ...
        'fuelFlow_GPH', reshape(fuelFlow_GPH, outputSize), ...
        'pressureAltitude_ft', pressureAltitude_ft, ...
        'rpm', rpm, ...
        'deltaISA_C', deltaISA_C, ...
        'referenceWeight_lb', data.referenceWeight_lb, ...
        'referenceSpeedFairingsInstalled', ...
            data.speedFairingsInstalled, ...
        'interpolationMethod', 'linear, no extrapolation', ...
        'source', data.source);
end

function columns = interpolateAllTemperatureColumns( ...
        queryAltitude_ft, queryRPM, data, temperatureTables)
%INTERPOLATEALLTEMPERATURECOLUMNS Return cold/ISA/hot values.

    columns = zeros(numel(queryAltitude_ft), 3);
    for temperatureIndex = 1:3
        columns(:, temperatureIndex) = interpolateAltitudeRPMPlane( ...
            queryAltitude_ft, queryRPM, data.altitudeGrid_ft, ...
            data.rpmGrid, temperatureTables{temperatureIndex});
    end
end

function value = interpolateTemperature(deltaISA_C, columns)
%INTERPOLATETEMPERATURE Interpolate cold-to-ISA or ISA-to-hot.

    value = zeros(size(deltaISA_C));
    colderThanISA = deltaISA_C <= 0;
    coldFraction = (deltaISA_C(colderThanISA) + 20) ./ 20;
    value(colderThanISA) = columns(colderThanISA, 1) + ...
        coldFraction .* (columns(colderThanISA, 2) - ...
        columns(colderThanISA, 1));

    hotterThanISA = ~colderThanISA;
    hotFraction = deltaISA_C(hotterThanISA) ./ 20;
    value(hotterThanISA) = columns(hotterThanISA, 2) + ...
        hotFraction .* (columns(hotterThanISA, 3) - ...
        columns(hotterThanISA, 2));
end

function value = interpolateAltitudeRPMPlane( ...
        queryAltitude_ft, queryRPM, altitudeGrid_ft, rpmGrid, valueGrid)
%INTERPOLATEALTITUDERPMPLANE Interpolate RPM first, then altitude.

    value = nan(size(queryAltitude_ft));
    exactTolerance_ft = 1e-9;

    for k = 1:numel(queryAltitude_ft)
        altitude = queryAltitude_ft(k);
        engineRPM = queryRPM(k);
        exactIndex = find( ...
            abs(altitudeGrid_ft - altitude) <= exactTolerance_ft, 1);

        if ~isempty(exactIndex)
            value(k) = interp1(rpmGrid{exactIndex}, ...
                valueGrid{exactIndex}, engineRPM, 'linear', NaN);
            continue
        end

        lowerIndex = find(altitudeGrid_ft < altitude, 1, 'last');
        upperIndex = lowerIndex + 1;
        lowerValue = interp1(rpmGrid{lowerIndex}, ...
            valueGrid{lowerIndex}, engineRPM, 'linear', NaN);
        upperValue = interp1(rpmGrid{upperIndex}, ...
            valueGrid{upperIndex}, engineRPM, 'linear', NaN);

        if isnan(lowerValue) || isnan(upperValue)
            continue
        end

        altitudeFraction = ...
            (altitude - altitudeGrid_ft(lowerIndex)) ./ ...
            (altitudeGrid_ft(upperIndex) - altitudeGrid_ft(lowerIndex));
        value(k) = lowerValue + ...
            altitudeFraction .* (upperValue - lowerValue);
    end
end

function varargout = expandScalarInputs(varargin)
%EXPANDSCALARINPUTS Expand scalars while requiring equal-sized arrays.

    arraySize = [];
    for k = 1:nargin
        if ~isscalar(varargin{k})
            if isempty(arraySize)
                arraySize = size(varargin{k});
            elseif ~isequal(size(varargin{k}), arraySize)
                error('pohCruiseTableLookup:SizeMismatch', ...
                    'Nonscalar inputs must have identical sizes.');
            end
        end
    end

    if isempty(arraySize)
        arraySize = [1, 1];
    end

    varargout = varargin;
    for k = 1:nargin
        if isscalar(varargout{k})
            varargout{k} = repmat(varargout{k}, arraySize);
        end
    end
end
