

###### (Automatically generated documentation)

# Create Spaces From DXF Diagram

## Description
Use a 2d diagram from an external DXF to create spaces in OpenStudio. The number of floors and floor to floor height are exposed as arguments

## Modeler Description
This uses the OpenStudio::Model::Space::fromFloorPrint method, and is very much like the Create Spaaces From Diagram tool in the OpenStudio SketchUp plugin, but lets you draw teh diagram in the tool of your choice, and then imports it into the OpenStudio application via a measure.

## Measure Type
ModelMeasure

## Taxonomy


## Arguments


### Full path of DXF file with Diagram
This should include the path and the file name.
**Name:** dxf_path,
**Type:** String,
**Units:** ,
**Required:** true,
**Model Dependent:** false

### Floor to Floor Height

**Name:** floor_to_floor_height,
**Type:** Double,
**Units:** ft,
**Required:** true,
**Model Dependent:** false

### Number of Floors
Diagram will be stacked this many times.
**Name:** num_floors,
**Type:** Integer,
**Units:** ft,
**Required:** true,
**Model Dependent:** false

### Base Height for Lowest Diagram.
Use 0 unless you are staking multiple diagrams.
**Name:** base_height,
**Type:** Double,
**Units:** ft,
**Required:** true,
**Model Dependent:** false




