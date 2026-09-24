# Cessna 172S Performance Analysis Tool

MATLAB application for analysing Cessna 172S aerodynamic and operational
performance. The project combines published Pilot's Operating Handbook (POH)
references, first-principles equations, and explicitly labelled semi-empirical
models. POH results remain primary whenever a published reference is available.

**Release status:** v1.0.0 — nine operating modes and **174/174 validation checks PASS**
at the frozen project checkpoint.

This is an educational and portfolio project. It is not approved for aircraft
operation, dispatch, or operational flight planning.

## Quick start

Place all project `.m` files in one folder, open that folder in MATLAB, and run:

```matlab
cd("C:\path\to\C172_Performance_Tool")
clear functions
rehash
runAllValidations
main
```

`runAllValidations` checks that MATLAB resolves every validator from the same
project folder. If a path-conflict error appears, use `which functionName -all`
to locate and move or rename the stale duplicate.

## Operating modes

| Mode | Capability | Evidence basis |
|---:|---|---|
| 1 | Aerodynamic performance sweep: stall, minimum-power and minimum-drag speeds, drag and power-required plots | Analytical; parabolic drag polar uses documented engineering assumptions |
| 2 | Cruise percent MCP, KTAS, fuel flow, configuration corrections, and semi-empirical speed comparison | POH Figure 5-8 primary; calibrated model separately labelled |
| 3 | Maximum-rate-climb speed/rate and altitude envelope | POH Figure 5-6 interpolation |
| 4 | Cruise-model accuracy audit and grouped cross-validation | POH Figure 5-8 comparison; negative proxy result retained |
| 5 | Short-field takeoff distance with grid, wind, and dry-grass treatment | POH Figure 5-5 data and published corrections |
| 6 | Short-field landing distance with grid, wind, grass, and flap treatment | POH Figure 5-11 data and published corrections |
| 7 | Climb/cruise mission fuel, range, endurance, reserve, contingency, and wind-component planning | POH Figures 5-7 and 5-8; Figures 5-9/5-10 used for cross-chart validation |
| 8 | Maximum-glide reference plus analytical best-range and minimum-sink comparisons | POH Figure 3-1 primary; assumed drag polar comparison clearly separated |
| 9 | Normal-category maneuver limits and coordinated level-turn performance | POH Section 2 limits plus analytical turn equations |

## Validation checkpoint

`runAllValidations.m` executes seven suites:

| Suite | Checks |
|---|---:|
| `runValidation` | 55/55 |
| `runEffectiveModelValidation` | 12/12 |
| `runEffectiveCruiseSpeedValidation` | 14/14 |
| `runMissionFuelValidation` | 26/26 |
| `runRangeEnduranceProfileValidation` | 15/15 |
| `runGlideDescentValidation` | 22/22 |
| `runTurnPerformanceValidation` | 30/30 |
| **Complete checkpoint** | **174/174** |

See `VALIDATION.md` for the validation scope and representative interactive
acceptance cases. Passing checks establish code/data reproduction and internal
model consistency within the stated envelopes; they do not constitute
independent flight-test validation.

## Evidence classifications

The project keeps these categories separate in code and user output:

- **POH data/table or figure interpolation:** published performance and
  limitation references evaluated only within documented source envelopes.
- **Certified configuration data:** engine, propeller, power, RPM, and geometry
  items traced to FAA type-certificate material.
- **Derived from published data:** for example, model `CLmax` derived from the
  published 53-KCAS flaps-up stall point at 2550 lb.
- **Analytical/engineering assumption:** parabolic drag-polar and coordinated-
  turn equations whose assumptions are reported explicitly.
- **Engineering proxy that fails closure:** the original `eta(J)` approximation;
  its approximately 14.02-kW RMS cruise closure error remains visible in Mode 4.
- **Semi-empirical/POH-calibrated:** combined installed-power and cruise-speed
  models. These are not isolated airframe or propeller identifications.
- **POH cross-chart reconstruction:** range/endurance profiles checked against
  digitized chart readings, not against independent flight-test measurements.

## Model basis

The aerodynamic model uses

```text
CD = CD0 + k CL^2
PR = D V
k  = 1 / (pi e AR)
```

The original uncalibrated cruise propulsion proxy uses

