

###### (Automatically generated documentation)

# Set Window to Wall Ratio by Facade

## Description


## Modeler Description


## Measure Type
ModelMeasure

## Taxonomy


## Arguments


### Window to Wall Ratio (fraction).

**Name:** wwr,
**Type:** Double,
**Units:** ,
**Required:** true,
**Model Dependent:** false




### Sill Height (in).

**Name:** sillHeight,
**Type:** Double,
**Units:** ,
**Required:** true,
**Model Dependent:** false




### Cardinal Direction.

**Name:** facade,
**Type:** Choice,
**Units:** ,
**Required:** true,
**Model Dependent:** false


**Choice Display Names** ["North", "East", "South", "West", "All"]



### Don't alter spaces that are not included in the building floor area

**Name:** exl_spaces_not_incl_fl_area,
**Type:** Boolean,
**Units:** ,
**Required:** true,
**Model Dependent:** false




### Exterior Door Logic
This will only impact exterior surfaces with specified orientation. Can do nothing, split all, or remove doors.
**Name:** split_at_doors,
**Type:** Choice,
**Units:** ,
**Required:** true,
**Model Dependent:** false


**Choice Display Names** ["Do nothing to Doors", "Split Walls at Doors", "Remove Doors"]



### Inset windows for triangular surfaces

**Name:** inset_tri_sub,
**Type:** Boolean,
**Units:** ,
**Required:** true,
**Model Dependent:** false




### Triangulate non-Rectangular surfaces
This will only impact exterior surfaces with specified orientation
**Name:** triangulate,
**Type:** Boolean,
**Units:** ,
**Required:** true,
**Model Dependent:** false







