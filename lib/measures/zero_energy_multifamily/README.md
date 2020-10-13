

###### (Automatically generated documentation)

# Zero Energy Multifamily

## Description
Takes a model with space and stub space types, and applies constructions, schedules, internal loads, hvac, and service water heating to match the Zero Energy Multifamily Design Guide recommendations.

## Modeler Description
This measure has optional arguments to apply recommendations from different sections of the Zero Energy Multifamily Design Guide.

## Measure Type
ModelMeasure

## Taxonomy


## Arguments


### Add Constructions to Model
The Construction Set will be applied to the entire building
**Name:** add_constructions,
**Type:** Boolean,
**Units:** ,
**Required:** true,
**Model Dependent:** false

### Construction template for adding wall and roof constructions
The constructions will be applied to the entire building
**Name:** wall_roof_construction_template,
**Type:** Choice,
**Units:** ,
**Required:** true,
**Model Dependent:** false

### Construction template for adding window constructions
The constructions will be applied to the entire building
**Name:** window_construction_template,
**Type:** Choice,
**Units:** ,
**Required:** true,
**Model Dependent:** false

### Add Space Type Loads to Model
Populate existing space types in model with internal loads.
**Name:** add_space_type_loads,
**Type:** Boolean,
**Units:** ,
**Required:** true,
**Model Dependent:** false

### Add Elevators to Model
Elevators will be add directly to space in model vs. being applied to a space type.
**Name:** add_elevators,
**Type:** Boolean,
**Units:** ,
**Required:** true,
**Model Dependent:** false

### Elevator Spaces
Comma separated names of spaces for elevator. Each space listed will have associated elevator loads.
**Name:** elev_spaces,
**Type:** String,
**Units:** ,
**Required:** true,
**Model Dependent:** false

### Elevator Type
This will impact loads, schedules, and fraction of heat lost.
**Name:** elevator_type,
**Type:** Choice,
**Units:** ,
**Required:** true,
**Model Dependent:** false

### Add Internal Mass to Model
Adds internal mass to each space.
**Name:** add_internal_mass,
**Type:** Boolean,
**Units:** ,
**Required:** true,
**Model Dependent:** false

### Add Exterior Lights to Model
Multiple exterior lights objects will be added for different classes of lighting such as parking and facade.
**Name:** add_exterior_lights,
**Type:** Boolean,
**Units:** ,
**Required:** true,
**Model Dependent:** false

### Onsite Parking Fraction
If set to 0 no exterior lighting for parking will be added
**Name:** onsite_parking_fraction,
**Type:** Double,
**Units:** ,
**Required:** true,
**Model Dependent:** false

### Add Thermostats
Add Thermostat to model based on Space Type Standards information of spaces assigned to thermal zones.
**Name:** add_thermostat,
**Type:** Boolean,
**Units:** ,
**Required:** true,
**Model Dependent:** false

### Add Service Water Heating to Model
This will add both the supply and demand side of service water heating.
**Name:** add_swh,
**Type:** Boolean,
**Units:** ,
**Required:** true,
**Model Dependent:** false

### Service Water Heating Source
The primary source of heating used by SWH systems in the model.
**Name:** swh_type,
**Type:** Choice,
**Units:** ,
**Required:** true,
**Model Dependent:** false

### Add HVAC System to Model

**Name:** add_hvac,
**Type:** Boolean,
**Units:** ,
**Required:** true,
**Model Dependent:** false

### HVAC System Type

**Name:** hvac_system_type,
**Type:** Choice,
**Units:** ,
**Required:** true,
**Model Dependent:** false




