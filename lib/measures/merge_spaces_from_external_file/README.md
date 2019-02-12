

###### (Automatically generated documentation)

# Merge Spaces from External File

## Description
The measure lets you merge the contents from spaces in an external file into spaces in your current model. Spaces are identifed by the space name being the same in the two models. If a space is in the current model but not the external model they will be deleted. If a space is in both models the selecd elments willl be udpated based on the external model. If a space is not in the current model but is in the external model it will be cloned into the current model.

## Modeler Description
A string argument is used to identify the external model that is being merged into the current model. user agrument determine which kind of objets are brought over from the external model. Some characteristics that can be merged are surfaces, shading surface groups, interior partition groups, daylight controls, and internal loads. Additionally thermal zone, space space type, building story, construction set, and schedule set assignments names will can taken from the space, but objets they represent won't be cloned if objects by that name already exist in the current model.

## Measure Type
ModelMeasure

## Taxonomy


## Arguments


### External OSM File Name
Name of the model to merge into current model. This is the filename with the extension (e.g. MyModel.osm). Optionally this can inclucde the full file path, but for most use cases should just be file name.
**Name:** external_model_name,
**Type:** String,
**Units:** ,
**Required:** true,
**Model Dependent:** false

### Merge Geometry from External Model
Replace geometry in current model with geometry from external model.
**Name:** merge_geometry,
**Type:** Boolean,
**Units:** ,
**Required:** true,
**Model Dependent:** false

### Merge Internal Loads from External Model
Replace internal loads directly assigned so spaces in current model with internal loads directly assigned to spaces frp, external model. If a schedule is hard assigned to a load instance, it will be brought over as well.
**Name:** merge_loads,
**Type:** Boolean,
**Units:** ,
**Required:** true,
**Model Dependent:** false

### Merge Space Attribute names from External Model
Replace space attribute names in current model with space attribute names from external models. When external model has unkown attribute name that object will be cloned into the current model.
**Name:** merge_attribute_names,
**Type:** Boolean,
**Units:** ,
**Required:** true,
**Model Dependent:** false

### Add Spaces to Current Model
Add spaces to current model that exist in external model but do not exist in current model.
**Name:** add_spaces,
**Type:** Boolean,
**Units:** ,
**Required:** true,
**Model Dependent:** false

### Remove Spaces from Current Model
Remove spaces from current model that do not exist in externa model.
**Name:** remove_spaces,
**Type:** Boolean,
**Units:** ,
**Required:** true,
**Model Dependent:** false

### Merge Schedules from External Model
This isn't limited to spaces, this will replace any scheules in the current model with schedules of the same name in the external model. It will not replace schedule named 'a' from an internal load in th emodel with a schedule named 'b' from an internal load by that same name in the external model, to perform that task currently, you must merge loads.
**Name:** merge_schedules,
**Type:** Boolean,
**Units:** ,
**Required:** true,
**Model Dependent:** false

### Convert Merged Schedule Compact objects to Schedule Ruleset.
Will convert any imported schedules to Schedule Ruleset instead of Schedule Compact and will connect them to objects that had previously refered to the Schedule Compact object.
**Name:** compact_to_ruleset,
**Type:** Boolean,
**Units:** ,
**Required:** true,
**Model Dependent:** false




