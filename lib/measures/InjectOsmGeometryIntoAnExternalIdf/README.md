

###### (Automatically generated documentation)

# InjectOsmGeometryIntoAnExternalIdf

## Description


## Modeler Description


## Measure Type
EnergyPlusMeasure

## Taxonomy


## Arguments


### External IDF File Name
Name of the IDF file to inject OSM geometry into. This is the filename with the extension (e.g. MyModel.idf). Optionally this can inclucde the full file path, but for most use cases should just be file name.
**Name:** source_idf_path,
**Type:** String,
**Units:** ,
**Required:** true,
**Model Dependent:** false

### Merge Geometry From OpenStudio Model into Source IDF File?
If set to false the entire external IDF will replace the initial IDF generated from the OSM file.
**Name:** merge_geometry_from_osm,
**Type:** Boolean,
**Units:** ,
**Required:** true,
**Model Dependent:** false