```text
PA = eta_prop P_engine
J  = V / (n D_prop)
```

The semi-empirical cruise-speed model solves the power balance using a combined
effective installed term calibrated to the complete 111-point POH Figure 5-8
grid. Grouped holdouts remove complete altitude, temperature, or RPM blocks.
This assesses interpolation robustness but cannot separate airframe drag from
installed propulsion losses.

Mode 9 uses the standard steady coordinated level-turn relations

```text
n      = 1 / cos(bank)
R      = VTAS^2 / (g tan(bank))
omega  = g tan(bank) / VTAS
VSturn = VS1 sqrt(n)
```

KCAS is approximated as KEAS only when density is used to derive TAS. If a
requested turn is stall-infeasible, its radius/rate/time are labelled as
mathematical requested geometry rather than sustainable performance.

## Important envelopes and limitations

- Cruise POH inputs are confined to the Figure 5-8 altitude, temperature, and
  RPM grid. Unavailable combinations are rejected rather than extrapolated.
- The semi-empirical cruise model applies only to its 2550-lb,
  speed-fairings-installed reference configuration and documented numerical
  advance-ratio guard band.
- Published reduced-weight cruise wording contains overlapping applicability
  ranges. The tool reports the overlap as unavailable instead of choosing a
  correction silently.
- Takeoff and landing calculations apply only the implemented published table
  and correction conditions. Wet/contaminated runway and runway-slope models
  are not invented.
- Mission range/endurance results use the selected reserve, contingency, wind,
  altitude, and RPM assumptions. Figure 5-7 climb distance remains zero-wind,
  and no unsupported descent-fuel credit is taken.
- POH Figure 3-1 is primary for glide range. Analytical glide comparisons use
  an assumed clean-airframe drag polar and exclude identified windmilling-
  propeller drag.
- Mode 9 is normal-category only, uses the published 1900–2550 lb VA table,
  and rejects VA extrapolation. It does not construct a gust envelope or infer
  utility-category performance.
- No public experimentally validated whole-aircraft drag polar and exact
  McCauley 1A170E/JHA7660 performance map have been identified together.

## Project files

The release contains 50 MATLAB function files. Major groups are:

- **Application/input:** `main.m`, `promptScalar.m`
- **Atmosphere/aircraft:** `isaAtmosphere.m`,
  `atmosphereAtPressureAltitude.m`, `cessna172.m`
- **Aerodynamics:** `dragPolar.m`, `dragRequired.m`, `powerRequired.m`,
  `stallSpeed.m`, `characteristicSpeeds.m`, `aerodynamicPerformance.m`
- **Cruise/propulsion:** `pohCruiseData.m`, `pohCruiseTableLookup.m`,
  `pohCruisePerformance.m`, `enginePowerAvailable.m`,
  `fitEffectiveCruiseModel.m`, `effectiveInstalledEfficiency.m`,
  `fitEffectiveCruiseSpeedModel.m`, `predictEffectiveCruiseSpeed.m`
- **Climb/mission:** `pohClimbPerformance.m`, `pohClimbFuelData.m`,
  `pohClimbFuelPerformance.m`, `pohMissionFuelPlanning.m`
- **Range/endurance:** `pohCruiseAtPower.m`,
  `pohRangeEnduranceProfileData.m`, `pohRangeEnduranceProfile.m`
- **Field performance:** `pohTakeoffData.m`, `pohTakeoffPerformance.m`,
  `pohLandingData.m`, `pohLandingPerformance.m`
- **Glide/turn:** `pohMaximumGlide.m`, `glideDescentPerformance.m`,
  `pohManeuverLimits.m`, `turnPerformance.m`
- **Validation/audit:** `runAllValidations.m` and the seven suite/audit entry
  points listed in the validation table
- **Traceability:** `REFERENCES.md`, `VALIDATION.md`

The `results/` directory contains reproducible accuracy-audit exports. Plotting
functions also write generated graphics there when their modes are run.

## Recommended MATLAB version

MATLAB R2020a or later is recommended because figure export uses
`exportgraphics`.

## Operational disclaimer

This software is not an FAA-approved source and must not replace the POH/AFM
applicable to a specific aircraft, current regulations, weather information,
pilot judgment, or approved operational planning methods.
