

###### (Automatically generated documentation)

# Radiance Daylighting Measure

## Description
This measure uses Radiance instead of EnergyPlus for daylighting calculations with OpenStudio.

## Modeler Description
The OpenStudio model is converted to Radiance format. All spaces containing daylighting objects (illuminance map, daylighting control point, and optionally glare sensors) will have annual illuminance calculated using Radiance, and the OS model's lighting schedules can be overwritten with those based on daylight responsive lighting controls.

## Measure Type
ModelMeasure

## Taxonomy


## Arguments


### Apply schedules
Update lighting load schedules for Radiance-daylighting control response
**Name:** apply_schedules,
**Type:** Boolean,
**Units:** ,
**Required:** true,
**Model Dependent:** false

### Cores
Number of CPU cores to use for Radiance jobs. Default is to use all but one core, NOTE: this option is ignored on Windows.
**Name:** use_cores,
**Type:** Choice,
**Units:** ,
**Required:** true,
**Model Dependent:** false

### Radiance Settings
The measure gets the Radiance simulation parameters from the "Model" by default. "High" will force high-quality simulation paramaters, and "Testing" uses very crude parameters for a fast simulation but produces very inaccurate results.
**Name:** rad_settings,
**Type:** Choice,
**Units:** ,
**Required:** true,
**Model Dependent:** false

### Debug Mode
Generate additional log messages, images for each window group, and save all window group output.
**Name:** debug_mode,
**Type:** Boolean,
**Units:** ,
**Required:** false,
**Model Dependent:** false

### Cleanup Data
Delete Radiance input and (most) output data, post-simulation (lighting schedules are passed to OpenStudio model (and daylight metrics are passed to OpenStudio-server, if applicable)
**Name:** cleanup_data,
**Type:** Boolean,
**Units:** ,
**Required:** false,
**Model Dependent:** false




