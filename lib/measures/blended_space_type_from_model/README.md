

###### (Automatically generated documentation)

# Blended Space Type from Model

## Description
This measure will remove all space type assignemnts and hard assigned internal loads from spaces that are included in the building floor area. Spaces such as plenums and attics will be left alone. A blended space type will be created from the original internal loads and assigned at the building level. Thermostats, Service Water Heating, and HVAC systems will not be altered. Any constructions associated with space types will be hard assigned prior to the space type assignemnt being removed.

## Modeler Description
The goal of this measure is to create a single space type that represents the loads and schedules of a collection of space types in a model. When possible the measure will create mulitple load instances of a specific type in the resulting blended space type. This allows the original schedules to be used, and can allow for down stream EE measures on specific internal loads. Design Ventilation Outdoor Air objects will have to be merged into a single object. Will try to maintain the load design type (power, per area, per person) when possible. Need to account for zone multipliers when createding blended internal loads. Also address what happens to daylighting control objets. Original space types will be left in the model, some may still be assigned to spaces not included in the building area.

## Measure Type
ModelMeasure

## Taxonomy


## Arguments


### Blend Space Types that are part of the same

**Name:** blend_method,
**Type:** Choice,
**Units:** ,
**Required:** true,
**Model Dependent:** false




