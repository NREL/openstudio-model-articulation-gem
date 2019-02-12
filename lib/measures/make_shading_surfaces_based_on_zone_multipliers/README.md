

###### (Automatically generated documentation)

# Make Shading Surfaces Based on Zone Multipliers

## Description
Initially this will jsut focus on Z shifting of geometry, but in future could work on x,z or y,z multiplier grids like what is use don the large hotel

## Modeler Description
Not sure how I will handle arguments. Maybe lump together all spaces on same sotry that have the same multilier value. This will have variable number of arguments basd on the model pased in. Alternative is to either only allo w one group to be chosen at at time, or allow a comlex string that describes everything. Also need to see how to define shirting. There is an offset but it may be above and below and may not be equal. In Some cases a mid floor is halfway betwen floors which makes just copying the base surfaces as shading multiple times probemeatic, since there is overlap. It coudl be nice to stretch one surface over many stories. If I check for vertial adn orthogonal surface that may work fine. 

## Measure Type
ModelMeasure

## Taxonomy


## Arguments


### Z offset distance for selcected zones.

**Name:** z_offset_dist,
**Type:** Double,
**Units:** ft,
**Required:** true,
**Model Dependent:** false

### Number of copies in the positive direction.
Should be integer no more than the multiplier - 1
**Name:** z_num_pos,
**Type:** Integer,
**Units:** ,
**Required:** true,
**Model Dependent:** false




