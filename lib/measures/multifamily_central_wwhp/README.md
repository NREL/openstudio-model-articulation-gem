

###### (Automatically generated documentation)

# Multifamily Central Waste Water Heat Pump

## Description
This measure replaces the service water heating equipment with a waste water heat pump loop and optionally top-off water heaters.

## Modeler Description
This measure uses 4 loops to model the waste water heat pump. The WW-Water Connections loop records the waste water temperature and flow rate with EMS controls. The Waste Water Heat Pump loop models the flow from the tank to the heat pump. The Service Preheat Water loop heats up the water to a target supply temperature. The Service Hot Water Loop connects to water use objects.

## Measure Type
ModelMeasure

## Taxonomy


## Arguments


### Choose the SWH type.

**Name:** swh_type,
**Type:** Choice,
**Units:** ,
**Required:** true,
**Model Dependent:** false




