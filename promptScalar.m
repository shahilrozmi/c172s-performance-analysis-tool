function value = promptScalar(promptText, minimumValue, maximumValue, defaultValue)
%PROMPTSCALAR Request a finite scalar within inclusive limits.

    if nargin < 4
        defaultValue = [];
    end

    while true
        value = input(promptText);

        if isempty(value) && ~isempty(defaultValue)
            value = defaultValue;
        end

        if isnumeric(value) && isscalar(value) && isfinite(value) && ...
                value >= minimumValue && value <= maximumValue
            return
        end

        if isempty(defaultValue)
            fprintf('ERROR: Enter a value from %.3g to %.3g.\n\n', ...
                minimumValue, maximumValue);
        else
            fprintf(['ERROR: Enter a value from %.3g to %.3g, or press ' ...
                'Enter for the default.\n\n'], minimumValue, maximumValue);
        end
    end
end
