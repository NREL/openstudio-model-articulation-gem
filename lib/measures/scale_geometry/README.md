

###### (Automatically generated documentation)

# scale_geometry

## Description
Scales geometry in the model by fixed multiplier in the x, y, z directions.  Does not guarantee that the resulting model will be correct (e.g. not self-intersecting).  

## Modeler Description
Scales all PlanarSurfaceGroup origins and then all PlanarSurface vertices in the model. Also applies to DaylightingControls, GlareSensors, and IlluminanceMaps.

## Measure Type
ModelMeasure

## Taxonomy


## Arguments


### X Scale
Multiplier to apply to X direction.
**Name:** x_scale,
**Type:** Double,
**Units:** ,
**Required:** true,
**Model Dependent:** false

### Y Scale
Multiplier to apply to Y direction.
**Name:** y_scale,
**Type:** Double,
**Units:** ,
**Required:** true,
**Model Dependent:** false

### Z Scale
Multiplier to apply to Z direction.
**Name:** z_scale,
**Type:** Double,
**Units:** ,
**Required:** true,
**Model Dependent:** false




