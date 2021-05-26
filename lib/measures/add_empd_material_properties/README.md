

###### (Automatically generated documentation)

# Add EMPD Material Properties

## Description
Adds the properties for the effective moisture penetration depth (EMPD) Heat Balance Model with inputs for penetration depths.

## Modeler Description
Adds the properties for the "MoisturePenetrationDepthConductionTransferFunction" or effective moisture penetration depth (EMPD) Heat Balance Model with inputs for penetration depths. 

 Leaving "Change heat balance algorithm?" blank will use the current OpenStudio heat balance algorithm setting. 

 At least 1 interior material needs to have moisture penetration depth properties set to use the EMPD heat balance algorithm.

## Measure Type
ModelMeasure

## Taxonomy


## Arguments


### Select Material

**Name:** selected_material,
**Type:** Choice,
**Units:** ,
**Required:** true,
**Model Dependent:** true

### Set value for Water Vapor Diffusion Resistance Factor

**Name:** waterDiffFact,
**Type:** Double,
**Units:** ,
**Required:** true,
**Model Dependent:** false

### Set value for Moisture Equation Coefficient A

**Name:** coefA,
**Type:** Double,
**Units:** ,
**Required:** true,
**Model Dependent:** false

### Set value for Moisture Equation Coefficient B

**Name:** coefB,
**Type:** Double,
**Units:** ,
**Required:** true,
**Model Dependent:** false

### Set value for Moisture Equation Coefficient C

**Name:** coefC,
**Type:** Double,
**Units:** ,
**Required:** true,
**Model Dependent:** false

### Set value for Moisture Equation Coefficient D

**Name:** coefD,
**Type:** Double,
**Units:** ,
**Required:** true,
**Model Dependent:** false

### Set value for Surface Layer Penetration Depth

**Name:** surfacePenetration,
**Type:** String,
**Units:** ,
**Required:** true,
**Model Dependent:** false

### Set value for Deep Layer Penetration Depth

**Name:** deepPenetration,
**Type:** String,
**Units:** ,
**Required:** false,
**Model Dependent:** false

### Set value for Coating Layer Thickness

**Name:** coating,
**Type:** Double,
**Units:** ,
**Required:** true,
**Model Dependent:** false

### Set value for Coating Layer Resistance Factor

**Name:** coatingRes,
**Type:** Double,
**Units:** ,
**Required:** true,
**Model Dependent:** false

### Change heat balance algorithm?

**Name:** algorithm,
**Type:** Choice,
**Units:** ,
**Required:** false,
**Model Dependent:** false




