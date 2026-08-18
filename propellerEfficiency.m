function [etaProp, info] = propellerEfficiency(V_mps, rpm, propeller)
%PROPELLEREFFICIENCY Estimate C172S fixed-pitch propeller efficiency.
%
%   ETA = PROPELLEREFFICIENCY(V_MPS, RPM) returns propeller efficiency for
%   the Cessna 172S two-blade, 76-inch fixed-pitch propeller.
%
%   ETA = PROPELLEREFFICIENCY(V_MPS, RPM, PROPELLER) overrides the default
%   propeller data. Supported fields are:
%       diameter_m        - propeller diameter [m]
%       advanceRatioData  - advance-ratio breakpoints
%       efficiencyData    - efficiency at each breakpoint
%       interpolation     - 'pchip' (default) or 'linear'
%       modelName         - descriptive model name
%
%   [ETA, INFO] also returns advance ratio and model information.
%
%   Inputs may be scalars or equal-sized arrays. A scalar is expanded to
%   match an array input.
%
%   Model:
%       n   = RPM / 60
%       J   = V / (n D)
%       eta = eta(J)
%
%   The default eta(J) curve is a smooth engineering approximation based
%   on the two-blade fixed-pitch propeller trends in AER 416 Part 7. Its
%   assumed peak is J = 0.74 and eta = 0.85, in the operating region of the
%   C172S POH cruise points. It is not a manufacturer performance map for
%   the McCauley 1A170E/JHA7660.
%
%   Only propeller diameter enters this advance-ratio proxy. The certified
%   60-inch pitch designation and any blade chord, twist, root-cutout, or
%   airfoil geometry are not used. This function is therefore not BEMT.
%
%   Efficiency is defined as useful propulsive power divided by engine
%   shaft power. Therefore eta = 0 at zero airspeed even though the
%   propeller can still produce static thrust.

    if nargin < 3 || isempty(propeller)
        propeller = struct();
    end

    validateattributes(V_mps, {'numeric'}, ...
        {'real', 'finite', 'nonnegative', 'nonempty'}, ...
        mfilename, 'V_mps', 1);
    validateattributes(rpm, {'numeric'}, ...
        {'real', 'finite', 'positive', 'nonempty'}, ...
        mfilename, 'rpm', 2);

    if ~isstruct(propeller) || ~isscalar(propeller)
        error('propellerEfficiency:InvalidPropeller', ...
            'propeller must be a scalar structure.');
    end

    propeller = setDefault(propeller, 'diameter_m', 76 * 0.0254);
    propeller = setDefault(propeller, 'advanceRatioData', ...
        [0.00, 0.10, 0.20, 0.30, 0.40, 0.50, 0.60, ...
         0.68, 0.74, 0.80, 0.86, 0.92, 0.98, 1.04]);
    propeller = setDefault(propeller, 'efficiencyData', ...
        [0.00, 0.18, 0.36, 0.52, 0.65, 0.75, 0.82, ...
         0.845, 0.85, 0.84, 0.79, 0.66, 0.38, 0.00]);
    propeller = setDefault(propeller, 'interpolation', 'pchip');
    propeller = setDefault(propeller, 'modelName', ...
        'C172S fixed-pitch engineering proxy');

    propeller = validatePropellerData(propeller);
    [V_mps, rpm] = expandScalarInputs(V_mps, rpm);

    advanceRatio = double(V_mps) ./ ...
        ((double(rpm) ./ 60) .* propeller.diameter_m);

    minimumJ = propeller.advanceRatioData(1);
    maximumJ = propeller.advanceRatioData(end);
    outsideModel = advanceRatio < minimumJ | advanceRatio > maximumJ;

    if any(outsideModel(:))
        firstInvalid = find(outsideModel, 1, 'first');
        error('propellerEfficiency:AdvanceRatioOutsideModel', ...
            ['Advance ratio J = %.3f is outside the model range of ' ...
             '%.2f to %.2f. Extrapolation is disabled.'], ...
            advanceRatio(firstInvalid), minimumJ, maximumJ);
    end

    etaProp = interp1( ...
        propeller.advanceRatioData, ...
        propeller.efficiencyData, ...
        advanceRatio, ...
        propeller.interpolation);

    % Guard against tiny interpolation overshoots and round-off.
    etaProp = min(1, max(0, etaProp));

    if nargout > 1
        [etaPeak, peakIndex] = max(propeller.efficiencyData);
        info = struct( ...
            'advanceRatio', advanceRatio, ...
            'diameter_m', propeller.diameter_m, ...
            'rotationRate_rps', double(rpm) ./ 60, ...
            'modelName', propeller.modelName, ...
            'interpolation', propeller.interpolation, ...
            'peakAdvanceRatio', ...
                propeller.advanceRatioData(peakIndex), ...
            'peakEfficiency', etaPeak, ...
            'validAdvanceRatio', [minimumJ, maximumJ]);
    end
