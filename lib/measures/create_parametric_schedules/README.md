

###### (Automatically generated documentation)

# Create Parametric Schedules

## Description
Create parametric schedules for internal loads and HVAC availability. Replace existing schedules in model with newly generated schedules. New schedules along with hours of operation schedule will go in a building level schedule set.

## Modeler Description
This measure doesn't alter existing schedules. It only creates new schedules to replace them. Do this by creating a building level schedule set and removing all schedules from instances. HVAC schedules and thermostats will have to be applied differently.

## Measure Type
ModelMeasure

## Taxonomy


## Arguments


### Hours of Operation Start - Weekday
Energy 24 hour values with fractional values converted to minutes. e.g. 17.25 = 5:15pm.
**Name:** hoo_start_wkdy,
**Type:** Double,
**Units:** Hours,
**Required:** true,
**Model Dependent:** false

### Hours of Operation End - Weekday
If Hours of Operation End matches Hours of Operation Start it will be assumed to be 0 hours vs. 24.0
**Name:** hoo_end_wkdy,
**Type:** Double,
**Units:** Hours,
**Required:** true,
**Model Dependent:** false

### Hours of Operation Start - Saturday
Energy 24 hour values with fractional values converted to minutes. e.g. 17.25 = 5:15pm.
**Name:** hoo_start_sat,
**Type:** Double,
**Units:** Hours,
**Required:** true,
**Model Dependent:** false

### Hours of Operation End - Saturday

**Name:** hoo_end_sat,
**Type:** Double,
**Units:** Hours,
**Required:** true,
**Model Dependent:** false

### Hours of Operation Start - Sunday
Energy 24 hour values with fractional values converted to minutes. e.g. 17.25 = 5:15pm.
**Name:** hoo_start_sun,
**Type:** Double,
**Units:** Hours,
**Required:** true,
**Model Dependent:** false

### Hours of Operation End - Sunday
Energy 24 hour values with fractional values converted to minutes. e.g. 17.25 = 5:15pm.
**Name:** hoo_end_sun,
**Type:** Double,
**Units:** Hours,
**Required:** true,
**Model Dependent:** false

### Hours of Operation Per Week
If this is a non zero value it will override all of the other hours of operations inputs, however the base hours and profile shapes for weekday will be starting point to define center of day to expand/contract from.
**Name:** hoo_per_week,
**Type:** Double,
**Units:** Hours,
**Required:** true,
**Model Dependent:** false

### Comma Separated List of Valid Building Names To Alter.
This measure will only alter building names which exactly match one of the commera separted building names. Currently this check is not case sensitive. Leading or spaces from the comma separted values will be removed for comparision. An empty string will apply this to buildings of any name
**Name:** valid_building_names,
**Type:** String,
**Units:** ,
**Required:** true,
**Model Dependent:** false

### Only alter Space Types with this Standards Building Type
Pick valid Standards Building Type name. An empty string won't filter out any space types by Standards Building Type value.
**Name:** standards_building_type,
**Type:** String,
**Units:** ,
**Required:** true,
**Model Dependent:** false

### Only alter Space Types with this Standards Space Type
Pick valid Standards Space Type name. An empty string won't filter out any space types by Standards Space Type value.
**Name:** standards_space_type,
**Type:** String,
**Units:** ,
**Required:** true,
**Model Dependent:** false

### Lighting Profiles

**Name:** lighting_profiles,
**Type:** String,
**Units:** ,
**Required:** true,
**Model Dependent:** false

### Electric Equipment Profiles

**Name:** electric_equipment_profiles,
**Type:** String,
**Units:** ,
**Required:** true,
**Model Dependent:** false

### Target Electric Power Density.

**Name:** electric_equipment_value,
**Type:** Double,
**Units:** W/ft^2,
**Required:** true,
**Model Dependent:** false

### Select desired electric equipment action
Schedules and or load values from earlier arguments may be ignored depending on what is selected for this action.
**Name:** electric_equipment_action,
**Type:** Choice,
**Units:** ,
**Required:** true,
**Model Dependent:** false

### Gas Equipment Profiles

**Name:** gas_equipment_profiles,
**Type:** String,
**Units:** ,
**Required:** true,
**Model Dependent:** false

### Occupancy Profiles

**Name:** occupancy_profiles,
**Type:** String,
**Units:** ,
**Required:** true,
**Model Dependent:** false

### Infiltration Profiles

**Name:** infiltration_profiles,
**Type:** String,
**Units:** ,
**Required:** true,
**Model Dependent:** false

### Thermostat Setback Profiles

**Name:** thermostat_setback_profiles,
**Type:** String,
**Units:** ,
**Required:** true,
**Model Dependent:** false

### Heating Setpoint During Occupied Hours

**Name:** htg_setpoint,
**Type:** Double,
**Units:** F,
**Required:** true,
**Model Dependent:** false

### Cooling Setpoint During Occupied Hours

**Name:** clg_setpoint,
**Type:** Double,
**Units:** F,
**Required:** true,
**Model Dependent:** false

### Thermostat Setback Delta During Unoccupied Hours

**Name:** setback_delta,
**Type:** Double,
**Units:** F,
**Required:** true,
**Model Dependent:** false

### HVAC availability Profiles

**Name:** hvac_availability_profiles,
**Type:** String,
**Units:** ,
**Required:** true,
**Model Dependent:** false

### Service Water Heating Profiles

**Name:** swh_profiles,
**Type:** String,
**Units:** ,
**Required:** true,
**Model Dependent:** false

### Apply to un-assigned Service Water Equipment Instances.
When applying profiles to sub-set of space types in the building, setting to true will apply these profiles to water use equipment instances that are not assigned to a space.
**Name:** alter_swh_wo_space,
**Type:** Boolean,
**Units:** ,
**Required:** true,
**Model Dependent:** false

### Ramp Frequency

**Name:** ramp_frequency,
**Type:** Double,
**Units:** Hours,
**Required:** true,
**Model Dependent:** false

### Error on Out of Order Processed Profiles.
When set to false, out of order profile times trigger a warning, but the measure will attempt to reconsile the conflict by moving the problematic times.
**Name:** error_on_out_of_order,
**Type:** Boolean,
**Units:** ,
**Required:** true,
**Model Dependent:** false




