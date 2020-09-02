

###### (Automatically generated documentation)

# Alter DOE School Summer Vacation

## Description
This measure will alter seasonal components of schedules that already have rules in place for seasonal adjustments.  Initially it just shortens summery vacation, but could be updated to lengthen it. Can be generalized in future to measure named Shift Existing Seasonal Schedule Rules.

## Modeler Description
Initial use is to change summer vacations in primary and secondary school. Primary input will be number of months long the school year is. This is meant to be used on DOE prototype schedules which represent a 10 month school year. 11 or 12 month input will shorten or remove the summer break. Shortening from the end of the break leaving the beginning un-touched. If this measure is run on unexpected models it will not have the desired impact.

## Measure Type
ModelMeasure

## Taxonomy


## Arguments


### Number of Months per Year School is in Session
This name will be used as the name of the new space.
**Name:** months_school,
**Type:** Double,
**Units:** ,
**Required:** true,
**Model Dependent:** false