end

function propeller = setDefault(propeller, fieldName, defaultValue)
%SETDEFAULT Add a field only when the caller did not supply it.
    if ~isfield(propeller, fieldName) || isempty(propeller.(fieldName))
        propeller.(fieldName) = defaultValue;
    end
end

function propeller = validatePropellerData(propeller)
%VALIDATEPROPELLERDATA Validate geometry, curve data, and interpolation.
    validateattributes(propeller.diameter_m, {'numeric'}, ...
        {'real', 'finite', 'positive', 'scalar'}, ...
        mfilename, 'propeller.diameter_m', 3);
    validateattributes(propeller.advanceRatioData, {'numeric'}, ...
        {'real', 'finite', 'nonnegative', 'vector', 'nonempty'}, ...
        mfilename, 'propeller.advanceRatioData', 3);
    validateattributes(propeller.efficiencyData, {'numeric'}, ...
        {'real', 'finite', '>=', 0, '<=', 1, 'vector', 'nonempty'}, ...
        mfilename, 'propeller.efficiencyData', 3);

    if numel(propeller.advanceRatioData) ~= ...
            numel(propeller.efficiencyData)
        error('propellerEfficiency:CurveSizeMismatch', ...
            ['propeller.advanceRatioData and propeller.efficiencyData ' ...
             'must contain the same number of elements.']);
    end

    if numel(propeller.advanceRatioData) < 2 || ...
            any(diff(propeller.advanceRatioData) <= 0)
        error('propellerEfficiency:InvalidAdvanceRatioData', ...
            ['propeller.advanceRatioData must contain at least two ' ...
             'strictly increasing values.']);
    end

    if ~(ischar(propeller.interpolation) || ...
            (isstring(propeller.interpolation) && isscalar(propeller.interpolation)))
        error('propellerEfficiency:InvalidInterpolation', ...
            'propeller.interpolation must be ''pchip'' or ''linear''.');
    end

    interpolation = char(propeller.interpolation);
    if ~any(strcmp(interpolation, {'pchip', 'linear'}))
        error('propellerEfficiency:InvalidInterpolation', ...
            'propeller.interpolation must be ''pchip'' or ''linear''.');
    end
    propeller.interpolation = interpolation;

    if ~(ischar(propeller.modelName) || ...
            (isstring(propeller.modelName) && isscalar(propeller.modelName)))
        error('propellerEfficiency:InvalidModelName', ...
            'propeller.modelName must be text.');
    end

    propeller.advanceRatioData = ...
        double(propeller.advanceRatioData(:).');
    propeller.efficiencyData = ...
        double(propeller.efficiencyData(:).');
    propeller.modelName = char(propeller.modelName);
end

function [first, second] = expandScalarInputs(first, second)
%EXPANDSCALARINPUTS Expand a scalar while requiring equal-sized arrays.
    if isscalar(first) && ~isscalar(second)
        first = repmat(first, size(second));
    elseif ~isscalar(first) && isscalar(second)
        second = repmat(second, size(first));
    elseif ~isequal(size(first), size(second))
        error('propellerEfficiency:SizeMismatch', ...
            'V_mps and rpm must be scalars or equal-sized arrays.');
    end
end
