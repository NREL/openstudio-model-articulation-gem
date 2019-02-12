

###### (Automatically generated documentation)

# Create Bar From Building Type Ratios

## Description
Create a core and perimeter bar sliced by space type.

## Modeler Description
Space Type collections are made from one or more building types passed in with user arguments.

## Measure Type
ModelMeasure

## Taxonomy


## Arguments


### Primary Building Type

**Name:** bldg_type_a,
**Type:** Choice,
**Units:** ,
**Required:** true,
**Model Dependent:** false

### Primary Building Type Number of Units

**Name:** bldg_type_a_num_units,
**Type:** Integer,
**Units:** ,
**Required:** true,
**Model Dependent:** false

### Building Type B

**Name:** bldg_type_b,
**Type:** Choice,
**Units:** ,
**Required:** true,
**Model Dependent:** false

### Building Type B Fraction of Building Floor Area

**Name:** bldg_type_b_fract_bldg_area,
**Type:** Double,
**Units:** ,
**Required:** true,
**Model Dependent:** false

### Building Type B Number of Units

**Name:** bldg_type_b_num_units,
**Type:** Integer,
**Units:** ,
**Required:** true,
**Model Dependent:** false

### Building Type C

**Name:** bldg_type_c,
**Type:** Choice,
**Units:** ,
**Required:** true,
**Model Dependent:** false

### Building Type C Fraction of Building Floor Area

**Name:** bldg_type_c_fract_bldg_area,
**Type:** Double,
**Units:** ,
**Required:** true,
**Model Dependent:** false

### Building Type C Number of Units

**Name:** bldg_type_c_num_units,
**Type:** Integer,
**Units:** ,
**Required:** true,
**Model Dependent:** false

### Building Type D

**Name:** bldg_type_d,
**Type:** Choice,
**Units:** ,
**Required:** true,
**Model Dependent:** false

### Building Type D Fraction of Building Floor Area

**Name:** bldg_type_d_fract_bldg_area,
**Type:** Double,
**Units:** ,
**Required:** true,
**Model Dependent:** false

### Building Type D Number of Units

**Name:** bldg_type_d_num_units,
**Type:** Integer,
**Units:** ,
**Required:** true,
**Model Dependent:** false

### Single Floor Area
Non-zero value will fix the single floor area, overriding a user entry for Total Building Floor Area
**Name:** single_floor_area,
**Type:** Double,
**Units:** ft^2,
**Required:** true,
**Model Dependent:** false

### Total Building Floor Area

**Name:** total_bldg_floor_area,
**Type:** Double,
**Units:** ft^2,
**Required:** true,
**Model Dependent:** false

### Typical Floor to FLoor Height
Selecting a typical floor height of 0 will trigger a smart building type default.
**Name:** floor_height,
**Type:** Double,
**Units:** ft,
**Required:** true,
**Model Dependent:** false

### Number of Stories Above Grade

**Name:** num_stories_above_grade,
**Type:** Double,
**Units:** ,
**Required:** true,
**Model Dependent:** false

### Number of Stories Below Grade

**Name:** num_stories_below_grade,
**Type:** Integer,
**Units:** ,
**Required:** true,
**Model Dependent:** false

### Building Rotation
Set Building Rotation off of North (positive value is clockwise).
**Name:** building_rotation,
**Type:** Double,
**Units:** Degrees,
**Required:** true,
**Model Dependent:** false

### Target Standard

**Name:** template,
**Type:** Choice,
**Units:** ,
**Required:** true,
**Model Dependent:** false

### Ratio of North/South Facade Length Relative to East/West Facade Length.
Selecting an aspect ratio of 0 will trigger a smart building type default. Aspect ratios less than one are not recommended for sliced bar geometry, instead rotate building and use a greater than 1 aspect ratio
**Name:** ns_to_ew_ratio,
**Type:** Double,
**Units:** ,
**Required:** true,
**Model Dependent:** false

### Window to Wall Ratio.
Selecting a window to wall ratio of 0 will trigger a smart building type default.
**Name:** wwr,
**Type:** Double,
**Units:** ,
**Required:** true,
**Model Dependent:** false

### Fraction of Exterior Wall Area with Adjacent Structure
This will impact how many above grade exterior walls are modeled with adiabatic boundary condition.
**Name:** party_wall_fraction,
**Type:** Double,
**Units:** ,
**Required:** true,
**Model Dependent:** false

### Number of North facing stories with party wall
This will impact how many above grade exterior north walls are modeled with adiabatic boundary condition. If this is less than the number of above grade stoes, upper flor will reamin exterior
**Name:** party_wall_stories_north,
**Type:** Integer,
**Units:** ,
**Required:** true,
**Model Dependent:** false

### Number of South facing stories with party wall
This will impact how many above grade exterior south walls are modeled with adiabatic boundary condition. If this is less than the number of above grade stoes, upper flor will reamin exterior
**Name:** party_wall_stories_south,
**Type:** Integer,
**Units:** ,
**Required:** true,
**Model Dependent:** false

### Number of East facing stories with party wall
This will impact how many above grade exterior east walls are modeled with adiabatic boundary condition. If this is less than the number of above grade stoes, upper flor will reamin exterior
**Name:** party_wall_stories_east,
**Type:** Integer,
**Units:** ,
**Required:** true,
**Model Dependent:** false

### Number of West facing stories with party wall
This will impact how many above grade exterior west walls are modeled with adiabatic boundary condition. If this is less than the number of above grade stoes, upper flor will reamin exterior
**Name:** party_wall_stories_west,
**Type:** Integer,
**Units:** ,
**Required:** true,
**Model Dependent:** false

### Is the Bottom Story Exposed to Ground?
This should be true unless you are modeling a partial building which doesn't include the lowest story. The bottom story floor will have an adiabatic boundary condition when false.
**Name:** bottom_story_ground_exposed_floor,
**Type:** Boolean,
**Units:** ,
**Required:** true,
**Model Dependent:** false

### Is the Top Story an Exterior Roof?
This should be true unless you are modeling a partial building which doesn't include the highest story. The top story ceiling will have an adiabatic boundary condition when false.
**Name:** top_story_exterior_exposed_roof,
**Type:** Boolean,
**Units:** ,
**Required:** true,
**Model Dependent:** false

### Calculation Method for Story Multiplier

**Name:** story_multiplier,
**Type:** Choice,
**Units:** ,
**Required:** true,
**Model Dependent:** false

### Division Method for Bar Space Types.

**Name:** bar_division_method,
**Type:** Choice,
**Units:** ,
**Required:** true,
**Model Dependent:** false

### Make Mid Story Floor Surfaces Adibatic
If set to true, this will skip surface intersection and make mid story floors and celings adiabiatc, not just at multiplied gaps.
**Name:** make_mid_story_surfaces_adiabatic,
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




