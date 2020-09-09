

###### (Automatically generated documentation)

# AlterWeekendSchedules

## Description
This measure will alter weekend schedules to match a weekday (e.g. Monday) instead of the default DOE schedules, which are off on the weekends for schools and sometimes offices. In the future this measure could be replaced by an overall improvement in schedules used in the create_typical measure.

## Modeler Description
Initial use is to change weekend schedules in schools and large offices for SEED project to follow weekday schedules instead of being off on weekends. Measure will loop through existing schedules and use the Monday schedules for Saturday and Sunday.

## Measure Type
ModelMeasure

## Taxonomy


## Arguments


### If the building is open on the weekend
If the weekend open status is set to true the measure will run.
**Name:** weekend_open_status,
**Type:** Boolean,
**Units:** ,
**Required:** true,
**Model Dependent:** false




