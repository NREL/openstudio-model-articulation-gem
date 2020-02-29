

###### (Automatically generated documentation)

# Create Baseline Building

## Description
Creates the Performance Rating Method baseline building.  For 90.1, this is the Appendix G aka LEED Baseline.  For India ECBC, this is the Appendix D Baseline.  Note: for 90.1, this model CANNOT be used for code compliance; it is not the same as the Energy Cost Budget baseline.

## Modeler Description


## Measure Type
ModelMeasure

## Taxonomy


## Arguments


### Standard

**Name:** standard,
**Type:** Choice,
**Units:** ,
**Required:** true,
**Model Dependent:** false

### Building Type.

**Name:** building_type,
**Type:** Choice,
**Units:** ,
**Required:** true,
**Model Dependent:** false

### Climate Zone.

**Name:** climate_zone,
**Type:** Choice,
**Units:** ,
**Required:** true,
**Model Dependent:** false

### Customization
If selected, some of the standard process will be replaced by custom logic specific to particular programs.  If these do not apply to you, select None.
**Name:** custom,
**Type:** Choice,
**Units:** ,
**Required:** true,
**Model Dependent:** false

### Show debug messages?

**Name:** debug,
**Type:** Boolean,
**Units:** ,
**Required:** true,
**Model Dependent:** false




