function [P_engine_W, info] = enginePowerAvailable( ...
        pressureAltitude_ft, rpm, deltaISA_C, engine)
%ENGINEPOWERAVAILABLE C172S engine brake power from POH cruise data.
%
%   P_ENGINE_W = ENGINEPOWERAVAILABLE(PRESSUREALTITUDE_FT, RPM) returns
%   engine shaft (brake) power at standard temperature.
%
%   P_ENGINE_W = ENGINEPOWERAVAILABLE(PRESSUREALTITUDE_FT, RPM,
%   DELTAISA_C) includes the temperature offset from ISA, in deg C.
%
%   P_ENGINE_W = ENGINEPOWERAVAILABLE(..., ENGINE) overrides the default
%   sea-level rated power through ENGINE.ratedPower_W.
%
%   [P_ENGINE_W, INFO] also returns the interpolated percent maximum
%   continuous power (MCP), POH KTAS, POH fuel flow, and source metadata.
%
%   Inputs may be scalars or equal-sized arrays. Interpolation and envelope
%   enforcement are centralized in pohCruiseTableLookup.m.
%
%   The output is engine brake power. Propeller efficiency must be applied
%   separately when calculating propulsive power available.

    if nargin < 3 || isempty(deltaISA_C)
        deltaISA_C = 0;
    end
    if nargin < 4 || isempty(engine)
        engine = struct();
    end

    if ~isstruct(engine) || ~isscalar(engine)
        error('enginePowerAvailable:InvalidEngine', ...
            'engine must be a scalar structure.');
    end
    if ~isfield(engine, 'ratedPower_W') || isempty(engine.ratedPower_W)
        engine.ratedPower_W = 180 * 745.6998715822702;
    end
    validateattributes(engine.ratedPower_W, {'numeric'}, ...
        {'real', 'finite', 'positive', 'scalar'}, ...
        mfilename, 'engine.ratedPower_W', 4);

    try
        point = pohCruiseTableLookup( ...
            pressureAltitude_ft, rpm, deltaISA_C);
    catch ME
        remapLookupError(ME);
    end

    P_engine_W = engine.ratedPower_W .* (point.percentMCP ./ 100);

    if nargout > 1
        % percentBHP is retained as a backward-compatible alias; the POH
        % column is formally percent maximum continuous power (MCP).
        info = point;
        info.percentBHP = point.percentMCP;
        info.ratedPower_W = engine.ratedPower_W;
        info.dataSource = point.source;
    end
end

function remapLookupError(ME)
%REMAPLOOKUPERROR Preserve the public enginePowerAvailable identifiers.

    prefix = 'pohCruiseTableLookup:';
    if startsWith(ME.identifier, prefix)
        suffix = ME.identifier((numel(prefix) + 1):end);
        error(['enginePowerAvailable:' suffix], '%s', ME.message);
    end
    rethrow(ME)
end
