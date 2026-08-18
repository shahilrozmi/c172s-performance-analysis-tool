function [PA_W, info] = powerAvailable( ...
        V_mps, pressureAltitude_ft, rpm, deltaISA_C, aircraft)
%POWERAVAILABLE Calculate C172S propulsive power available.
%
%   PA_W = POWERAVAILABLE(V_MPS, PRESSUREALTITUDE_FT, RPM) calculates
%   power available at standard atmospheric temperature.
%
%   PA_W = POWERAVAILABLE(V_MPS, PRESSUREALTITUDE_FT, RPM, DELTAISA_C)
%   includes the temperature offset from ISA, in deg C.
%
%   PA_W = POWERAVAILABLE(..., AIRCRAFT) uses optional nested model data:
%       AIRCRAFT.engine     - passed to enginePowerAvailable
%       AIRCRAFT.propeller  - passed to propellerEfficiency
%
%   AIRCRAFT may also be supplied as the fourth input when DELTAISA_C is
%   omitted:
%       PA_W = POWERAVAILABLE(V_MPS, PRESSUREALTITUDE_FT, RPM, AIRCRAFT)
%
%   [PA_W, INFO] also returns engine power, propeller efficiency, advance
%   ratio, and the diagnostic structures from both component models.
%
%   Model:
%       PA = eta_prop * P_engine
%
%   Inputs may be scalars or equal-sized arrays. Scalar inputs are expanded
%   to match array inputs.
%
%   Required files:
%       enginePowerAvailable.m
%       propellerEfficiency.m

    aircraftWasFourthInput = false;

    if nargin < 4 || isempty(deltaISA_C)
        deltaISA_C = 0;
    elseif isstruct(deltaISA_C) && nargin < 5
        aircraft = deltaISA_C;
        deltaISA_C = 0;
        aircraftWasFourthInput = true;
    end

    if (nargin < 5 && ~aircraftWasFourthInput) || isempty(aircraft)
        aircraft = struct();
    end

    validateattributes(V_mps, {'numeric'}, ...
        {'real', 'finite', 'nonnegative', 'nonempty'}, ...
        mfilename, 'V_mps', 1);
    validateattributes(pressureAltitude_ft, {'numeric'}, ...
        {'real', 'finite', 'nonempty'}, ...
        mfilename, 'pressureAltitude_ft', 2);
    validateattributes(rpm, {'numeric'}, ...
        {'real', 'finite', 'positive', 'nonempty'}, ...
        mfilename, 'rpm', 3);
    validateattributes(deltaISA_C, {'numeric'}, ...
        {'real', 'finite', 'nonempty'}, ...
        mfilename, 'deltaISA_C', 4);

    if ~isstruct(aircraft) || ~isscalar(aircraft)
        error('powerAvailable:InvalidAircraft', ...
            'aircraft must be a scalar structure.');
    end

    [V_mps, pressureAltitude_ft, rpm, deltaISA_C] = ...
        expandScalarInputs( ...
            V_mps, pressureAltitude_ft, rpm, deltaISA_C);

    engine = struct();
    if isfield(aircraft, 'engine') && ~isempty(aircraft.engine)
        engine = aircraft.engine;
    end

    propeller = struct();
    if isfield(aircraft, 'propeller') && ~isempty(aircraft.propeller)
        propeller = aircraft.propeller;
    end

    [P_engine_W, engineInfo] = enginePowerAvailable( ...
        pressureAltitude_ft, rpm, deltaISA_C, engine);

    [etaProp, propellerInfo] = propellerEfficiency( ...
        V_mps, rpm, propeller);

    PA_W = etaProp .* P_engine_W;

    if nargout > 1
        info = struct( ...
            'enginePower_W', P_engine_W, ...
            'propellerEfficiency', etaProp, ...
            'advanceRatio', propellerInfo.advanceRatio, ...
            'pressureAltitude_ft', pressureAltitude_ft, ...
            'rpm', rpm, ...
            'deltaISA_C', deltaISA_C, ...
            'engine', engineInfo, ...
            'propeller', propellerInfo);
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
                error('powerAvailable:SizeMismatch', ...
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