# *******************************************************************************
# OpenStudio(R), Copyright (c) Alliance for Sustainable Energy, LLC.
# See also https://openstudio.net/license
# *******************************************************************************

# Start the measure
class CreateDEERPrototypeBuilding < OpenStudio::Measure::ModelMeasure
  require 'openstudio-standards'
  require_relative 'resources/deer_building_types'
  include DEERBuildingTypes

  # Define the name of the Measure.
  def name
    return 'Create DEER Prototype Building ALPHA Version'
  end

  # Human readable description
  def description
    return 'Creates the DEER Prototype Building Models as starting points for other analyses.  This measure is a work-in-progress ALPHA version.  Some of the building types do not simulate correctly, and no attempt has yet been made to ensure that the simulation results match the DOE-2 DEER Prototypes.'
  end

  # Human readable description of modeling approach
  def modeler_description
    return ''
  end

  # Define the arguments that the user will input.
  def arguments(model)
    args = OpenStudio::Measure::OSArgumentVector.new

    # Templates
    templates = [
      'DEER Pre-1975',
      'DEER 1985',
      'DEER 1996',
      'DEER 2003',
      'DEER 2007',
      'DEER 2011',
      'DEER 2014',
      'DEER 2015',
      'DEER 2017'
    ]

    # Climate Zones
    climate_zones = [
      'CEC T24-CEC1',
      'CEC T24-CEC2',
      'CEC T24-CEC3',
      'CEC T24-CEC4',
      'CEC T24-CEC5',
      'CEC T24-CEC6',
      'CEC T24-CEC7',
      'CEC T24-CEC8',
      'CEC T24-CEC9',
      'CEC T24-CEC10',
      'CEC T24-CEC11',
      'CEC T24-CEC12',
      'CEC T24-CEC13',
      'CEC T24-CEC14',
      'CEC T24-CEC15',
      'CEC T24-CEC16'
    ]

    # Make an argument for the building type/HVAC type combo
    building_hvac_chs = OpenStudio::StringVector.new
    building_type_to_hvac_systems.each do |bldg_abrev, hvac_abrevs|
      hvac_abrevs.each do |hvac_abrev|
        building_hvac_chs << "#{building_type_to_long[bldg_abrev]}: #{hvac_sys_to_long[hvac_abrev]}"
      end
    end
    building_hvac = OpenStudio::Measure::OSArgument.makeChoiceArgument('building_hvac', building_hvac_chs, true)
    building_hvac.setDisplayName('Building Type: HVAC Type')
    building_hvac.setDefaultValue('Assembly: Split or Packaged DX Unit with Gas Furnace')
    args << building_hvac

    # Make an argument for the template
    template_chs = OpenStudio::StringVector.new
    templates.each do |template|
      template_chs << template
    end
    template = OpenStudio::Measure::OSArgument.makeChoiceArgument('template', template_chs, true)
    template.setDisplayName('Template')
    template.setDefaultValue('DEER 1985')
    args << template

    # Make an argument for the climate zone
    climate_zone_chs = OpenStudio::StringVector.new
    climate_zones.each do |climate_zone|
      climate_zone_chs << climate_zone
    end
    climate_zone = OpenStudio::Measure::OSArgument.makeChoiceArgument('climate_zone', climate_zone_chs, true)
    climate_zone.setDisplayName('Climate Zone')
    climate_zone.setDefaultValue('CEC T24-CEC1')
    args << climate_zone

    return args
  end

  # Define what happens when the measure is run.
  def run(model, runner, user_arguments)
    super(model, runner, user_arguments)

    # Use the built-in error checking
    if !runner.validateUserArguments(arguments(model), user_arguments)
      return false
    end

    # Assign the user inputs to variables that can be accessed across the measure
    building_hvac = runner.getStringArgumentValue('building_hvac', user_arguments)
    template = runner.getStringArgumentValue('template', user_arguments)
    climate_zone = runner.getStringArgumentValue('climate_zone', user_arguments)

    # Split the Building type and HVAC type
    building_type_long = building_hvac.split(':')[0].strip
    hvac_sys_long = building_hvac.split(':')[1].strip

    # Get the building and HVAC type abbreviations used by the standards gem
    building_type = building_type_to_long.find { |k, v| v == building_type_long }.first
    hvac_sys = hvac_sys_to_long.find { |k, v| v == hvac_sys_long }.first

    # Turn debugging output on/off
    debug = false

    # Make a directory to save the resulting models for debugging
    run_dir = "#{Dir.pwd}/output"
    Dir.mkdir(run_dir) unless Dir.exist?(run_dir)

    # Make a prototype creator
    reset_log
    prototype_creator = Standard.build("#{template}_#{building_type}_#{hvac_sys}")
    prototype_creator.model_create_prototype_model(climate_zone, nil, run_dir, debug, model)

    log_messages_to_runner(runner, debug)
    reset_log

    return true
  end
end

# this allows the measure to be use by the application
CreateDEERPrototypeBuilding.new.registerWithApplication
