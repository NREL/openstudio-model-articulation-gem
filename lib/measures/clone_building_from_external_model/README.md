

###### (Automatically generated documentation)

# Clone Building From External Model

## Description
This measures clones the building in from an external model in place of the existing building in a model. In addition to changing the feilds in the building object itself, it will bring in meters, building story objects, shading surface groups, thermal zones, and spaces. This includes their children. Currently this doesn't included HVAC systems, site lighitng.

## Modeler Description
The intent of this measure is to provide a measure is to provide a way in a single analysis to use a collection of custom seed models. Your real seed model woudl be an empty model, maybe containing custom weather data and simulation settings, then you would have a variety of models with pre-generated builiding envelopes to choose from. They custom seeds coudl jsut have surraes, or could contain constructions, schedules, and loads.

## Measure Type
ModelMeasure

## Taxonomy


## Arguments


### External OSM File Name
Name of the model to clone building from. This is the filename with the extension (e.g. MyModel.osm). Optionally this can inclucde the full file path, but for most use cases should just be file name.
**Name:** external_model_name,
**Type:** String,
**Units:** ,
**Required:** true,
**Model Dependent:** false




