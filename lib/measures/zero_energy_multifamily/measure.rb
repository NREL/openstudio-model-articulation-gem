# *******************************************************************************
# OpenStudio(R), Copyright (c) 2008-2019, Alliance for Sustainable Energy, LLC.
# All rights reserved.
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are met:
#
# (1) Redistributions of source code must retain the above copyright notice,
# this list of conditions and the following disclaimer.
#
# (2) Redistributions in binary form must reproduce the above copyright notice,
# this list of conditions and the following disclaimer in the documentation
# and/or other materials provided with the distribution.
#
# (3) Neither the name of the copyright holder nor the names of any contributors
# may be used to endorse or promote products derived from this software without
# specific prior written permission from the respective party.
#
# (4) Other than as required in clauses (1) and (2), distributions in any form
# of modifications or other derivative works may not use the "OpenStudio"
# trademark, "OS", "os", or any other confusingly similar designation without
# specific prior written permission from Alliance for Sustainable Energy, LLC.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDER(S) AND ANY CONTRIBUTORS
# "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO,
# THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
# ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER(S), ANY CONTRIBUTORS, THE
# UNITED STATES GOVERNMENT, OR THE UNITED STATES DEPARTMENT OF ENERGY, NOR ANY OF
# THEIR EMPLOYEES, BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
# EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT
# OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
# INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT,
# STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY
# OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
# *******************************************************************************

# see the URL below for information on how to write OpenStudio measures
# http://nrel.github.io/OpenStudio-user-documentation/reference/measure_writing_guide/

# start the measure
class ZeroEnergyMultifamily < OpenStudio::Measure::ModelMeasure

require 'openstudio-standards'

