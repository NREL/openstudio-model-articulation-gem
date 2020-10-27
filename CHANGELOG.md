# OpenStudio Model Articulation Gems

## Version 0.2.1

* Updates the following in lib/measures:
    * BarAspectRationSlicedBySpaceType
    * InjectOsmGeometryIntoAnExternalIdf
    * SetWindowToWallRatioByFacade
    * SpaceTypeAndConstructionSetWizard
    * clone_building_from_external_model
    * create_DOE_prototype_building
    * create_baseline_building
    * create_deer_prototype_building
    * create_typical_building_from_model
    * create_typical_deer_building_from_model
    * create_typical_doe_building_from_model
    * merge_floorspace_js_with_model
    * merge_spaces_from_external_file
    * radiance_measure
* Adds the following to lib/measures:
    * radiant_slab_with_doas


## Version 0.2.0

* Support for OpenStudio 3.0
    * Upgrade Bundler to 2.1.x
    * Restrict to Ruby ~> 2.5.0   
    * Removed simplecov forked dependency 
* Upgraded openstudio-extension to 0.2.3
    * Updated measure tester to 0.2.0 (removes need for github gem in downstream projects)
* Upgraded openstudio-standards to 0.2.11
* Exclude measure tests from being released with the gem (reduces the size of the installed gem significantly)
* Removed dependency on openstudio-common-measures gem

## Version 0.1.1

* Update to OpenStudio Common Gem 0.1.2 (and extension gem 0.1.6)
* Merge in OpenStudio articulation measures from OpenStudio-measures
* Code cleanup on the measures
* Update copyrights and licenses 

## Version 0.1.0

* Initial release of the articulation measures that are used for generating OpenStudio models.
