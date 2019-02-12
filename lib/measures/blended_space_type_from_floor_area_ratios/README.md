

###### (Automatically generated documentation)

# Blended Space Type from Floor Area Ratios

## Description
This measure will take a string argument describing the space type ratios, for space types already in the model. There is also an argument to set the new blended space type as the default space type for the building. The space types refererenced by this argument should already exist in the model.

## Modeler Description
To determine default ratio look at the building type, and try to infer template (from building name) and set default ratios saved in the resources folder.

## Measure Type
ModelMeasure

## Taxonomy


## Arguments


### Space Type Ratio String.
'Space Type A' => ratio,'Space Type B,ratio', etc.
**Name:** space_type_ratio_string,
**Type:** String,
**Units:** ,
**Required:** true,
**Model Dependent:** false

### Set Default Space Type using Blended Space Type.

**Name:** set_default_space_type,
**Type:** Boolean,
**Units:** ,
**Required:** true,
**Model Dependent:** false




