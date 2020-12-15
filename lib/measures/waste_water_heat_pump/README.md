

###### (Automatically generated documentation)

# Waste Water Heat Pump

## Description
This measure adds a waste water heat pump to the supply side of user selected hot water loop.  The 'Replace existing SWH loop' option creates a new service water heating loop and places all existing water use equipment onto that loop.  The delete existing tanks option allows to the user to optionally remove existing water heater tanks from a service hot water loop if not replacing it entirely.

## Modeler Description
This measure uses four loops to model the waste water heat pump. The 'WW-Water Connections Loop' records the waste water temperature and flow rate with EMS controls, the 'Waste Water Heat Pump Loop' models the flow from the tank to the heat pump, the 'Service Preheat Water Loop' heats up the water to a target supply temperature, and the 'Service Hot Water Loop' connects to water use equipment objects.
This waste water heat pump model was developed by Nick Smith and is based off of the SHARC PIRANHA unit. Performance details and modeling approach is described in the journal article by Nick Smith and Gregor Henze, 'Modelling of Wastewater Heat Recovery Heat Pump Systems', Journal of Sustainable Development of Energy, Water and Environment Systems, 9(1), 2021, available at http://dx.doi.org/10.13044/j.sdewes.d8.0330.
This work was adapted into this OpenStudio measure by Korbaga Woldekidan and Matthew Dahlhausen, and used in the development of the ASHRAE Zero Energy Multifamily Design Guide. An overview of energy performance of WWHP systems in multifamily building, including distribution loss evaluation and comparison to other water heating systems in several climate zones is available in the 2020 Building Performance Analysis Conference and Simbuild presentation, Seminar 9 Workflow and Tool Developments, 'Integrating Residential and Commercial Modeling for Zero Energy Mixed-Use Multifamily Building Design'.

## Measure Type
ModelMeasure

## Taxonomy


## Arguments


### Add WWHP to service hot water loop:

**Name:** swh_loop,
**Type:** Choice,
**Units:** ,
**Required:** false,
**Model Dependent:** false

### If adding to existing loop, delete existing tanks?:

**Name:** delete_existing_tanks,
**Type:** Boolean,
**Units:** ,
**Required:** false,
**Model Dependent:** false




