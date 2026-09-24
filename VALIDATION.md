# Validation Record

## Frozen checkpoint

The Cessna 172S Performance Analysis Tool v1.0.0 reports the following
complete MATLAB checkpoint:

| Validation suite | Result | Principal scope |
|---|---:|---|
| `runValidation` | 55/55 | ISA, aircraft constants, aerodynamic identities, POH cruise/climb/takeoff/landing data, corrections, and error handling |
| `runEffectiveModelValidation` | 12/12 | Combined effective-power calibration, grouped holdouts, envelope guard, and classification |
| `runEffectiveCruiseSpeedValidation` | 14/14 | Cruise-speed inversion coverage/errors, grouped holdouts, envelope guard, and classification |
| `runMissionFuelValidation` | 26/26 | POH climb data, fuel capacities, mission arithmetic, wind, reserve/contingency policy, and rejection cases |
| `runRangeEnduranceProfileValidation` | 15/15 | POH Figures 5-7/5-8 reconstruction and Figures 5-9/5-10 cross-chart closure |
| `runGlideDescentValidation` | 22/22 | Figure 3-1 reproduction and analytical glide-model consistency |
| `runTurnPerformanceValidation` | 30/30 | POH maneuver limits, VA interpolation, level-turn equations, altitude/weight scaling, and envelope rejection |
| **Total** | **174/174** | **Complete project checkpoint** |

The complete result was reproduced in MATLAB from the consolidated project
folder on 18 August 2026. The master runner also verified that every validation
suite resolved from that folder rather than from a stale MATLAB-path duplicate.

## Reproduction command

From the project folder:

```matlab
clear functions
rehash
runAllValidations
```

The expected final line is:

```text
Validated project checkpoint           174/174 PASS
```

If a path conflict is reported, run `which functionName -all`, remove or move
the stale copy, then repeat `clear functions`, `rehash`, and the master runner.

## Representative interactive acceptance cases

Mode 9 received additional manual acceptance testing after the automated suite.
Values below are rounded as displayed by `main.m`.

| Case | Inputs `(PA ft, ISA °C, lb, KCAS, bank)` | Expected/result |
|---|---|---|
| Nominal level turn | `(0, 0, 2550, 95, 45°)` | PASS; `n=1.414`, accelerated stall `63.03 KCAS`, radius `799 ft`, rate `11.50°/s`, 360° time `31.3 s` |
| Accelerated-stall rejection | `(0, 0, 2550, 60, 60°)` | FAIL; accelerated stall `74.95 KCAS`, margin `-14.95 KCAS`, stall-limited bank `38.71°` |
| Altitude scaling | `(10000, 0, 2550, 95, 45°)` | PASS; density `0.9046 kg/m³`, TAS `110.55 kt`, radius `1082 ft`, rate `9.88°/s` |
| Above-VA warning | `(0, 0, 2550, 110, 45°)` | PASS for the smooth requested load; explicit full/abrupt-control warning |
| Above-VNO warning | `(0, 0, 2550, 130, 45°)` | PASS for the mathematical turn; explicit POH smooth-air caution-range warning |

The v1.0 presentation update labels radius/rate/time for an infeasible requested
turn as mathematical geometry that is not sustainable level-flight
performance.

## What the checks establish

- Exact reproduction of embedded POH grid points used by the project.
- Correct interpolation, published correction, and no-extrapolation behavior.
- Internal consistency of analytical equations and unit conversions.
- Compliance with declared input/calibration envelopes.
- Grouped holdout performance of the semi-empirical cruise models.
- Preservation of explicit POH, analytical, assumed, calibrated, and
  cross-chart classifications.

## What the checks do not establish

- Independent flight-test validation of the assumed C172S drag polar.
- An isolated McCauley JHA7660 propeller efficiency or CT/CP map.
- Independent validation of windmilling-propeller drag.
- Operational dispatch or flight-planning approval.
- A certified gust envelope, negative-CL stall boundary, or utility-category
  maneuver envelope.
- Wet/contaminated-runway, runway-slope, or other unimplemented corrections.

## Release acceptance checklist

- [x] One project root and no duplicate filenames in the submitted archive.
- [x] Every `.m` filename matches its primary MATLAB function name.
- [x] Seven-suite master manifest totals 174 checks.
- [x] All nine interactive modes are present in `main.m`.
- [x] POH and analytical results remain separately classified.
- [x] README and reference traceability match the 174-check checkpoint.
- [x] Deferred features are documented rather than silently assumed.
- [x] Re-run `runAllValidations` after installing the final changed files.

The final installation-side confirmation reproduced the complete **174/174 PASS**
checkpoint. No numerical model equations or POH datasets were changed during the
presentation/documentation update.
