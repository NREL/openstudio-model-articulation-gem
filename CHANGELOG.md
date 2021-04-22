# OpenStudio Model Articulation Gems

## Version 0.4.0

* Support Ruby ~> 2.7
* Support for OpenStudio 3.2 (upgrade to extension gem 0.4.2 and standards gem 0.2.13)
* Support for ASHRAE 90.1 2016 for DOE prototype measure
* Support for ASHRAE 90.1 216 and 2019 for measures that pull templates from extension gem. This includes but is not limited to DOE create_bar, create_typical, and space type and construction set wizard measures.

## Version 0.3.1

* Bump openstudio-extension-gem version to 0.3.2 to support updated workflow-gem

## Version 0.3.0

* Support for OpenStudio 3.1
	* Update OpenStudio Standards to 0.2.12
    * Update OpenStudio Extension gem to 0.3.1
* Move errs array creation in radiant_slab_with_doas measure
* Fix radiant measure to work with Ruby 2.2 (remove Safe Navigation operator)

## Version 0.2.1

* Support for OpenStudio 3.1
    * Update OpenStudio Standards to 0.2.12
    * Update OpenStudio Extension gem to 0.3.1
    
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
