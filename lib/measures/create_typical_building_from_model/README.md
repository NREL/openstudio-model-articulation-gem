

###### (Automatically generated documentation)

# Create Typical Building from Model

## Description
Takes a model with space and stub space types, and assigns constructions, schedules, internal loads, hvac, and other loads such as exterior lights and service water heating. The end result is somewhat like a custom protptye model with user geometry, but it may use different HVAC systems.

## Modeler Description
Initially this was intended for stub space types, but it is possible that it will be run on models tha talready have internal loads, schedules, or constructions that should be preserved. Set it up to support addition at later date of bool args to skip specific types of model elements.

## Measure Type
ModelMeasure

## Taxonomy


## Arguments


### Target Standard

**Name:** template,
**Type:** Choice,
**Units:** ,
**Required:** true,
**Model Dependent:** false

### HVAC System Type

**Name:** system_type,
**Type:** Choice,
**Units:** ,
**Required:** true,
**Model Dependent:** false

### HVAC System Delivery Type
How the HVAC system delivers heating or cooling to the zone.
**Name:** hvac_delivery_type,
**Type:** Choice,
**Units:** ,
**Required:** true,
**Model Dependent:** false

### HVAC Heating Source
The primary source of heating used by HVAC systems in the model.
**Name:** htg_src,
**Type:** Choice,
**Units:** ,
**Required:** true,
**Model Dependent:** false

### HVAC Cooling Source
The primary source of cooling used by HVAC systems in the model.
**Name:** clg_src,
**Type:** Choice,
**Units:** ,
**Required:** true,
**Model Dependent:** false

### Kitchen Exhaust MakeUp Air Calculation Method
Determine logic to identify dining or cafe zones to provide makeup air to kitchen exhaust.
**Name:** kitchen_makeup,
**Type:** Choice,
**Units:** ,
**Required:** true,
**Model Dependent:** false

### Exterior Lighting Zone
Identify the Exterior Lighitng Zone for the Building Site.
**Name:** exterior_lighting_zone,
**Type:** Choice,
**Units:** ,
**Required:** true,
**Model Dependent:** false

### Add Constructions to Model
Construction Set will be appied to entire building
**Name:** add_constructions,
**Type:** Boolean,
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

### Add Exhaust Fans to Model
Depending upon building type exhaust fans can be in kitchens, restrooms or other space types
**Name:** add_exhaust,
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

### Add Thermostats
Add Thermost to model based on Space Type Standards information of spaces assigned to thermal zones.
**Name:** add_thermostat,
**Type:** Boolean,
**Units:** ,
**Required:** true,
**Model Dependent:** false

### Add HVAC System to Model
Add HVAC System and thermostats to model
**Name:** add_hvac,
**Type:** Boolean,
**Units:** ,
**Required:** true,
**Model Dependent:** false

### Clean Model of non-gemoetry objects
Only removes objects of type that are selected to be added.
**Name:** remove_objects,
**Type:** Boolean,
**Units:** ,
**Required:** true,
**Model Dependent:** false

### Use Upstream Argument Values
When true this will look for arguments or registerValues in upstream measures that match arguments from this measure, and will use the value from the upstream measure in place of what is entered for this measure.
**Name:** use_upstream_args,
**Type:** Boolean,
**Units:** ,
**Required:** true,
**Model Dependent:** false

### Enable Daylight Savings.
By default this will force dayligint savsings to be enabled. Set to false if in a location where DST is not followed, or if needed for specific use case.
**Name:** enable_dst,
**Type:** Boolean,
**Units:** ,
**Required:** true,
**Model Dependent:** false




