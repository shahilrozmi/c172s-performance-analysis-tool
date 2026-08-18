function aircraft = cessna172()
%CESSNA172 Return the data used by the Cessna 172S performance model.
%
%   AIRCRAFT = CESSNA172() returns geometry, weight, aerodynamic, engine,
%   propeller, and model-limit data in SI units unless stated otherwise.

    LBF_TO_N = 4.4482216152605;
    HP_TO_W = 745.6998715822702;
    KT_TO_MPS = 0.514444;
    IN_TO_M = 0.0254;
    RHO0 = 1.2250;

    aircraft.name = "Cessna 172S Skyhawk";

    % Geometry
    aircraft.S = 16.2;                  % Wing area (m^2)
    aircraft.b = 11.0;                  % Wingspan (m)
    aircraft.AR = aircraft.b^2 / aircraft.S;

    % Weight. The default is maximum takeoff weight so the aerodynamic and
    % climb results are directly comparable with the POH performance tables.
    aircraft.maxGrossWeight_lb = 2550;
    aircraft.maxGrossWeight_N = ...
        aircraft.maxGrossWeight_lb * LBF_TO_N;
    aircraft.W = aircraft.maxGrossWeight_N;

    % Aerodynamics. CD0 and e remain explicit engineering assumptions
    % pending independent drag-polar validation. CLmax is derived so that
    % the model reproduces the POH flaps-up, power-idle stall speed of
    % 53 KCAS at 2550 lb under sea-level standard conditions.
    aircraft.CD0 = 0.027;
    aircraft.e = 0.80;
    aircraft.referenceStallSpeedFlapsUp_KCAS = 53;
    referenceStallSpeed_mps = ...
        aircraft.referenceStallSpeedFlapsUp_KCAS * KT_TO_MPS;
    aircraft.CLmax = 2 * aircraft.maxGrossWeight_N / ...
        (RHO0 * aircraft.S * referenceStallSpeed_mps^2);
    aircraft.aerodynamicParameterStatus = struct( ...
        'CD0', 'engineering assumption; accuracy audit required', ...
        'e', 'engineering assumption; accuracy audit required', ...
        'CLmax', 'derived from POH 53 KCAS flaps-up stall speed');

    % Engine
    aircraft.engineManufacturer = "Lycoming";
    aircraft.engineModel = "IO-360-L2A";
    aircraft.engineRPMmax = 2700;
    aircraft.enginePowerSL = 180 * HP_TO_W;
    aircraft.engine = struct( ...
        'ratedPower_W', aircraft.enginePowerSL);

    % Propeller
    aircraft.propManufacturer = "McCauley";
    aircraft.propModel = "McCauley 1A170E/JHA7660";
    aircraft.propType = "fixed-pitch";
    aircraft.propBlades = 2;
    aircraft.propDiameter = 76 * IN_TO_M;
    aircraft.propMinimumDiameter = 75 * IN_TO_M;
    aircraft.propPitchAt75Radius = 60 * IN_TO_M;
    aircraft.propRPMstaticRange = [2300, 2400];
    % Retained for backward compatibility; this is the midpoint of the
    % certified range, not a separately certified exact static RPM.
    aircraft.propRPMstatic = mean(aircraft.propRPMstaticRange);
    aircraft.propeller = struct( ...
        'diameter_m', aircraft.propDiameter, ...
        'minimumDiameter_m', aircraft.propMinimumDiameter, ...
        'pitchAt75Radius_m', aircraft.propPitchAt75Radius, ...
        'staticRPMRange', aircraft.propRPMstaticRange, ...
        'certifiedModelName', char(aircraft.propModel), ...
        'modelName', 'C172S fixed-pitch engineering proxy');

    aircraft.certificationSource = ...
        'FAA TCDS 3A12 Rev. 80, Model 172S';

    % Fuel capacity. These are published POH quantities; performance and
    % planning calculations use usable fuel, not total tank capacity.
    aircraft.fuelTotal_USgal = 56.0;
    aircraft.fuelUsable_USgal = 53.0;
    aircraft.fuelTotalEachTank_USgal = 28.0;
    aircraft.fuelUsableEachTank_USgal = 26.5;
    aircraft.fuelCapacitySource = ...
        'C172S POH/AFM 172SPHBUS-02, Section 1';

    % Data/model limits
    aircraft.pohMaximumAltitude_ft = 12000;
    aircraft.aeroSweepMaximumSpeed_mps = 150 * KT_TO_MPS;
end
