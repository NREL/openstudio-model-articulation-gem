# *******************************************************************************
# OpenStudio(R), Copyright (c) Alliance for Sustainable Energy, LLC.
# See also https://openstudio.net/license
# *******************************************************************************

# see the URL below for information on how to write OpenStudio measures
# http://openstudio.nrel.gov/openstudio-measure-writing-guide

# see the URL below for information on using life cycle cost objects in OpenStudio
# http://openstudio.nrel.gov/openstudio-life-cycle-examples

# see the URL below for access to C++ documentation on model objects (click on "model" in the main window to view model objects)
# http://openstudio.nrel.gov/sites/openstudio.nrel.gov/files/nv_data/cpp_documentation_it/model/html/namespaces.html

# start the measure
class DEERSpaceTypeAndConstructionSetWizard < OpenStudio::Measure::ModelMeasure
  require 'openstudio-standards'

  # define the name that a user will see, this method may be deprecated as
  # the display name in PAT comes from the name field in measure.xml
  def name
    return 'DEER Space Type and Construction Set Wizard'
  end

  # human readable description
  def description
    return 'Create DEER space types and or construction sets for the requested building type, climate zone, and target.'
  end

  # human readable description of modeling approach
  def modeler_description
    return 'The data for this measure comes from the openstudio-standards Ruby Gem. They are no longer created from the same JSON file that was used to make the OpenStudio templates. Optionally this will also set the building default space type and construction set.'
  end

  # define the arguments that the user will input
  def arguments(model)
    args = OpenStudio::Measure::OSArgumentVector.new

    # Make an argument for the building type
    building_type = OpenStudio::Measure::OSArgument.makeChoiceArgument('building_type', OpenstudioStandards::CreateTypical.get_deer_building_types, true)
    building_type.setDisplayName('Building Type.')
    building_type.setDefaultValue('Asm')
    args << building_type

    # Make an argument for the template
    template = OpenStudio::Measure::OSArgument.makeChoiceArgument('template', OpenstudioStandards::CreateTypical.get_deer_templates, true)
    template.setDisplayName('Template.')
    template.setDefaultValue('DEER 2017')
    args << template

    # Make an argument for the climate zone
    climate_zone = OpenStudio::Measure::OSArgument.makeChoiceArgument('climate_zone', OpenstudioStandards::CreateTypical.get_deer_climate_zones, true)
    climate_zone.setDisplayName('Climate Zone.')
    climate_zone.setDefaultValue('CEC T24-CEC8')
    args << climate_zone

    # make an argument to add new space types
    create_space_types = OpenStudio::Measure::OSArgument.makeBoolArgument('create_space_types', true)
    create_space_types.setDisplayName('Create Space Types?')
    create_space_types.setDefaultValue(true)
    args << create_space_types

    # make an argument to add new construction set
    create_construction_set = OpenStudio::Measure::OSArgument.makeBoolArgument('create_construction_set', true)
    create_construction_set.setDisplayName('Create Construction Set?')
    create_construction_set.setDefaultValue(true)
    args << create_construction_set

    # make an argument to determine if building defaults should be set
    set_building_defaults = OpenStudio::Measure::OSArgument.makeBoolArgument('set_building_defaults', true)
    set_building_defaults.setDisplayName('Set Building Defaults Using New Objects?')
    set_building_defaults.setDefaultValue(true)
    args << set_building_defaults

    return args
  end

  # define what happens when the measure is run
  def run(model, runner, user_arguments)
    super(model, runner, user_arguments)

    # assign the user inputs to variables
    args = runner.getArgumentValues(arguments(model), user_arguments)
    args = Hash[args.collect{ |k, v| [k.to_s, v] }]
    if !args then return false end

    # run create_space_types_and_constructions
    results = OpenstudioStandards::CreateTypical.create_space_types_and_constructions(model, args['building_type'], args['template'], args['climate_zone'])

    if results == false
      return false
    else
      return true
    end
  end
end

# this allows the measure to be use by the application
DEERSpaceTypeAndConstructionSetWizard.new.registerWithApplication
