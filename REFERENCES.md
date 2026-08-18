# References and Source Traceability

This file records the evidence hierarchy used by the Cessna 172S Performance
Analysis Tool. A citation identifies the origin of a value or method; it does
not convert an analytical assumption or calibrated model into certified data.

## Primary aircraft references

1. Cessna Aircraft Company, *Pilot's Operating Handbook and FAA Approved
   Airplane Flight Manual, Cessna Model 172S, NAV III Avionics Option with
   GFC 700 AFCS*, part number 172SPHBUS-02, Revision 2, 18 November 2010.

   Project use:

   - Section 1: fuel capacities and aircraft reference quantities
   - Figure 2-1: VA, VNO, and VNE in KCAS/KIAS
   - Section 2, pages 2-8 and 2-10: normal-category maneuver/bank and load
     factor limits
   - Figure 3-1: maximum-glide speed, configuration, and zero-wind range
   - Section 4, page 4-35: speed-fairing and approximate reduced-weight cruise
     corrections
   - Figure 5-5: short-field takeoff
   - Figure 5-6: maximum rate of climb
   - Figure 5-7: climb time, fuel, and distance
   - Figure 5-8: cruise percent MCP, KTAS, fuel flow, and operating conditions
   - Figures 5-9 and 5-10: range/endurance graphical cross-checks
   - Figure 5-11: short-field landing

   Numerical provider comments retain the specific figure, page, and revision
   identifiers used when each dataset was transcribed. Interpolation is limited
   to the documented source envelope.

2. Federal Aviation Administration, *Type Certificate Data Sheet No. 3A12*,
   Revision 80, 26 May 2010, Model 172S section.

   Project use:

   - Lycoming IO-360-L2A engine designation
   - 180 hp and 2700-RPM limits
   - McCauley 1A170E/JHA7660 propeller designation
   - 2300–2400 full-throttle static-RPM range
   - 75–76 inch propeller diameter limits

3. Federal Aviation Administration, *Type Certificate Data Sheet No. P-857*,
   McCauley fixed-pitch metal propellers.

   Project use:

   - Model-suffix convention for nominal diameter and geometric pitch at
     75-percent radius
   - Interpretation of JHA7660 as 76-inch diameter and 60-inch pitch

## Analytical and comparison references

4. Toronto Metropolitan University, AER 416 course notes:

   - Part 5: *Airfoils and Wings*
   - Part 6: *Aircraft Performance*
   - Part 7: *Aircraft Propulsion*

   Project use: aerodynamic force/power relations, parabolic drag-polar
   framework, performance-speed relations, climb/glide fundamentals, and
   advance-ratio/propulsion concepts. The coordinated-turn implementation is
   identified separately as a standard point-mass analytical model and does
   not claim POH numerical calibration.

5. Haberkorn, Thomas, *Aircraft Separation in Uncontrolled Airspace Including
   Human Factors*, Graz University of Technology dissertation, 2016,
   DOI 10.3217/cbg8a-5xc50.

   Project use: Figure A.10 comparison polar,
   `CD = 0.033 + 0.035 (CL - 0.14)^2`, used only by the cruise accuracy audit.
   It is not treated as Cessna manufacturer flight-test data.

## Function-to-source map

