# see the URL below for information on how to write OpenStudio measures
# http://nrel.github.io/OpenStudio-user-documentation/reference/measure_writing_guide/

# start the measure
class CreateBarFromModel < OpenStudio::Ruleset::ModelUserScript

  # require all .rb files in resources folder
  Dir[File.dirname(__FILE__) + '/resources/*.rb'].each {|file| require file }

  # resource file modules
  include OsLib_HelperMethods
  include OsLib_Geometry
  include OsLib_ModelGeneration
  include OsLib_ModelSimplification

  # human readable name
  def name
    return "Create Bar From Model"
  end

  # human readable description
  def description
    return "Create a core and perimeter bar envelope based on analysis of initial model geometry."
  end

  # human readable description of modeling approach
  def modeler_description
    return "Gather orientation and story specific construction, fenestration (including overhang) specific information"
  end

  # define the arguments that the user will input
  def arguments(model)
    args = OpenStudio::Ruleset::OSArgumentVector.new

    #make an argument for bar calculation method
    choices = OpenStudio::StringVector.new
    choices << "Bar - Reduced Bounding Box" # maintains aspect ratio of bounding box and floor area
    choices << "Bar - Reduced Width" # hybrid of the reduced bounding box and the stretched bars
    choices << "Bar - Stretched" # maintains total exterior wall area and floor area
    bar_calc_method = OpenStudio::Ruleset::OSArgument::makeChoiceArgument("bar_calc_method",choices,true)
    bar_calc_method.setDisplayName("Calculation Method to determine Bar Length and Width.")
    bar_calc_method.setDefaultValue('Bar - Reduced Bounding Box')
    args << bar_calc_method

    #make an argument for bar sub-division approach
    choices = OpenStudio::StringVector.new
    choices << "Single Space Type - Core and Perimeter"
    choices << "Multiple Space Types - Simple Sliced"
    choices << "Multiple Space Types - Individual Stories Sliced"
    bar_division_method = OpenStudio::Ruleset::OSArgument::makeChoiceArgument("bar_division_method",choices,true)
    bar_division_method.setDisplayName("Division Method for Bar Spaces.")
    bar_division_method.setDefaultValue('Single Space Type - Core and Perimeter')
    args << bar_division_method

    return args
  end

  # define what happens when the measure is run
  def run(model, runner, user_arguments)
    super(model, runner, user_arguments)

    # use the built-in error checking
    if !runner.validateUserArguments(arguments(model), user_arguments)
      return false
    end

    bar_calc_method = runner.getStringArgumentValue("bar_calc_method",user_arguments)
    bar_division_method = runner.getStringArgumentValue("bar_division_method",user_arguments)

    # todo - in future may investigate best rotation to fit rectangle
    # todo - in future will investigate all constructions to inform new envelope For now will rely on building default construction set
    # todo - in future store HVAC system type by zone with floor area for each system (identify what is primary)
    # todo - in future store information on exhaust fans

    # todo - space type blending measure should be run upstream if necessary, but could warn user if all spaces of original model don't have space space type assignments
    # todo - warn user of any space loads that will be lost with envelope (I think thi sis addressed)
    # todo - warn user about daylighing control objects that will be removed. In future could add new similar controls back into model

    # assign the user inputs to variables

    # report initial condition of model
    runner.registerInitialCondition("The building started with #{model.getSpaces.size} spaces.")

    # gather_envelope_data
    envelope_data_hash = gather_envelope_data(runner,model)

    # report summary of initial geometry
    runner.registerValue('rotation',envelope_data_hash[:north_axis],'degrees')
    runner.registerInfo("Initial building rotation is #{envelope_data_hash[:north_axis]} degrees.")

    runner.registerValue('building_floor_area',envelope_data_hash[:building_floor_area],'m^2')
    building_floor_area_ip = OpenStudio.convert(envelope_data_hash[:building_floor_area], 'm^2', 'ft^2').get
    runner.registerInfo("Initial building floor area is #{OpenStudio.toNeatString(building_floor_area_ip,0,true)} (ft^2)")

    runner.registerValue('wwr_n',envelope_data_hash[:building_wwr_n],'ratio')
    runner.registerValue('wwr_s',envelope_data_hash[:building_wwr_s],'ratio')
    runner.registerValue('wwr_e',envelope_data_hash[:building_wwr_e],'ratio')
    runner.registerValue('wwr_w',envelope_data_hash[:building_wwr_w],'ratio')
    runner.registerInfo("Initial building North WWR is #{envelope_data_hash[:building_wwr_n].round(2)}.")
    runner.registerInfo("Initial building South WWR is #{envelope_data_hash[:building_wwr_s].round(2)}.")
    runner.registerInfo("Initial building East WWR is #{envelope_data_hash[:building_wwr_e].round(2)}.")
    runner.registerInfo("Initial building West WWR is #{envelope_data_hash[:building_wwr_w].round(2)}.")

    runner.registerValue('proj_factor_n',envelope_data_hash[:building_overhang_proj_factor_n],'ratio')
    if envelope_data_hash[:building_overhang_proj_factor_n] > 0
      runner.registerInfo("Initial building North projection factor is #{envelope_data_hash[:building_overhang_proj_factor_n].round(2)}.")
    end
    runner.registerValue('proj_factor_s',envelope_data_hash[:building_overhang_proj_factor_n],'ratio')
    if envelope_data_hash[:building_overhang_proj_factor_s] > 0
      runner.registerInfo("Initial building South projection factor is #{envelope_data_hash[:building_overhang_proj_factor_s].round(2)}.")
    end
    runner.registerValue('proj_factor_e',envelope_data_hash[:building_overhang_proj_factor_n],'ratio')
    if envelope_data_hash[:building_overhang_proj_factor_e] > 0
      runner.registerInfo("Initial building East projection factor is #{envelope_data_hash[:building_overhang_proj_factor_e].round(2)}.")
    end
    runner.registerValue('proj_factor_w',envelope_data_hash[:building_overhang_proj_factor_n],'ratio')
    if envelope_data_hash[:building_overhang_proj_factor_w] > 0
      runner.registerInfo("Initial building West projection factor is #{envelope_data_hash[:building_overhang_proj_factor_w].round(2)}.")
    end

    runner.registerValue('min_x',envelope_data_hash[:building_min_xyz][0],'m')
    runner.registerValue('min_y',envelope_data_hash[:building_min_xyz][1],'m')
    runner.registerValue('min_z',envelope_data_hash[:building_min_xyz][2],'m')
    runner.registerValue('max_x',envelope_data_hash[:building_max_xyz][0],'m')
    runner.registerValue('max_y',envelope_data_hash[:building_max_xyz][1],'m')
    runner.registerValue('max_z',envelope_data_hash[:building_max_xyz][2],'m')
    min_x_ip = OpenStudio.convert(envelope_data_hash[:building_min_xyz][0], 'm', 'ft').get.round(2)
    min_y_ip = OpenStudio.convert(envelope_data_hash[:building_min_xyz][1], 'm', 'ft').get.round(2)
    min_z_ip = OpenStudio.convert(envelope_data_hash[:building_min_xyz][2], 'm', 'ft').get.round(2)
    max_x_ip = OpenStudio.convert(envelope_data_hash[:building_max_xyz][0], 'm', 'ft').get.round(2)
    max_y_ip = OpenStudio.convert(envelope_data_hash[:building_max_xyz][1], 'm', 'ft').get.round(2)
    max_z_ip = OpenStudio.convert(envelope_data_hash[:building_max_xyz][2], 'm', 'ft').get.round(2)
    effective_number_of_stories_above_grade = 0 # will populate this when looping through stories
    effective_number_of_stories_below_grade = 0 # will populate this when looping through stories
    runner.registerInfo("Intial bounding box is [#{min_x_ip},#{min_y_ip},#{min_z_ip}] and [#{max_x_ip},#{max_y_ip},#{max_z_ip}] (ft).")

    # todo - pass in story and space type hashes as runner.registerValues?

    envelope_data_hash[:stories].each do |story,hash|
      min_height_ip = OpenStudio.convert(hash[:story_min_height],'m','ft').get
      max_height_ip = OpenStudio.convert(hash[:story_max_height],'m','ft').get
      story_footprint = OpenStudio.convert(hash[:story_footprint],'m^2','ft^2').get
      story_perimeter = OpenStudio.convert(hash[:story_perimeter],'m','ft').get
      story_string = []
      story_string << "#{story.name} geometry ranges from #{min_height_ip.round(2)} (ft) #{max_height_ip.round(2)} (ft)."
      story_string << "#{story.name} has a footprint if #{OpenStudio.toNeatString(story_footprint,0,true)} (ft^2) and an exterior perimeter of #{OpenStudio.toNeatString(story_perimeter,0,true)} (ft)."
      if not envelope_data_hash[:stories][story][:story_included_in_building_area]
        story_string << " * #{story.name} has one or more spaces not included in the building area, it may represent a plenum or attic. It should not contribute to the story count for the building"
      else
        # populate effective number of above and below grade stories
        if envelope_data_hash[:stories][story][:story_has_ground_walls].size > 0
          story_string << " * #{story.name} appears to represent a below grade building story."
          effective_number_of_stories_below_grade += envelope_data_hash[:stories][story][:story_min_multiplier]
        else
          effective_number_of_stories_above_grade += envelope_data_hash[:stories][story][:story_min_multiplier]
        end
      end
      if envelope_data_hash[:stories][story][:story_min_multiplier] > 1
        story_string << " * #{story.name} appears to represent #{envelope_data_hash[:stories][story][:story_min_multiplier]} building stories."
      end
      if envelope_data_hash[:stories][story][:story_has_adiabatic_walls].size > 0
        story_string << " * One or more spaces on #{story.name} have surfaces with adiabatic boundary condtions."

        if envelope_data_hash[:stories][story][:story_party_walls].size > 0
          if envelope_data_hash[:stories][story][:story_party_walls].include?('north')
            runner.registerInfo(" * One or more walls on the North side of #{story.name} appear to represent party walls.")
          end
          if envelope_data_hash[:stories][story][:story_party_walls].include?('south')
            runner.registerInfo(" * One or more walls on the South side of #{story.name} appear to represent party walls.")
          end
          if envelope_data_hash[:stories][story][:story_party_walls].include?('east')
            runner.registerInfo(" * One or more walls on the East side of #{story.name} appear to represent party walls.")
          end
          if envelope_data_hash[:stories][story][:story_party_walls].include?('west')
            runner.registerInfo(" * One or more walls on the West side of #{story.name} appear to represent party walls.")
          end
        end

      end
      story_string.each do |string|
        runner.registerInfo(string)
      end

    end

    # log effective number of stories in hash
    envelope_data_hash[:effective_num_stories_below_grade] = effective_number_of_stories_below_grade
    envelope_data_hash[:effective_num_stories_above_grade] = effective_number_of_stories_above_grade
    envelope_data_hash[:effective__num_stories] = effective_number_of_stories_below_grade + effective_number_of_stories_above_grade
    envelope_data_hash[:floor_height] = envelope_data_hash[:building_max_xyz][2] / envelope_data_hash[:effective__num_stories].to_f
    runner.registerInfo("The building has #{effective_number_of_stories_below_grade} below grade stories and #{effective_number_of_stories_above_grade} above grade stories.")

    # todo - issue with calculated perimeter methods, estimate whole building perimeter instead
    building_perimeter_estimated = envelope_data_hash[:building_exterior_wall_area]/(effective_number_of_stories_above_grade * envelope_data_hash[:floor_height])
    runner.registerValue('building_perimeter',building_perimeter_estimated,'m')
    building_perimeter_ip = OpenStudio.convert(building_perimeter_estimated, 'm', 'ft').get
    runner.registerInfo("Initial building average perimeter is #{OpenStudio.toNeatString(building_perimeter_ip,0,true)} (ft).")
    # runner.registerValue('building_perimeter',envelope_data_hash[:building_floor_area],'m')
    # building_perimeter_ip = OpenStudio.convert(envelope_data_hash[:building_perimeter], 'm', 'ft').get
    # runner.registerInfo("Initial building ground floor perimeter is #{OpenStudio.toNeatString(building_perimeter_ip,0,true)} (ft).")

    # report space type breakdown
    total_area_with_space_types = 0
    space_type_ratios = {}
    envelope_data_hash[:space_types].each do |space_type,hash|
      total_area_with_space_types += hash[:floor_area]
    end
    # loop through stories and report ratio and thermostat information
    envelope_data_hash[:space_types].each do |space_type,hash|
      space_type_ratio = hash[:floor_area]/total_area_with_space_types
      space_type_ratios[space_type] = space_type_ratio
    end
    space_type_ratios = space_type_ratios.sort_by{|k,v| v}.reverse
    space_type_ratios.each do |space_type,ratio|
      runner.registerInfo("#{ratio.round(3)} - Ratio of building floor area that is #{space_type.name}")
    end

    # report on thermostats
    htg_setpoint_ratios = {} # key is setpoint value is ratio
    clg_setpoint_ratios = {} # key is setpoint value is ratio
    htg_setpoints = {} # key is space type value is schedule
    clg_setpoints = {} # key is space type value is schedule
    space_type_ratios.each do |space_type,ratio|
      target_htg_setpoint_schedule = envelope_data_hash[:space_types][space_type][:htg_setpoint].key(envelope_data_hash[:space_types][space_type][:htg_setpoint].values.max)
      target_clg_setpoint_schedule = envelope_data_hash[:space_types][space_type][:clg_setpoint].key(envelope_data_hash[:space_types][space_type][:clg_setpoint].values.max)
      htg_setpoints[space_type] = target_htg_setpoint_schedule
      clg_setpoints[space_type] = target_clg_setpoint_schedule

      # skip if space type doesn't have heating and cooling thermostats
      if not target_htg_setpoint_schedule.nil? && target_clg_setpoint_schedule.nil?

        runner.registerInfo("Setpoint schedules for #{space_type.name} are #{target_htg_setpoint_schedule.name} for heating and #{target_clg_setpoint_schedule.name} for cooling.")
        if envelope_data_hash[:space_types][space_type][:htg_setpoint].size > 1
          runner.registerInfo(" * More than one heating setpoint schedule was used for zones with #{space_type.name}. Listed schedule was used over the largest floor area for this space type.")
        end
        if envelope_data_hash[:space_types][space_type][:clg_setpoint].size > 1
          runner.registerInfo(" * More than one cooling setpoint schedule was used for zones with #{space_type.name}. Listed schedule was used over the largest floor area for this space type.")
        end

        # update htg_setpoint_ratios and clg_setpoint_ratios
        if htg_setpoint_ratios.has_key?(target_htg_setpoint_schedule)
          htg_setpoint_ratios[target_htg_setpoint_schedule] += envelope_data_hash[:space_types][space_type][:htg_setpoint].values.max
        else
          htg_setpoint_ratios[target_htg_setpoint_schedule] = envelope_data_hash[:space_types][space_type][:htg_setpoint].values.max
        end
        if clg_setpoint_ratios.has_key?(target_clg_setpoint_schedule)
          clg_setpoint_ratios[target_clg_setpoint_schedule] += envelope_data_hash[:space_types][space_type][:clg_setpoint].values.max
        else
          clg_setpoint_ratios[target_clg_setpoint_schedule] = envelope_data_hash[:space_types][space_type][:clg_setpoint].values.max
        end

      else
        runner.registerInfo("Didn't find or assign heating and cooling thermostat for #{space_type.name}")
      end

    end

    # left these in for diagnostics if I want to see full contents of hashes
    #  puts envelope_data_hash
    #  envelope_data_hash[:space_types].each do |k,v|
    #   puts k.name
    #   puts v
    #  end
    #  envelope_data_hash[:stories].each do |k,v|
    #    puts v
    #  end

    # define length and with of bar
    if bar_calc_method == "Bar - Reduced Bounding Box"
      bar_calc = calc_bar_reduced_bounding_box(envelope_data_hash)
    elsif bar_calc_method == "Bar - Reduced Width"
      bar_calc = calc_bar_reduced_width(envelope_data_hash)
    elsif bar_calc_method == "Bar - Stretched"
      bar_calc = calc_bar_stretched(envelope_data_hash)
    end

    # populate bar_hash and create envelope with data from envelope_data_hash and user arguments
    bar_hash = {}
    bar_hash[:length] = bar_calc[:length]
    bar_hash[:width] = bar_calc[:width]
    bar_hash[:building_perimeter] = envelope_data_hash[:building_perimeter] # just using ground floor perimeter
    bar_hash[:num_stories] = envelope_data_hash[:effective__num_stories]
    bar_hash[:num_stories_below_grade] = envelope_data_hash[:effective_num_stories_below_grade]
    bar_hash[:num_stories_above_grade] = envelope_data_hash[:effective_num_stories_above_grade]
    bar_hash[:floor_height] = envelope_data_hash[:floor_height]
    center_x = (envelope_data_hash[:building_max_xyz][0] + envelope_data_hash[:building_min_xyz][0])/2.0
    center_y = (envelope_data_hash[:building_max_xyz][1] + envelope_data_hash[:building_min_xyz][1])/2.0
    center_z = envelope_data_hash[:building_min_xyz][2]
    bar_hash[:center_of_footprint] = OpenStudio::Point3d.new(center_x,center_y,center_z)
    bar_hash[:bar_division_method] = bar_division_method
    bar_hash[:space_types] = envelope_data_hash[:space_types]
    bar_hash[:building_wwr_n] = envelope_data_hash[:building_wwr_n]
    bar_hash[:building_wwr_s] = envelope_data_hash[:building_wwr_s]
    bar_hash[:building_wwr_e] = envelope_data_hash[:building_wwr_e]
    bar_hash[:building_wwr_w] = envelope_data_hash[:building_wwr_w]
    bar_hash[:stories] = envelope_data_hash[:stories]

    # remove exhaust from zones to re-apply to new zone after create_bar (for now not keeping zone mixing or zone ventilation design flow rate)
    # when using create_typical_model with this measure choose None for exhaust makeup air so don't have any dummy exhaust objects
    model.getFanZoneExhausts.each do |exhaust|
      exhaust.removeFromThermalZone
    end

    # remove non-resource objects
    remove_non_resource_objects(runner,model)

    # create bar
    create_bar(runner,model,bar_hash)

    # move exhaust from temp zone to large zone in new model
    zone_hash = {} #key is zone value is floor area. It excludes zones with non 1 multiplier
    model.getThermalZones.each do |thermal_zone|
      next if thermal_zone.multiplier > 1
      zone_hash[thermal_zone] = thermal_zone.floorArea
    end
    target_zone = zone_hash.key(zone_hash.values.max)
    model.getFanZoneExhausts.each do |exhaust|
      exhaust.addToThermalZone(target_zone)
    end

    # assign thermostats
    if htg_setpoint_ratios.size > 0 || clg_setpoint_ratios.size > 0
      if bar_division_method.include?("Single Space Type")

        mode_target_htg_setpoint_sch = htg_setpoint_ratios.key(htg_setpoint_ratios.values.max)
        mode_target_clg_setpoint_sch = clg_setpoint_ratios.key(clg_setpoint_ratios.values.max)
        new_thermostat = OpenStudio::Model::ThermostatSetpointDualSetpoint.new(model)
        new_thermostat.setHeatingSetpointTemperatureSchedule(mode_target_htg_setpoint_sch)
        new_thermostat.setCoolingSetpointTemperatureSchedule(mode_target_clg_setpoint_sch)
        runner.registerInfo("Assigning #{mode_target_htg_setpoint_sch.name} as heating setpoint schedule for all thermal zones.")
        runner.registerInfo("Assigning #{mode_target_clg_setpoint_sch.name} as cooling setpoint schedule for all thermal zones.")
        model.getThermalZones.each do |thermal_zone|
          thermal_zone.setThermostatSetpointDualSetpoint(new_thermostat)
        end

      else

        # restore thermostats for space type saved from old geometry
        model.getThermalZones.each do |thermal_zone|
          next if not thermal_zone.spaces.first.spaceType.is_initialized
          space_type = thermal_zone.spaces.first.spaceType.get
          new_thermostat = OpenStudio::Model::ThermostatSetpointDualSetpoint.new(model)
          new_thermostat.setHeatingSetpointTemperatureSchedule(htg_setpoints[space_type])
          new_thermostat.setCoolingSetpointTemperatureSchedule(clg_setpoints[space_type])
          thermal_zone.setThermostatSetpointDualSetpoint(new_thermostat)
        end

      end

    end

    # report final ratios
    final_floor_area = model.getBuilding.floorArea
    final_ratios = {}
    model.getSpaceTypes.each do |space_type|
      next if space_type.floorArea == 0.0
      final_ratios[space_type] = space_type.floorArea/final_floor_area
    end
    Hash[final_ratios.sort_by{|k, v| v}.reverse].each do |k,v|
      runner.registerInfo("#{v.round(3)} - Final Ratio for #{k.name}.")
    end

    # report final condition of model
    final_floor_area_ip = OpenStudio.convert(model.getBuilding.floorArea,'m^2','ft^2').get
    runner.registerFinalCondition("The building finished with #{model.getSpaces.size} spaces and a floor area of #{OpenStudio.toNeatString(final_floor_area_ip,0,true)}.")

    return true

  end
  
end

# register the measure to be used by the application
CreateBarFromModel.new.registerWithApplication