# load OpenStudio measure libraries from openstudio-extension gem
  require 'openstudio-extension'
  require 'openstudio/extension/core/os_lib_helper_methods.rb'

  # resource file modules
  include OsLib_HelperMethods

  # human readable name
  def name
    return 'Zero Energy Multifamily'
  end

  # human readable description
  def description
    return 'Takes a model with space and stub space types, and applies constructions, schedules, internal loads, hvac, and service water heating to match the Zero Energy Multifamily Design Guide recommendations.'
  end

  # human readable description of modeling approach
  def modeler_description
    return 'This measure has optional arguments to apply recommendations from different sections of the Zero Energy Multifamily Design Guide.'
  end

  def zero_energy_multifamily_add_hvac(model, runner, standard, system_type, zones)
    heated_and_cooled_zones = zones.select { |zone| standard.thermal_zone_heated?(zone) && standard.thermal_zone_cooled?(zone) }
    heated_zones = zones.select { |zone| standard.thermal_zone_heated?(zone) }
    cooled_zones = zones.select { |zone| standard.thermal_zone_cooled?(zone) }
    cooled_only_zones = zones.select { |zone| !standard.thermal_zone_heated?(zone) && standard.thermal_zone_cooled?(zone) }
    heated_only_zones = zones.select { |zone| standard.thermal_zone_heated?(zone) && !standard.thermal_zone_cooled?(zone) }
    system_zones = heated_and_cooled_zones + cooled_only_zones

    # ventilation systems added first so that the most controllable equipment is last in zone priority
    case system_type
    when 'Minisplit Heat Pumps with DOAS'
      standard.model_add_hvac_system(model, 'DOAS', 'Electricity', nil, 'Electricity', system_zones,
                                     air_loop_heating_type: 'DX',
                                     air_loop_cooling_type: 'DX')
      standard.model_add_hvac_system(model, 'Residential Air Source Heat Pump', 'Electricity', 'Electricity', 'Electricity', system_zones)

    when 'Minisplit Heat Pumps with ERVs'
      standard.model_add_hvac_system(model, 'ERVs', nil, nil, nil, system_zones)
      standard.model_add_hvac_system(model, 'Residential Air Source Heat Pump', 'Electricity', 'Electricity', 'Electricity', system_zones)

    when 'PTHPs with DOAS'
      standard.model_add_hvac_system(model, 'DOAS', 'Electricity', nil, 'Electricity', system_zones,
                                     air_loop_heating_type: 'DX',
                                     air_loop_cooling_type: 'DX')
      standard.model_add_hvac_system(model, 'PTHP', nil, nil, nil, system_zones,
                                     zone_equipment_ventilation: false)

    when 'PTHPs with ERVs'
      standard.model_add_hvac_system(model, 'ERVs', nil, nil, nil, system_zones)
      standard.model_add_hvac_system(model, 'PTHP', nil, nil, nil, system_zones,
                                     zone_equipment_ventilation: false)

    when 'Four-pipe Fan Coils with central air-source heat pump with DOAS'
      standard.model_add_hvac_system(model, 'DOAS', 'AirSourceHeatPump', nil, 'Electricity', system_zones,
                                     hot_water_loop_type: 'LowTemperature',
                                     chilled_water_loop_cooling_type: 'AirCooled',
                                     air_loop_heating_type: 'Water',
                                     air_loop_cooling_type: 'Water')
      standard.model_add_hvac_system(model, 'Fan Coil', 'AirSourceHeatPump', nil, 'Electricity', system_zones,
                                     hot_water_loop_type: 'LowTemperature',
                                     chilled_water_loop_cooling_type: 'AirCooled',
                                     zone_equipment_ventilation: false,
                                     fan_coil_capacity_control_method: 'VariableFanVariableFlow')

    when 'Four-pipe Fan Coils with central air-source heat pump with ERVs'
      standard.model_add_hvac_system(model, 'ERVs', nil, nil, nil, system_zones)
      standard.model_add_hvac_system(model, 'Fan Coil', 'AirSourceHeatPump', nil, 'Electricity', system_zones,
                                     hot_water_loop_type: 'LowTemperature',
                                     chilled_water_loop_cooling_type: 'AirCooled',
                                     zone_equipment_ventilation: false,
                                     fan_coil_capacity_control_method: 'VariableFanVariableFlow')

    when 'Water Source Heat Pumps with Boiler and Fluid-cooler with DOAS'
      standard.model_add_hvac_system(model, 'DOAS', 'Electricity', nil, 'Electricity', system_zones,
                                     air_loop_heating_type: 'DX',
                                     air_loop_cooling_type: 'DX')
      standard.model_add_hvac_system(model, 'Water Source Heat Pumps', 'NaturalGas', nil, 'Electricity', system_zones,
                                     heat_pump_loop_cooling_type: 'EvaporativeFluidCooler',
                                     zone_equipment_ventilation: false)

    when 'Water Source Heat Pumps with Boiler and Fluid-cooler with ERVs'
      standard.model_add_hvac_system(model, 'ERVs', nil, nil, nil, system_zones)
      standard.model_add_hvac_system(model, 'Water Source Heat Pumps', 'NaturalGas', nil, 'Electricity', system_zones,
                                     heat_pump_loop_cooling_type: 'EvaporativeFluidCooler',
                                     zone_equipment_ventilation: false)

    when 'Water Source Heat Pumps with Ground Source Heat Pump with DOAS'
      standard.model_add_hvac_system(model, 'DOAS', 'Electricity', nil, 'Electricity', system_zones,
                                     air_loop_heating_type: 'DX',
                                     air_loop_cooling_type: 'DX')
      standard.model_add_hvac_system(model, 'Ground Source Heat Pumps', 'Electricity', nil, 'Electricity', system_zones,
                                     zone_equipment_ventilation: false)

    when 'Water Source Heat Pumps with Ground Source Heat Pump with ERVs'
      standard.model_add_hvac_system(model, 'ERVs', nil, nil, nil, system_zones)
      standard.model_add_hvac_system(model, 'Ground Source Heat Pumps', 'Electricity', nil, 'Electricity', system_zones,
                                     zone_equipment_ventilation: false)

    else
      runner.registerError("HVAC System #{system_type} not recognized")
      return false
    end

    # adjust DOAS setpoint temperatures
    htg_dsgn_sup_air_temp_c = OpenStudio.convert(65.0, 'F', 'C').get
    if system_type.include? 'DOAS'
      model.getAirLoopHVACs.each do |air_loop|
        next unless air_loop.name.to_s.include? 'DOAS'
        sizing_system = air_loop.sizingSystem
        sizing_system.setCentralHeatingDesignSupplyAirTemperature(htg_dsgn_sup_air_temp_c)
        air_loop.supplyOutletNode.setpointManagers.each do |spm|
          if spm.to_SetpointManagerOutdoorAirReset.is_initialized
            spm = spm.to_SetpointManagerOutdoorAirReset.get
            spm.setSetpointatOutdoorLowTemperature(htg_dsgn_sup_air_temp_c)
          end
        end
        air_loop.thermalZones.each do |zone|
          sizing_zone = zone.sizingZone
          sizing_zone.setDedicatedOutdoorAirHighSetpointTemperatureforDesign(htg_dsgn_sup_air_temp_c)
        end
      end
    end
  end

  # define the arguments that the user will input
  def arguments(model)
    args = OpenStudio::Measure::OSArgumentVector.new

    # make an argument for add_constructions
    add_constructions = OpenStudio::Measure::OSArgument.makeBoolArgument('add_constructions', true)
    add_constructions.setDisplayName('Add Constructions to Model')
    add_constructions.setDescription('The Construction Set will be applied to the entire building')
    add_constructions.setDefaultValue(true)
    args << add_constructions

    # make an argument for wall and roof construction template
    construction_set_chs = OpenStudio::StringVector.new
    construction_set_chs << '90.1-2019'
    construction_set_chs << 'Good'
    construction_set_chs << 'Better'
    construction_set_chs << 'ZE AEDG Multifamily Recommendations'
    wall_roof_construction_template = OpenStudio::Measure::OSArgument.makeChoiceArgument('wall_roof_construction_template', construction_set_chs, true)
    wall_roof_construction_template.setDisplayName('Construction template for adding wall and roof constructions')
    wall_roof_construction_template.setDescription('The constructions will be applied to the entire building')
    wall_roof_construction_template.setDefaultValue('ZE AEDG Multifamily Recommendations')
    args << wall_roof_construction_template

    # make an argument for window construction template
    construction_set_chs = OpenStudio::StringVector.new
    construction_set_chs << '90.1-2019'
    construction_set_chs << 'Good'
    construction_set_chs << 'Better'
    construction_set_chs << 'ZE AEDG Multifamily Recommendations'
    window_construction_template = OpenStudio::Measure::OSArgument.makeChoiceArgument('window_construction_template', construction_set_chs, true)
    window_construction_template.setDisplayName('Construction template for adding window constructions')
    window_construction_template.setDescription('The constructions will be applied to the entire building')
    window_construction_template.setDefaultValue('ZE AEDG Multifamily Recommendations')
    args << window_construction_template

    # make an argument for add_space_type_loads
    add_space_type_loads = OpenStudio::Measure::OSArgument.makeBoolArgument('add_space_type_loads', true)
    add_space_type_loads.setDisplayName('Add Space Type Loads to Model')
    add_space_type_loads.setDescription('Populate existing space types in model with internal loads.')
    add_space_type_loads.setDefaultValue(true)
    args << add_space_type_loads

    # make an argument for add_elevators
    add_elevators = OpenStudio::Measure::OSArgument.makeBoolArgument('add_elevators', true)
    add_elevators.setDisplayName('Add Elevators to Model')
    add_elevators.setDescription('Elevators will be add directly to space in model vs. being applied to a space type.')
    add_elevators.setDefaultValue(false)
    args << add_elevators

    # make an argument for elev_spaces
    # todo - make sure this is setup to handle no elevators and also that it handles bad names well.
    elev_spaces = OpenStudio::Measure::OSArgument.makeStringArgument('elev_spaces', true)
    elev_spaces.setDisplayName('Elevator Spaces')
    elev_spaces.setDescription('Comma separated names of spaces for elevator. Each space listed will have associated elevator loads.')
    elev_spaces.setDefaultValue("Elevator_1_4,Elevator_2_4")
    args << elev_spaces

    # elevator type
    elevator_type_chs = OpenStudio::StringVector.new
    elevator_type_chs << 'Traction'
    elevator_type_chs << 'Hydraulic'
    # todo - could include auto that looks at number of stories
    elevator_type = OpenStudio::Measure::OSArgument.makeChoiceArgument('elevator_type', elevator_type_chs, true)
    elevator_type.setDisplayName('Elevator Type')
    elevator_type.setDescription('This will impact loads, schedules, and fraction of heat lost.')
    elevator_type.setDefaultValue('Traction')
    args << elevator_type

    # make an argument for add_internal_mass
    add_internal_mass = OpenStudio::Measure::OSArgument.makeBoolArgument('add_internal_mass', true)
    add_internal_mass.setDisplayName('Add Internal Mass to Model')
    add_internal_mass.setDescription('Adds internal mass to each space.')
    add_internal_mass.setDefaultValue(true)
    args << add_internal_mass

    # make an argument for add_exterior_lights
    add_exterior_lights = OpenStudio::Measure::OSArgument.makeBoolArgument('add_exterior_lights', true)
    add_exterior_lights.setDisplayName('Add Exterior Lights to Model')
    add_exterior_lights.setDescription('Multiple exterior lights objects will be added for different classes of lighting such as parking and facade.')
    add_exterior_lights.setDefaultValue(true)
    args << add_exterior_lights

    # make an argument for onsite_parking_fraction
    onsite_parking_fraction = OpenStudio::Measure::OSArgument.makeDoubleArgument('onsite_parking_fraction', true)
    onsite_parking_fraction.setDisplayName('Onsite Parking Fraction')
    onsite_parking_fraction.setDescription('If set to 0 no exterior lighting for parking will be added')
    onsite_parking_fraction.setDefaultValue(0.0)
    args << onsite_parking_fraction

    # make an argument for add_thermostat
    add_thermostat = OpenStudio::Measure::OSArgument.makeBoolArgument('add_thermostat', true)
    add_thermostat.setDisplayName('Add Thermostats')
    add_thermostat.setDescription('Add Thermostat to model based on Space Type Standards information of spaces assigned to thermal zones.')
    add_thermostat.setDefaultValue(true)
    args << add_thermostat

    # make an argument for add_swh
    add_swh = OpenStudio::Measure::OSArgument.makeBoolArgument('add_swh', true)
    add_swh.setDisplayName('Add Service Water Heating to Model')
    add_swh.setDescription('This will add both the supply and demand side of service water heating.')
    add_swh.setDefaultValue(true)
    args << add_swh

    swh_chs = OpenStudio::StringVector.new
    swh_chs << 'HeatPump'
    swh_type = OpenStudio::Measure::OSArgument.makeChoiceArgument('swh_type', swh_chs, true)
    swh_type.setDisplayName('Service Water Heating Source')
    swh_type.setDescription('The primary source of heating used by SWH systems in the model.')
    swh_type.setDefaultValue('HeatPump')
    args << swh_type

    # make an argument for add_hvac
    add_hvac = OpenStudio::Measure::OSArgument.makeBoolArgument('add_hvac', true)
    add_hvac.setDisplayName('Add HVAC System to Model')
    add_hvac.setDefaultValue(true)
    args << add_hvac

    # Make argument for system type
    hvac_chs = OpenStudio::StringVector.new
    hvac_chs << 'Minisplit Heat Pumps with DOAS'
    hvac_chs << 'Minisplit Heat Pumps with ERVs'
    hvac_chs << 'PTHPs with DOAS'
    hvac_chs << 'PTHPs with ERVs'
    hvac_chs << 'Four-pipe Fan Coils with central air-source heat pump with DOAS'
    hvac_chs << 'Four-pipe Fan Coils with central air-source heat pump with ERVs'
    hvac_chs << 'Water Source Heat Pumps with Boiler and Fluid-cooler with DOAS'
    hvac_chs << 'Water Source Heat Pumps with Boiler and Fluid-cooler with ERVs'
    hvac_chs << 'Water Source Heat Pumps with Ground Source Heat Pump with DOAS'
    hvac_chs << 'Water Source Heat Pumps with Ground Source Heat Pump with ERVs'
    hvac_system_type = OpenStudio::Measure::OSArgument.makeChoiceArgument('hvac_system_type', hvac_chs, true)
    hvac_system_type.setDisplayName('HVAC System Type')
    hvac_system_type.setDefaultValue('Four-pipe Fan Coils with central air-source heat pump with DOAS')
    args << hvac_system_type

    # make an argument for remove_objects
    # remove_objects = OpenStudio::Measure::OSArgument.makeBoolArgument('remove_objects', true)
    # remove_objects.setDisplayName('Clean Model of non-geometry objects')
    # remove_objects.setDescription('Only removes objects of type that are selected to be added.')
    # remove_objects.setDefaultValue(true)
    # args << remove_objects

    return args
  end

  # define what happens when the measure is run
  def run(model, runner, user_arguments)
    super(model, runner, user_arguments)

    # use the built-in error checking
    unless runner.validateUserArguments(arguments(model), user_arguments)
      return false
    end

    # assign the user inputs to variables
    args = {}
    args['add_constructions'] = runner.getBoolArgumentValue('add_constructions', user_arguments)
    args['wall_roof_construction_template'] = runner.getStringArgumentValue('wall_roof_construction_template', user_arguments)
    args['window_construction_template'] = runner.getStringArgumentValue('window_construction_template', user_arguments)
    args['add_space_type_loads'] = runner.getBoolArgumentValue('add_space_type_loads', user_arguments)
    args['add_elevators'] = runner.getBoolArgumentValue('add_elevators', user_arguments)
    args['elev_spaces'] = runner.getStringArgumentValue('elev_spaces', user_arguments)
    args['elevator_type'] = runner.getStringArgumentValue('elevator_type', user_arguments)
    args['add_exterior_lights'] = runner.getBoolArgumentValue('add_exterior_lights', user_arguments)
    args['onsite_parking_fraction'] = runner.getDoubleArgumentValue('onsite_parking_fraction', user_arguments)
    args['add_constructions'] = runner.getBoolArgumentValue('add_constructions', user_arguments)
    args['add_internal_mass'] = runner.getBoolArgumentValue('add_internal_mass', user_arguments)
    args['add_thermostat'] = runner.getBoolArgumentValue('add_thermostat', user_arguments)
    args['add_swh'] = runner.getBoolArgumentValue('add_swh', user_arguments)
    args['swh_type'] = runner.getStringArgumentValue('swh_type', user_arguments)
    args['add_hvac'] = runner.getBoolArgumentValue('add_hvac', user_arguments)
    args['hvac_system_type'] = runner.getStringArgumentValue('hvac_system_type', user_arguments)
    #args['remove_objects'] = runner.getBoolArgumentValue('remove_objects', user_arguments)
    args['remove_objects'] = false

    # validate fraction parking
    fraction = OsLib_HelperMethods.checkDoubleAndIntegerArguments(runner, user_arguments, 'min' => 0.0, 'max' => 1.0, 'min_eq_bool' => true, 'max_eq_bool' => true, 'arg_array' => ['onsite_parking_fraction'])
    if !fraction then return false end


    # report initial condition of model
    initial_objects = model.getModelObjects.size
    runner.registerInitialCondition("The building started with #{initial_objects} objects.")

    # open channel to log messages
    reset_log

    # remap residential building types and add ventilation
    model.getSpaceTypes.each do |space_type|
      if space_type.standardsSpaceType.get.to_s == "living"
        space_type.setStandardsSpaceType("Apartment")
      end
    end

    # Make the standard appliers
    standard = Standard.build('ZE AEDG Multifamily')

    # get climate zone for model
    climate_zone = standard.model_standards_climate_zone(model)
    if climate_zone.empty?
      runner.registerError('Climate zone could not be determined. Please set climate zone in the model.')
      log_messages_to_runner(runner, debug = true)
      return false
    else
      runner.registerInfo("Using climate zone #{climate_zone} from model")
    end

    # identify primary building type (used for construction, and ideally HVAC as well)
    # hard coded for this measure instead of identifying building type that represents the largest building area
    lookup_building_type = 'MidriseApartment'
    primary_bldg_type = lookup_building_type
    model.getBuilding.setStandardsBuildingType(lookup_building_type)

    # make construction set and apply to building
    if args['add_constructions']

      # remove default construction sets
      if args['remove_objects']
        model.getDefaultConstructionSets.each(&:remove)
      end
      # remove hard assigned constructions (wwr measures can hard assign constructions)
      model.getPlanarSurfaces.each do |surface|
        surface.resetConstruction
      end

      if ['SmallHotel', 'LargeHotel', 'MidriseApartment', 'HighriseApartment'].include?(primary_bldg_type)
        is_residential = 'Yes'
      else
        is_residential = 'No'
      end
      climate_zone = standard.model_get_building_climate_zone_and_building_type(model)['climate_zone']
      bldg_def_const_set = standard.model_add_construction_set(model, climate_zone, lookup_building_type, nil, is_residential)
      if bldg_def_const_set.is_initialized
        bldg_def_const_set = bldg_def_const_set.get
        if is_residential then bldg_def_const_set.setName("Res #{bldg_def_const_set.name}") end
        model.getBuilding.setDefaultConstructionSet(bldg_def_const_set)
        runner.registerInfo("Adding default construction set named #{bldg_def_const_set.name}")
      else
        runner.registerError("Could not create default construction set for the building type #{lookup_building_type} in climate zone #{climate_zone}.")
        log_messages_to_runner(runner, debug = true)
        return false
      end

      # address any adiabatic surfaces that don't have hard assigned constructions
      model.getSurfaces.each do |surface|
        next if surface.outsideBoundaryCondition != 'Adiabatic'
        next if surface.construction.is_initialized
        surface.setAdjacentSurface(surface)
        surface.setConstruction(surface.construction.get)
        surface.setOutsideBoundaryCondition('Adiabatic')
      end

      # Modify the infiltration rates
      if args['remove_objects']
        model.getSpaceInfiltrationDesignFlowRates.each(&:remove)
      end
      standard.model_apply_infiltration_standard(model)
      standard.model_modify_infiltration_coefficients(model, primary_bldg_type, climate_zone)

      # set ground temperatures from DOE prototype buildings
      standard.model_add_ground_temperatures(model, primary_bldg_type, climate_zone)

      # load construction sets for parametrics
      translator = OpenStudio::OSVersion::VersionTranslator.new
      ospath = OpenStudio::Path.new("#{File.dirname(__FILE__)}/resources/ze_aedg_multifamily_parametric_construction_sets.osm")
      construction_set_model = translator.loadModel(ospath)
      construction_set_model = construction_set_model.get
      # add construction sets to model
      construction_set = construction_set_model.getDefaultConstructionSetByName("90.1-2019 - #{climate_zone}").get
      construction_set.clone(model).to_DefaultConstructionSet.get
      construction_set = construction_set_model.getDefaultConstructionSetByName("Good - #{climate_zone}").get
      construction_set.clone(model).to_DefaultConstructionSet.get
      construction_set = construction_set_model.getDefaultConstructionSetByName("Better - #{climate_zone}").get
      construction_set.clone(model).to_DefaultConstructionSet.get

      # reset the wall and roof constructions based on the user-selected construction template
      if args['wall_roof_construction_template'] == 'ZE AEDG Multifamily Recommendations' && args['window_construction_template'] == 'ZE AEDG Multifamily Recommendations'
        runner.registerInfo("Keeping #{args['wall_roof_construction_template']}; keeping 'ZE AEDG Multifamily' constructions.")
      else
        runner.registerInfo("Applying #{args['wall_roof_construction_template']} roof and wall constructions and #{args['window_construction_template']} window constructions.")
        if args['wall_roof_construction_template'] == args['window_construction_template']
          construction_set_lookup = "#{args['wall_roof_construction_template']} - #{climate_zone}"
          new_construction_set = model.getDefaultConstructionSetByName(construction_set_lookup).get
          model.getBuilding.setDefaultConstructionSet(new_construction_set)
        else
          # combine construction sets
          new_construction_set = model.getBuilding.defaultConstructionSet.get.clone(model).to_DefaultConstructionSet.get
          new_construction_set.setName("#{args['wall_roof_construction_template']} walls and roofs and #{args['window_construction_template']} windows - #{climate_zone}")

          # change wall and roof properties if necessary
          unless args['wall_roof_construction_template'] == 'ZE AEDG Multifamily Recommendations'
            construction_set_lookup = "#{args['wall_roof_construction_template']} - #{climate_zone}"
            wall_roof_construction_set = model.getDefaultConstructionSetByName(construction_set_lookup).get
            ext_surf_set = wall_roof_construction_set.defaultExteriorSurfaceConstructions.get
            new_construction_set.setDefaultExteriorSurfaceConstructions(ext_surf_set)
          end

          # change window properties if necessary
          unless args['window_construction_template'] == 'ZE AEDG Multifamily Recommendations'
            construction_set_lookup = "#{args['window_construction_template']} - #{climate_zone}"
            window_construction_set = model.getDefaultConstructionSetByName(construction_set_lookup).get
            sub_surf_set = window_construction_set.defaultExteriorSubSurfaceConstructions.get
            new_construction_set.setDefaultExteriorSubSurfaceConstructions(sub_surf_set)
          end

          # assign default construction set to the building
          model.getBuilding.setDefaultConstructionSet(new_construction_set)
        end
      end
    end

    # add internal loads to space types
    if args['add_space_type_loads']

      # remove internal loads
      if args['remove_objects']
        model.getSpaceLoads.each do |instance|
          next if instance.name.to_s.include?('Elevator') # most prototype building types model exterior elevators with name Elevator
          next if instance.to_InternalMass.is_initialized
          next if instance.to_WaterUseEquipment.is_initialized
          instance.remove
        end
        model.getDesignSpecificationOutdoorAirs.each(&:remove)
        model.getDefaultScheduleSets.each(&:remove)
      end

      model.getSpaceTypes.each do |space_type|
        # Don't add infiltration here; will be added later in the script
        if space_type.standardsSpaceType.get.to_s == "Apartment"
          # only add ventilation
          test = standard.space_type_apply_internal_loads(space_type, false, false, false, false, true, false)
        else
          test = standard.space_type_apply_internal_loads(space_type, true, true, true, true, true, false)
        end
        if test == false
          runner.registerWarning("Could not add loads for #{space_type.name}. Not expected for #{args['template']}")
          next
        end

        # apply internal load schedules
        # the last bool test it to make thermostat schedules. They are now added in HVAC section instead of here
        if space_type.standardsSpaceType.get.to_s == "Apartment"
          # only add ventilation
          test = standard.space_type_apply_internal_load_schedules(space_type, false, false, false, false, true, false, false)
        else
          test = standard.space_type_apply_internal_load_schedules(space_type, true, true, true, true, true, true, false)
        end
        if test == false
          runner.registerWarning("Could not add schedules for #{space_type.name}. Not expected for #{args['template']}")
          next
        end

        # extend space type name to include the args['template']. Consider this as well for load defs
        space_type.setName("#{space_type.name} - #{args['template']}")
        runner.registerInfo("Adding loads to space type named #{space_type.name}")
      end

      # warn if spaces in model without space type
      spaces_without_space_types = []
      model.getSpaces.each do |space|
        next if space.spaceType.is_initialized
        spaces_without_space_types << space
      end
      unless spaces_without_space_types.empty?
        runner.registerWarning("#{spaces_without_space_types.size} spaces do not have space types assigned, and wont' receive internal loads from standards space type lookups.")
      end
    end

    # add elevators (returns ElectricEquipment object)
    if args['add_elevators']

      # remove elevators as spaceLoads or exteriorLights
      model.getSpaceLoads.each do |instance|
        next unless instance.name.to_s.include?('Elevator') # most prototype building types model exterior elevators with name Elevator
        instance.remove
      end
      model.getExteriorLightss.each do |ext_light|
        next unless ext_light.name.to_s.include?('Fuel equipment') # some prototype building types model exterior elevators by this name
        ext_light.remove
      end

      # number of elevators
      space_names = args['elev_spaces'].split(',')
      spaces = []
      space_names.sort.each do |name|
        spaces << model.getSpaceByName(name).get
      end
      number_of_elevators = spaces.size

      # determine blended occupancy schedule
      # todo - code to create schedules copied from standards. Break that out in standards into method that can be called from here
      occ_schedule = standard.spaces_get_occupancy_schedule(model.getSpaces)

      # get total number of people in building
      max_occ_in_spaces = 0
      model.getSpaces.each do |space|
        # From the space type
        if space.spaceType.is_initialized
          space.spaceType.get.people.each do |people|
            num_ppl = people.getNumberOfPeople(space.floorArea)
            max_occ_in_spaces += num_ppl
          end
        end
        # From the space
        space.people.each do |people|
          num_ppl = people.getNumberOfPeople(space.floorArea)
          max_occ_in_spaces += num_ppl
        end
      end

      # make elevator schedule based on change in occupancy for each timestep
      day_schedules = []
      default_day_schedule = occ_schedule.defaultDaySchedule
      day_schedules << default_day_schedule
      occ_schedule.scheduleRules.each do |rule|
        day_schedules << rule.daySchedule
      end
      day_schedules.each do |day_schedule|
        elevator_hourly_fractions = []
        (0..23).each do |hr|
          t = OpenStudio::Time.new(0, hr, 0, 0)
          value = day_schedule.getValue(t)
          t_plus = OpenStudio::Time.new(0, hr + 1, 0, 0)
          value_plus = day_schedule.getValue(t_plus)
          change_occupancy_fraction = (value_plus - value).abs
          change_num_people = change_occupancy_fraction * max_occ_in_spaces * 1.2
          # multiplication factor or 1.2 to account for interfloor traffic

          # determine time per ride based on number of floors and elevator type
          elevator_type = args['elevator_type']
          effective_num_stories = standard.model_effective_num_stories(model)
          if elevator_type == 'Hydraulic'
            time_per_ride = 8.7 + (effective_num_stories[:above_grade] * 5.6)
          elsif elevator_type == 'Traction'
            time_per_ride = 5.6 + (effective_num_stories[:above_grade] * 2.1)
          else
            OpenStudio.logFree(OpenStudio::Error, 'openstudio.prototype.elevators', "Elevator type #{elevator_type} not recognized.")
            return nil
          end

          # determine elevator operation fraction for each timestep
          people_per_ride = 5
          rides_per_elevator = (change_num_people / people_per_ride) / number_of_elevators
          operation_time = rides_per_elevator * time_per_ride
          elevator_operation_fraction = operation_time / 3600
          if elevator_operation_fraction > 1.00
            elevator_operation_fraction = 1.00
          end
          elevator_hourly_fractions << elevator_operation_fraction
        end

        # replace hourly occupancy values with operating fractions
        day_schedule.clearValues
        (0..23).each do |hr|
          t = OpenStudio::Time.new(0, hr, 0, 0)
          value = elevator_hourly_fractions[hr]
          value_plus = if hr <= 22
                         elevator_hourly_fractions[hr + 1]
                       else
                         elevator_hourly_fractions[0]
                       end
          next if value == value_plus
          day_schedule.addValue(t, elevator_hourly_fractions[hr])
        end
      end

      occ_schedule.setName('Elevator Schedule')

      # clone new elevator schedule and assign to elevator
      elev_sch = occ_schedule.clone(model)
      elevator_schedule = elev_sch.name.to_s

      # For elevator lights and fan, assume 100% operation during hours that elevator fraction > 0 (when elevator is in operation).
      # elevator lights
      lights_sch = occ_schedule.clone(model)
      lights_sch = lights_sch.to_ScheduleRuleset.get
      profiles = []
      profiles << lights_sch.defaultDaySchedule
      rules = lights_sch.scheduleRules
      rules.each do |rule|
        profiles << rule.daySchedule
      end
      profiles.each do |profile|
        times = profile.times
        values = profile.values
        values.each_with_index do |val, i|
          if val > 0
            profile.addValue(times[i], 1.0)
          end
        end
      end
      elevator_lights_schedule = lights_sch.name.to_s

      # elevator fan
      fan_sch = occ_schedule.clone(model)
      fan_sch = fan_sch.to_ScheduleRuleset.get
      profiles = []
      profiles << fan_sch.defaultDaySchedule
      rules = fan_sch.scheduleRules
      rules.each do |rule|
        profiles << rule.daySchedule
      end
      profiles.each do |profile|
        times = profile.times
        values = profile.values
        values.each_with_index do |val, i|
          if val > 0
            profile.addValue(times[i], 1.0)
          end
        end
      end
      elevator_fan_schedule = fan_sch.name.to_s

      # orig loads from first space
      orig_loads = []
      new_loads = []
      spaces.first.electricEquipment.each do |equip|
        orig_loads << equip
      end

      # make an elevator for each space
      elevators = nil
      spaces.each do |space|
        if elevators.nil?
          elevators  = standard.model_add_elevator(model,space, number_of_elevators, args['elevator_type'], elevator_schedule, elevator_fan_schedule, elevator_lights_schedule)
          if elevators.nil?
            runner.registerInfo('No elevators added to the building.')
          else
            elevator_def = elevators.electricEquipmentDefinition
            design_level = elevator_def.designLevel.get
            runner.registerInfo("Adding #{number_of_elevators} elevators with combined power of #{OpenStudio.toNeatString(design_level, 0, true)} (W), plus lights and fans.")
            # todo confirm if we want fraction lost for all elevators
            elevator_def.setFractionLost(1.0)
            elevator_def.setFractionRadiant(0.0)

            # adjust multipliers to 1 for new loads
            space.electricEquipment.each do |equip|
              next if orig_loads.include?(equip)
              equip.setName(equip.name.get.gsub(number_of_elevators.to_i.to_s,space.name.to_s))
              equip.setMultiplier(1.0) #orig multiplier is number of elevators
              new_loads << equip
            end
          end
        else
          new_loads.each do |equip|
            old_name = equip.name
            new_name = equip.name.get.gsub(spaces.first.name.to_s,space.name.to_s)
            new_equip = equip.clone(model).to_SpaceItem.get
            new_equip.setSpace(space)
            new_equip.setName(new_name)
          end
        end
      end
    end

    # add exterior lights (returns a hash where key is lighting type and value is exteriorLights object)
    if args['add_exterior_lights']

      if args['remove_objects']
        model.getExteriorLightss.each do |ext_light|
          next if ext_light.name.to_s.include?('Fuel equipment') # some prototype building types model exterior elevators by this name
          ext_light.remove
        end
      end

      exterior_lights = standard.model_add_typical_exterior_lights(model, 3, args['onsite_parking_fraction'])
      exterior_lights.each do |k, v|
        runner.registerInfo("Adding Exterior Lights named #{v.exteriorLightsDefinition.name} with design level of #{v.exteriorLightsDefinition.designLevel} * #{OpenStudio.toNeatString(v.multiplier, 0, true)}.")
      end
    end

    # add internal mass
    if args['add_internal_mass']

      if args['remove_objects']
        model.getSpaceLoads.each do |instance|
          next unless instance.to_InternalMass.is_initialized
          instance.remove
        end
      end

      # add internal mass to conditioned spaces; needs to happen after thermostats are applied
      standard.model_add_internal_mass(model, primary_bldg_type)
    end

    # switch back living space types so I don't alter thermostats or
    model.getSpaceTypes.each do |space_type|
      if space_type.standardsSpaceType.get.to_s == "Apartment"
        space_type.setStandardsSpaceType("living")
      end
    end

    # add thermostats
    if args['add_thermostat']

      # remove thermostats
      if args['remove_objects']
        model.getThermostatSetpointDualSetpoints.each(&:remove)
      end

      model.getSpaceTypes.each do |space_type|
        # create thermostat schedules
        # skip un-recognized space types
        next if standard.space_type_get_standards_data(space_type).empty?
        # the last bool test it to make thermostat schedules. They are added to the model but not assigned
        standard.space_type_apply_internal_load_schedules(space_type, false, false, false, false, false, false, true)

        # identify thermal thermostat and apply to zones (apply_internal_load_schedules names )
        model.getThermostatSetpointDualSetpoints.each do |thermostat|
          next if thermostat.name.to_s != "#{space_type.name} Thermostat"
          next unless thermostat.coolingSetpointTemperatureSchedule.is_initialized
          next unless thermostat.heatingSetpointTemperatureSchedule.is_initialized
          runner.registerInfo("Assigning #{thermostat.name} to thermal zones with #{space_type.name} assigned.")
          space_type.spaces.each do |space|
            next unless space.thermalZone.is_initialized
            space.thermalZone.get.setThermostatSetpointDualSetpoint(thermostat)
          end
        end
      end
    end

    # add service water heating demand and supply
    if args['add_swh']

      # remove water use equipment and water use connections
      if args['remove_objects']
        # TODO: - remove plant loops used for service water heating
        model.getWaterUseEquipments.each(&:remove)
        model.getWaterUseConnectionss.each(&:remove)
      end

      unless model.getWaterHeaterMixeds.empty?
        hpwh_cop = 2.8
        eff_f_of_plr = OpenStudio::Model::CurveCubic.new(model)
        eff_f_of_plr.setName("HPWH_COP_#{hpwh_cop}")
        eff_f_of_plr.setCoefficient1Constant(hpwh_cop)
        eff_f_of_plr.setCoefficient2x(0.0)
        eff_f_of_plr.setCoefficient3xPOW2(0.0)
        eff_f_of_plr.setCoefficient4xPOW3(0.0)
        eff_f_of_plr.setMinimumValueofx(0.0)
        eff_f_of_plr.setMaximumValueofx(1.0)
        model.getWaterHeaterMixeds.each do |water_heater|
          water_heater.setHeaterFuelType('Electricity')
          water_heater.setHeaterThermalEfficiency(1.0)
          water_heater.setPartLoadFactorCurve(eff_f_of_plr)
          water_heater.setOffCycleParasiticFuelConsumptionRate(0.0)
          water_heater.setOnCycleParasiticFuelConsumptionRate(0.0)
          water_heater.setOffCycleParasiticFuelType('Electricity')
          water_heater.setOnCycleParasiticFuelType('Electricity')
          water_heater.setOffCycleLossCoefficienttoAmbientTemperature(1.053)
          water_heater.setOnCycleLossCoefficienttoAmbientTemperature(1.053)
        end
      end

      typical_swh = standard.model_add_typical_swh(model, water_heater_fuel: args['swh_type'])
      midrise_swh_loops = []
      stripmall_swh_loops = []
      typical_swh.each do |loop|
        if loop.name.get.include?('MidriseApartment')
          midrise_swh_loops << loop
        elsif loop.name.get.include?('RetailStripmall')
          stripmall_swh_loops << loop
        else
          water_use_connections = []
          loop.demandComponents.each do |component|
            next unless component.to_WaterUseConnections.is_initialized
            water_use_connections << component
          end
          runner.registerInfo("Adding #{loop.name} to the building. It has #{water_use_connections.size} water use connections.")
        end
      end
      unless midrise_swh_loops.empty?
        runner.registerInfo("Adding #{midrise_swh_loops.size} MidriseApartment service water heating loops.")
      end
      unless stripmall_swh_loops.empty?
        runner.registerInfo("Adding #{stripmall_swh_loops.size} RetailStripmall service water heating loops.")
      end
    end

    # make windows in apartments operable
    runner.registerInfo("Making apartment windows operable. This may use a different construction than fixed windows.")
    model.getSpaceTypes.each do |space_type|
      next if not space_type.standardsSpaceType.get.to_s == "living"
      space_type.spaces.each do |space|
        space.surfaces.each do |surface|
          surface.subSurfaces.each do |sub_surface|
            next if not sub_surface.subSurfaceType == "FixedWindow" && sub_surface.outsideBoundaryCondition == "Outdoors"
            sub_surface.setSubSurfaceType("OperableWindow")
          end
        end
      end
    end

    # add daylight controls, need to perform a sizing run for 2010
    runner.registerInfo("Adding daylight controls to model.")
    if args['template'] == '90.1-2010'
      if standard.model_run_sizing_run(model, "#{Dir.pwd}/SRvt") == false
        log_messages_to_runner(runner, debug = true)
        return false
      end
    end
    standard.model_add_daylighting_controls(model)

    # add hvac system
    if args['add_hvac']

      # remove HVAC objects
      standard.model_remove_prm_hvac(model) if args['remove_objects']

      # re-assign apartment standards data type for occupancy grouping
      model.getSpaceTypes.each do |space_type|
        next unless space_type.standardsBuildingType.is_initialized
        next unless space_type.standardsSpaceType.is_initialized
        standards_space_type = space_type.standardsSpaceType.get
        if standards_space_type == 'living'
          space_type.setStandardsSpaceType('Apartment')
        end
      end

      # Group the zones by occupancy type.  Only split out non-dominant groups if their total area exceeds the limit.
      sys_groups = standard.model_group_zones_by_type(model, min_area_m2 = OpenStudio.convert(500, 'ft^2', 'm^2').get)
      sys_groups.each do |sys_group|
        zero_energy_multifamily_add_hvac(model, runner, standard, args['hvac_system_type'], sys_group['zones'])
      end
    end

    # set unmet hours tolerance to 1 deg R
    unmet_hrs_tol_k = OpenStudio.convert(1.0, 'R', 'K').get
    tolerances = model.getOutputControlReportingTolerances
    tolerances.setToleranceforTimeHeatingSetpointNotMet(unmet_hrs_tol_k)
    tolerances.setToleranceforTimeCoolingSetpointNotMet(unmet_hrs_tol_k)

    # set hvac controls and efficiencies (this should be last model articulation element)
    if args['add_hvac']

      # set additional properties for building
      props = model.getBuilding.additionalProperties
      props.setFeature('hvac_system_type', args['hvac_system_type'])

      # Set the heating and cooling sizing parameters
      standard.model_apply_prm_sizing_parameters(model)

      # Perform a sizing run
      unless standard.model_run_sizing_run(model, "#{Dir.pwd}/SizingRun")
        log_messages_to_runner(runner, debug = true)
        return false
      end

      # Apply the HVAC efficiency standard
      standard.model_apply_hvac_efficiency_standard(model, climate_zone)
    end 

    # remove everything but spaces, zones, and stub space types (extend as needed for additional objects, may make bool arg for this)
    if args['remove_objects']
      model.purgeUnusedResourceObjects
      objects_after_cleanup = initial_objects - model.getModelObjects.size
      if objects_after_cleanup > 0
        runner.registerInfo("Removing #{objects_after_cleanup} objects from model")
      end
    end

    # report final condition of model
    runner.registerFinalCondition("The building finished with #{model.getModelObjects.size} objects.")

    # log messages to info messages
    log_messages_to_runner(runner, debug = false)

    return true
  end
end

# register the measure to be used by the application
ZeroEnergyMultifamily.new.registerWithApplication
