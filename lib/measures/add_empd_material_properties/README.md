

###### (Automatically generated documentation)

# Add EMPD Material Properties

## Description
Adds the properties for the effective moisture penetration depth (EMPD) Heat Balance Model with inputs for penetration depths.

## Modeler Description
Adds the properties for the MoisturePenetrationDepthConductionTransferFunction or effective moisture penetration depth (EMPD) Heat Balance Model with inputs for penetration depths. 

 Leaving Change heat balance algorithm? blank will use the current OpenStudio heat balance algorithm setting. 

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

**Name:** water_diff_fact,
**Type:** Double,
**Units:** ,
**Required:** true,
**Model Dependent:** false

### Set value for Moisture Equation Coefficient A

**Name:** coef_a,
**Type:** Double,
**Units:** ,
**Required:** true,
**Model Dependent:** false

### Set value for Moisture Equation Coefficient B

**Name:** coef_b,
**Type:** Double,
**Units:** ,
**Required:** true,
**Model Dependent:** false

### Set value for Moisture Equation Coefficient C

**Name:** coef_c,
**Type:** Double,
**Units:** ,
**Required:** true,
**Model Dependent:** false

### Set value for Moisture Equation Coefficient D

**Name:** coef_d,
**Type:** Double,
**Units:** ,
**Required:** true,
**Model Dependent:** false

### Set value for Surface Layer Penetration Depth

**Name:** surface_penetration,
**Type:** String,
**Units:** ,
**Required:** true,
**Model Dependent:** false

### Set value for Deep Layer Penetration Depth

**Name:** deep_penetration,
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

**Name:** coating_res,
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




