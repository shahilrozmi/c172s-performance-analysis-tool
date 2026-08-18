function data = pohClimbFuelData()
%POHCLIMBFUELDATA Digitized C172S POH Figure 5-7 climb data.
%
%   DATA = POHCLIMBFUELDATA() returns the published standard-temperature
%   time, fuel, and zero-wind distance accumulated from sea level during a
%   normal climb at 2550 lb.
%
%   Conditions:
%       Weight        2550 lb
%       Flaps         UP
%       Power         Full throttle
%       Temperature   Standard
%       Mixture       Leaned above 3000 ft for maximum RPM
%
%   Source:
%       Cessna Model 172S POH/AFM 172SPHBUS-02, Figure 5-7.

    data.source = 'C172S POH/AFM 172SPHBUS-02, Figure 5-7';
    data.referenceWeight_lb = 2550;
    data.configuration = 'Flaps UP, full throttle';
    data.mixtureCondition = ...
        'lean above 3000 ft pressure altitude for maximum RPM';
    data.startTaxiTakeoffAllowance_USgal = 1.4;
    data.hotDayCorrectionPer10C = 0.10;
    data.distanceWindCondition = 'zero wind';

    data.pressureAltitude_ft = 0:1000:12000;
    data.standardTemperature_C = ...
        [15, 13, 11, 9, 7, 5, 3, 1, -1, -3, -5, -7, -9];
    data.climbSpeed_KIAS = ...
        [74, 73, 73, 73, 73, 73, 73, 73, 72, 72, 72, 72, 72];
    data.rateOfClimb_fpm = ...
        [730, 695, 655, 620, 600, 550, 505, 455, 410, 360, 315, 265, 220];
    data.timeFromSeaLevel_min = ...
        [0, 1, 3, 4, 6, 8, 10, 12, 14, 17, 20, 24, 28];
    data.fuelFromSeaLevel_USgal = ...
        [0.0, 0.4, 0.8, 1.2, 1.5, 1.9, 2.2, 2.6, 3.0, 3.4, 3.9, 4.4, 5.0];
    data.distanceFromSeaLevel_nm = ...
        [0, 2, 4, 6, 8, 10, 13, 16, 19, 22, 27, 32, 38];
end