| Files | Source class and basis |
|---|---|
| `main.m`, `promptScalar.m` | Application/input handling; no independent performance evidence |
| `isaAtmosphere.m`, `atmosphereAtPressureAltitude.m` | Analytical standard-atmosphere relations and constants stated in code |
| `cessna172.m` | POH and FAA configuration data; `CD0` and Oswald `e` remain explicit engineering assumptions; `CLmax` is derived from the POH 53-KCAS point |
| `dragPolar.m`, `dragRequired.m`, `powerRequired.m`, `stallSpeed.m`, `characteristicSpeeds.m`, `aerodynamicPerformance.m`, `plotAerodynamicPerformance.m` | AER 416 Parts 5–6 analytical methods; assumed parabolic drag polar |
| `propellerEfficiency.m`, `powerAvailable.m` | AER 416 Part 7 engineering proxy; not an identified JHA7660 map |
| `pohCruiseData.m`, `pohCruiseTableLookup.m`, `pohCruisePerformance.m`, `enginePowerAvailable.m`, `applyPohFieldCorrections.m` | POH Figure 5-8 and published configuration corrections |
| `cruiseAccuracyAudit.m`, `runAccuracyAudit.m` | POH Figure 5-8 comparison against the assumed/proxy models; preserves failed closure |
| `fitEffectiveCruiseModel.m`, `effectiveInstalledEfficiency.m` | Combined semi-empirical installed term calibrated to 111 POH Figure 5-8 points with grouped holdouts |
| `fitEffectiveCruiseSpeedModel.m`, `predictEffectiveCruiseSpeed.m` | POH-calibrated power-balance speed inversion; not independent physics identification |
| `pohClimbPerformance.m`, `climbAltitudeSweep.m`, `plotPohClimbEnvelope.m` | POH Figure 5-6 interpolation and visualization |
| `pohTakeoffData.m`, `pohTakeoffPerformance.m` | POH Figure 5-5 data, interpolation, conservative grid, and published corrections |
| `pohLandingData.m`, `pohLandingPerformance.m` | POH Figure 5-11 data, interpolation, conservative grid, and published corrections |
| `pohClimbFuelData.m`, `pohClimbFuelPerformance.m`, `pohMissionFuelPlanning.m` | POH Figures 5-7/5-8 plus user-selected reserve, contingency, fuel, and wind policy |
| `pohCruiseAtPower.m`, `pohRangeEnduranceProfileData.m`, `pohRangeEnduranceProfile.m` | POH Figures 5-7/5-8 reconstruction compared with digitized Figures 5-9/5-10 line-center readings |
| `pohMaximumGlide.m` | POH Figure 3-1 table/figure interpolation; no unsupported wind or weight correction |
| `glideDescentPerformance.m` | Hybrid: Figure 3-1 primary plus AER 416 Part 6/assumed-drag-polar comparisons; excludes identified windmilling-propeller drag |
| `pohManeuverLimits.m` | POH Figure 2-1 and Section 2 normal-category limits; exact table values distinguished from in-table linear interpolation |
| `turnPerformance.m` | Hybrid: POH limits plus standard steady coordinated level-turn equations; KCAS approximated as KEAS only for TAS conversion |
| `runValidation.m`, `runEffectiveModelValidation.m`, `runEffectiveCruiseSpeedValidation.m`, `runMissionFuelValidation.m`, `runRangeEnduranceProfileValidation.m`, `runGlideDescentValidation.m`, `runTurnPerformanceValidation.m`, `runAllValidations.m` | Reproduction, envelope, and internal-consistency checks; not independent flight-test evidence |

## Model classifications and evidence limits

- **POH data/table value:** a published numerical entry reproduced directly.
- **POH data/interpolation:** interpolation within a published table or chart;
  input extrapolation is rejected unless an explicit published correction is
  implemented.
- **Certified configuration data:** values taken from the cited FAA type
  certificate material.
- **Derived:** a value calculated from published data and stated equations.
- **Analytical/engineering assumption:** a result produced by stated equations
  using assumed parameters, such as the conventional whole-aircraft drag polar.
- **Engineering proxy that fails closure:** the original `eta(J)` curve. Its
  approximately 14.02-kW RMS POH cruise error is retained as a visible negative
  audit result.
- **Semi-empirical/POH-calibrated:** a combined effective quantity fitted to POH
  data. It is not an isolated propeller-efficiency or airframe-drag measurement.
- **POH cross-chart reconstruction:** results built from one set of POH figures
  and compared with graphical readings from other POH figures. This tests
  consistency, not independent truth.

## Known non-identifiability and deferred scope

Public evidence available to this project does not independently identify both
the C172S whole-aircraft drag polar and the exact JHA7660 propeller performance
map. Consequently, a precise drag/propeller-efficiency split would be
non-identifiable. The project reports a combined calibrated quantity and keeps
the limitation visible in code, output, and validation.

The conventional secondary comparison (`CD0 = 0.031`, `e = 0.75`,
`AR = 7.52`) has not been traced to a primary source. It is retained only for
sensitivity testing and must not be described as validated C172S data.

The following are deliberately not inferred without additional authoritative
data: gust-envelope construction, negative-CL stall boundary, utility-category
turn performance beyond published limits, power-on descent tables,
wet/contaminated runway corrections, and runway-slope corrections.

## Frozen validation checkpoint

Run `runAllValidations.m` to reproduce the seven-suite checkpoint:

```text
55 + 12 + 14 + 26 + 15 + 22 + 30 = 174 checks
```

The POH tables are embedded as numerical data only. Consult the current POH/AFM
applicable to a specific aircraft for any operational purpose.
