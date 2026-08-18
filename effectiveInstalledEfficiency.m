function [etaEffective, info] = effectiveInstalledEfficiency( ...
        V_mps, rpm, density_kgpm3, model)
%EFFECTIVEINSTALLEDEFFICIENCY Evaluate the POH-calibrated closure model.
%
%   ETA = EFFECTIVEINSTALLEDEFFICIENCY(V_MPS, RPM, DENSITY_KGPM3, MODEL)
%   returns the effective installed cruise-calibration term. MODEL is the
%   output of FITEFFECTIVECRUISEMODEL.
%
%   This quantity is not isolated propeller efficiency. It combines the
%   assumed airframe drag polar, installed propulsion, and other model
%   discrepancies required to close the C172S Figure 5-8 cruise data.
%
%   Inputs must remain inside the axis-aligned calibration envelope. This
%   restriction is necessary but not sufficient to prove that an arbitrary
%   combination lies inside the full POH operating envelope.

    if nargin < 4 || isempty(model)
        model = fitEffectiveCruiseModel();
    end
    validateModel(model);

    validateattributes(V_mps, {'numeric'}, ...
        {'real', 'finite', 'positive', 'nonempty'}, ...
        mfilename, 'V_mps', 1);
    validateattributes(rpm, {'numeric'}, ...
        {'real', 'finite', 'positive', 'nonempty'}, ...
        mfilename, 'rpm', 2);
    validateattributes(density_kgpm3, {'numeric'}, ...
        {'real', 'finite', 'positive', 'nonempty'}, ...
        mfilename, 'density_kgpm3', 3);

    [V_mps, rpm, density_kgpm3] = expandScalarInputs( ...
        V_mps, rpm, density_kgpm3);
    advanceRatio = double(V_mps) ./ ...
        ((double(rpm) ./ 60) .* model.propellerDiameter_m);

    envelope = model.trainingEnvelope;
    tolerance = 1e-10;
    outside = ...
        advanceRatio < envelope.advanceRatio(1) - tolerance | ...
        advanceRatio > envelope.advanceRatio(2) + tolerance | ...
        rpm < envelope.rpm(1) - tolerance | ...
        rpm > envelope.rpm(2) + tolerance | ...
        density_kgpm3 < envelope.density_kgpm3(1) - tolerance | ...
        density_kgpm3 > envelope.density_kgpm3(2) + tolerance;
    if any(outside(:))
        firstInvalid = find(outside, 1, 'first');
        error('effectiveInstalledEfficiency:OutsideCalibrationEnvelope', ...
            ['Input point J = %.4f, RPM = %.1f, rho = %.4f kg/m^3 is ' ...
             'outside the axis-aligned POH calibration envelope. ' ...
             'Extrapolation is disabled.'], ...
            advanceRatio(firstInvalid), rpm(firstInvalid), ...
            density_kgpm3(firstInvalid));
    end

    n = model.normalization;
    xJ = advanceRatio - n.advanceRatioCenter;
    xRPM = (double(rpm) - n.rpmCenter) ./ n.rpmScale;
    xDensity = (double(density_kgpm3) - ...
        n.densityCenter_kgpm3) ./ n.densityScale_kgpm3;

    switch model.form
        case 'j-linear'
            terms = {ones(size(xJ)), xJ};
        case 'j-quadratic'
            terms = {ones(size(xJ)), xJ, xJ.^2};
        case 'j-cubic'
            terms = {ones(size(xJ)), xJ, xJ.^2, xJ.^3};
        case 'j2-rpm-density'
            terms = {ones(size(xJ)), xJ, xJ.^2, xRPM, xDensity};
        otherwise
            error('effectiveInstalledEfficiency:UnknownForm', ...
                'Unknown calibrated-model form: %s.', model.form);
    end

    etaEffective = zeros(size(xJ));
    for coefficientIndex = 1:numel(model.coefficients)
        etaEffective = etaEffective + ...
            model.coefficients(coefficientIndex) .* ...
            terms{coefficientIndex};
    end

    nonphysical = etaEffective <= 0 | etaEffective >= 1;
    if any(nonphysical(:))
        firstInvalid = find(nonphysical, 1, 'first');
        error('effectiveInstalledEfficiency:NonphysicalResult', ...
            ['The calibrated model returned eta_effective = %.4f. ' ...
             'The result is rejected rather than clipped.'], ...
            etaEffective(firstInvalid));
    end

    if nargout > 1
        info = struct( ...
            'advanceRatio', advanceRatio, ...
            'rpm', double(rpm), ...
            'density_kgpm3', double(density_kgpm3), ...
            'modelName', model.name, ...
            'classification', model.classification, ...
            'referenceConfiguration', model.referenceConfiguration, ...
            'insideAxisAlignedCalibrationEnvelope', ~outside, ...
            'identifiabilityWarning', model.identifiabilityWarning);
    end
end

function validateModel(model)
    if ~isstruct(model) || ~isscalar(model)
        error('effectiveInstalledEfficiency:InvalidModel', ...
            'model must be a scalar structure from fitEffectiveCruiseModel.');
    end
    requiredFields = { ...
        'form', 'coefficients', 'normalization', 'trainingEnvelope', ...
        'propellerDiameter_m', 'passesCalibrationGate', 'name', ...
        'classification', 'referenceConfiguration', ...
        'identifiabilityWarning'};
    for fieldIndex = 1:numel(requiredFields)
        if ~isfield(model, requiredFields{fieldIndex})
            error('effectiveInstalledEfficiency:InvalidModel', ...
                'model is missing required field: %s.', ...
                requiredFields{fieldIndex});
        end
    end
    if ~model.passesCalibrationGate
        error('effectiveInstalledEfficiency:UnapprovedModel', ...
            ['The selected effective model did not pass the grouped ' ...
             'calibration gate and cannot be evaluated.']);
    end
end

function varargout = expandScalarInputs(varargin)
%EXPANDSCALARINPUTS Expand scalars while requiring equal-sized arrays.

    arraySize = [];
    for inputIndex = 1:nargin
        if ~isscalar(varargin{inputIndex})
            if isempty(arraySize)
                arraySize = size(varargin{inputIndex});
            elseif ~isequal(size(varargin{inputIndex}), arraySize)
                error('effectiveInstalledEfficiency:SizeMismatch', ...
                    'Nonscalar inputs must have identical sizes.');
            end
        end
    end
    if isempty(arraySize)
        arraySize = [1, 1];
    end

    varargout = varargin;
    for inputIndex = 1:nargin
        if isscalar(varargout{inputIndex})
            varargout{inputIndex} = ...
                repmat(varargout{inputIndex}, arraySize);
        end
    end
end
