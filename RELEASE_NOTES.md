# Release Notes

## v1.0.0

Public portfolio release of the Cessna 172S Performance Analysis Tool.

### Release scope

- Nine interactive operating modes
- Seven validation suites
- **174/174 validation checks PASS**
- POH-based cruise, climb, takeoff, landing, mission-fuel, range/endurance,
  glide, and maneuver/turn analyses
- Explicit separation of published POH data, certified configuration data,
  analytical assumptions, semi-empirical calibration, and cross-chart checks
- Reproducible cruise-model accuracy-audit outputs in `results/`

### Validation

Run:

```matlab
clear functions
rehash
runAllValidations
```

Expected final checkpoint:

```text
Validated project checkpoint           174/174 PASS
```

See `VALIDATION.md` for scope, limitations, and representative acceptance cases.

### Important limitation

This is an educational and portfolio analysis tool. It is not an FAA-approved
source and must not replace the POH/AFM applicable to a specific aircraft.
