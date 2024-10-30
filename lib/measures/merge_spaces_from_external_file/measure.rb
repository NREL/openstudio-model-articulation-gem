# *******************************************************************************
# OpenStudio(R), Copyright (c) Alliance for Sustainable Energy, LLC.
# See also https://openstudio.net/license
# *******************************************************************************

# see the URL below for information on how to write OpenStudio measures
# http://nrel.github.io/OpenStudio-user-documentation/reference/measure_writing_guide/

# load openstudio-standards gem
require 'openstudio-standards'

require_relative 'resources/ScheduleTranslator'

# start the measure
class MergeSpacesFromExternalFile < OpenStudio::Measure::ModelMeasure
  # human readable name
  def name
    return 'Merge Spaces from External File'
  end

  # human readable description
  def description
    return 'The measure lets you merge the contents from spaces in an external file into spaces in your current model. Spaces are identifed by the space name being the same in the two models. If a space is in the current model but not the external model they will be deleted. If a space is in both models the selecd elments willl be udpated based on the external model. If a space is not in the current model but is in the external model it will be cloned into the current model.'
  end

  # human readable description of modeling approach
  def modeler_description
    return "A string argument is used to identify the external model that is being merged into the current model. user agrument determine which kind of objets are brought over from the external model. Some characteristics that can be merged are surfaces, shading surface groups, interior partition groups, daylight controls, and internal loads. Additionally thermal zone, space space type, building story, construction set, and schedule set assignments names will can taken from the space, but objets they represent won't be cloned if objects by that name already exist in the current model."
  end

  # define the arguments that the user will input
  def arguments(model)
    args = OpenStudio::Measure::OSArgumentVector.new

    # make an argument for external_model_name
    external_model_name = OpenStudio::Measure::OSArgument.makeStringArgument('external_model_name', true)
    external_model_name.setDisplayName('External OSM File Name')
    external_model_name.setDescription('Name of the model to merge into current model. This is the filename with the extension (e.g. MyModel.osm). Optionally this can inclucde the full file path, but for most use cases should just be file name.')
    args << external_model_name

    # merge geometry
    merge_geometry = OpenStudio::Measure::OSArgument.makeBoolArgument('merge_geometry', true)
    merge_geometry.setDisplayName('Merge Geometry from External Model')
    merge_geometry.setDescription('Replace geometry in current model with geometry from external model.')
    merge_geometry.setDefaultValue(true)
    args << merge_geometry

    # merge internal loads
    merge_loads = OpenStudio::Measure::OSArgument.makeBoolArgument('merge_loads', true)
    merge_loads.setDisplayName('Merge Internal Loads from External Model')
    merge_loads.setDescription('Replace internal loads directly assigned so spaces in current model with internal loads directly assigned to spaces frp, external model. If a schedule is hard assigned to a load instance, it will be brought over as well.')
    merge_loads.setDefaultValue(true)
    args << merge_loads

    # merge space attributes
    merge_attribute_names = OpenStudio::Measure::OSArgument.makeBoolArgument('merge_attribute_names', true)
    merge_attribute_names.setDisplayName('Merge Space Attribute names from External Model')
    merge_attribute_names.setDescription('Replace space attribute names in current model with space attribute names from external models. When external model has unkown attribute name that object will be cloned into the current model.')
    merge_attribute_names.setDefaultValue(true)
    args << merge_attribute_names

    # add_spaces
    add_spaces = OpenStudio::Measure::OSArgument.makeBoolArgument('add_spaces', true)
    add_spaces.setDisplayName('Add Spaces to Current Model')
    add_spaces.setDescription('Add spaces to current model that exist in external model but do not exist in current model.')
    add_spaces.setDefaultValue(true)
    args << add_spaces

    # remove_spaces
    remove_spaces = OpenStudio::Measure::OSArgument.makeBoolArgument('remove_spaces', true)
    remove_spaces.setDisplayName('Remove Spaces from Current Model')
    remove_spaces.setDescription('Remove spaces from current model that do not exist in externa model.')
    remove_spaces.setDefaultValue(true)
    args << remove_spaces

    # merge schedules
    # doesn't bring in schedules from external model that are not used in current model, this measures isn't mean to load in resources that are not used
    merge_schedules = OpenStudio::Measure::OSArgument.makeBoolArgument('merge_schedules', true)
    merge_schedules.setDisplayName('Merge Schedules from External Model')
    merge_schedules.setDescription("This isn't limited to spaces, this will replace any scheules in the current model with schedules of the same name in the external model. It will not replace schedule named 'a' from an internal load in th emodel with a schedule named 'b' from an internal load by that same name in the external model, to perform that task currently, you must merge loads.")
    merge_schedules.setDefaultValue(true)
    args << merge_schedules

    # convert compact to ruleset
    compact_to_ruleset = OpenStudio::Measure::OSArgument.makeBoolArgument('compact_to_ruleset', true)
    compact_to_ruleset.setDisplayName('Convert Merged Schedule Compact objects to Schedule Ruleset.')
    compact_to_ruleset.setDescription('Will convert any imported schedules to Schedule Ruleset instead of Schedule Compact and will connect them to objects that had previously refered to the Schedule Compact object.')
    compact_to_ruleset.setDefaultValue(true)
    args << compact_to_ruleset

    # TODO: - in future have arg for logic when resource objects exist in both models
    # (constructions, materials for geometry, and schedule and load defs for internal loads)

    return args
  end

  def remove_space_loads(space)
    # remove loads from target space
    space.internalMass.each(&:remove)
    space.people.each(&:remove)
    space.lights.each(&:remove)
    space.luminaires.each(&:remove)
    space.electricEquipment.each(&:remove)
    space.gasEquipment.each(&:remove)
    space.hotWaterEquipment.each(&:remove)
    space.steamEquipment.each(&:remove)
    space.otherEquipment.each(&:remove)
    space.spaceInfiltrationDesignFlowRates.each(&:remove)
    space.spaceInfiltrationEffectiveLeakageAreas.each(&:remove)
    space.resetDesignSpecificationOutdoorAir
  end

  def reassign_loads(target_space, source_space)
    # re-assign loads from source space to target space
    source_space.internalMass.each { |instance| instance.setSpace(target_space) }
    source_space.people.each { |instance| instance.setSpace(target_space) }
    source_space.lights.each { |instance| instance.setSpace(target_space) }
    source_space.luminaires.each { |instance| instance.setSpace(target_space) }
    source_space.electricEquipment.each { |instance| instance.setSpace(target_space) }
    source_space.gasEquipment.each { |instance| instance.setSpace(target_space) }
    source_space.hotWaterEquipment.each { |instance| instance.setSpace(target_space) }
    source_space.steamEquipment.each { |instance| instance.setSpace(target_space) }
    source_space.otherEquipment.each { |instance| instance.setSpace(target_space) }
    source_space.spaceInfiltrationDesignFlowRates.each { |instance| instance.setSpace(target_space) }
    source_space.spaceInfiltrationEffectiveLeakageAreas.each { |instance| instance.setSpace(target_space) }
    target_space.setDesignSpecificationOutdoorAir(source_space.designSpecificationOutdoorAir.get)
  end

  def remove_space_attributes(space)
    space.resetSpaceType
    space.resetThermalZone
    space.resetBuildingStory
    space.resetDefaultConstructionSet
    space.resetDefaultScheduleSet
  end

  # don't clone object if it already exists in the model
  # todo see if space type of that name already exist in the model, if then clone in the requested on
  def reassign_space_attributes(target_space, source_space_hash, model)
    # re-assign space types
    if source_space_hash[:space_type].is_initialized
      target_space_type = source_space_hash[:space_type].get
      if !(model.getModelObjectByName(target_space_type.name.get).is_initialized && model.getModelObjectByName(target_space_type.name.get).get.to_SpaceType.is_initialized)
        # clone object
        target_space_type = source_space_hash[:space_type].get.clone(model).to_SpaceType.get
      end
      target_space.setSpaceType(target_space_type)
    else
      target_space.resetSpaceType
    end

    # re-assign thermal zones
    if source_space_hash[:thermal_zone].is_initialized
      target_zone = source_space_hash[:thermal_zone].get
      if !(model.getModelObjectByName(target_zone.name.get).is_initialized && model.getModelObjectByName(target_zone.name.get).get.to_ThermalZone.is_initialized)
        # clone object
        target_zone = source_space_hash[:thermal_zone].get.clone(model).to_ThermalZone.get
      end
      target_space.setThermalZone(target_zone)
    else
      target_space.resetThermalZone
    end

    # re-assign building story
    if source_space_hash[:building_story].is_initialized
      target_building_story = source_space_hash[:building_story].get
      if !(model.getModelObjectByName(target_building_story.name.get).is_initialized && model.getModelObjectByName(target_building_story.name.get).get.to_BuildingStory.is_initialized)
        # clone object
        target_building_story = source_space_hash[:building_story].get.clone(model).to_BuildingStory.get
      end
      target_space.setBuildingStory(target_building_story)
    else
      target_space.resetBuildingStory
    end

    # re-assign construction set
    if source_space_hash[:const_set].is_initialized
      target_const_set = source_space_hash[:const_set].get
      if !(model.getModelObjectByName(target_const_set.name.get).is_initialized && model.getModelObjectByName(target_const_set.name.get).get.to_DefaultConstructionSet.is_initialized)
        # clone object
        target_const_set = source_space_hash[:const_set].get.clone(model).to_DefaultConstructionSet.get
      end
      target_space.setDefaultConstructionSet(target_const_set)
    else
      target_space.resetDefaultConstructionSet
    end

    # re-assign schedule set
    if source_space_hash[:sch_set].is_initialized
      target_schedule_set = source_space_hash[:sch_set].get
      if !(model.getModelObjectByName(target_schedule_set.name.get).is_initialized && model.getModelObjectByName(target_schedule_set.name.get).get.to_DefaultScheduleSet.is_initialized)
        # clone object
        target_schedule_set = source_space_hash[:sch_set].get.clone(model).to_DefaultScheduleSet.get
      end
      target_space.setDefaultConstructionSet(target_schedule_set)
    else
      target_space.resetDefaultConstructionSet
    end
  end

  # define what happens when the measure is run
  def run(model, runner, user_arguments)
    super(model, runner, user_arguments)

    if !runner.validateUserArguments(arguments(model), user_arguments)
      return false
    end

    # assign the user inputs to variables
    args = runner.getArgumentValues(arguments(model), user_arguments)
    args = Hash[args.collect{ |k, v| [k.to_s, v] }]
    if !args then return false end

    # initial condition
    runner.registerInitialCondition("The model started with #{model.getSpaces.size} spaces.")

    if args['merge_geometry'] == false && args['merge_loads'] == false && args['merge_attribute_names'] == false && args['merge_schedules'] == false
      runner.registerAsNotApplicable('No change made in model')
      return true
    end

    # create hash of spaces in current model
    current_spaces_hash = {}
    model.getSpaces.sort.each do |space|
      hash = {}

      # populate space attributes
      hash[:space_type] = space.spaceType
      hash[:thermal_zone] = space.thermalZone
      hash[:building_story] = space.buildingStory
      hash[:const_set] = space.defaultConstructionSet
      hash[:sch_set] = space.defaultScheduleSet

      # populate internal laods
      hash[:int_mass] = space.internalMass
      hash[:people] = space.people
      hash[:lights] = space.lights
      hash[:luminaires] = space.luminaires
      hash[:elec_equip] = space.electricEquipment
      hash[:hot_water_equip] = space.hotWaterEquipment
      hash[:steam_equip] = space.steamEquipment
      hash[:other_equip] = space.otherEquipment
      hash[:infil] = space.spaceInfiltrationDesignFlowRates
      hash[:infil_leakage] = space.spaceInfiltrationEffectiveLeakageAreas
      hash[:oa] = space.designSpecificationOutdoorAir

      # store space object itself
      hash[:space] = space

      # add to main hash
      current_spaces_hash[space.name.get.to_s] = hash
    end

    # find external model
    osw_file = runner.workflow.findFile(args['external_model_name'])
    if osw_file.is_initialized
      osmPath_2 = osw_file.get.to_s
    else
      runner.registerError("Did not find #{args['external_model_name']} in paths described in OSW file.")
      return false
    end

    # Open OSM file
    model_2 = OpenStudio::Model::Model.load(OpenStudio::Path.new(osmPath_2)).get
    runner.registerInfo("#{args['osm_file_name']} has #{model_2.getSpaces.size} spaces")

    # create hash of spaces in external model
    external_spaces_hash = {}
    model_2.getSpaces.sort.each do |space|
      hash = {}

      # populate space attributes
      hash[:space_type] = space.spaceType
      hash[:thermal_zone] = space.thermalZone
      hash[:building_story] = space.buildingStory
      hash[:const_set] = space.defaultConstructionSet
      hash[:sch_set] = space.defaultScheduleSet

      # populate internal laods
      hash[:int_mass] = space.internalMass
      hash[:people] = space.people
      hash[:lights] = space.lights
      hash[:luminaires] = space.luminaires
      hash[:elec_equip] = space.electricEquipment
      hash[:hot_water_equip] = space.hotWaterEquipment
      hash[:steam_equip] = space.steamEquipment
      hash[:other_equip] = space.otherEquipment
      hash[:infil] = space.spaceInfiltrationDesignFlowRates
      hash[:infil_leakage] = space.spaceInfiltrationEffectiveLeakageAreas
      hash[:oa] = space.designSpecificationOutdoorAir

      # store space object itself
      hash[:space] = space

      # add to main hash
      external_spaces_hash[space.name.get.to_s] = hash
    end

    # look for matching space names
    external_spaces_hash.each do |space_name, hash|
      if current_spaces_hash.key?(space_name)
        runner.registerInfo("Merging #{space_name} from external model to current model")

        if args['merge_geometry']
          # rename current space
          current_spaces_hash[space_name][:space].setName('to be deleted')

          # remove loads before cloning if they will not be used
          if !(args['merge_loads'])
            remove_space_loads(hash[:space])
          end
          # remove space attributes before cloning if they will not be used
          if !(args['merge_attribute_names'])
            remove_space_attributes(hash[:space])
          end
          final_space = hash[:space].clone(model).to_Space.get
        else
          final_space = current_spaces_hash[space_name][:space]
          # remove loads before if they will not be used
          if args['merge_loads']
            remove_space_loads(final_space)
          end
          # remove space attributes if they will not be used
          if args['merge_attribute_names']
            remove_space_attributes(final_space)
          end
        end

        # merge internal loads if requested
        if args['merge_loads'] && args['merge_geometry']
          # nothing to do, correct loads are already with space cloned from external model
        elsif args['merge_loads'] == false && args['merge_geometry'] == false
          # nothing to do, correct loads are already with space from current model, nothing brought in from external model
        elsif args['merge_loads'] && args['merge_geometry'] == false
          # clone in and reassign load instances from external model
          temp_space = hash[:space].clone(model).to_Space.get
          reassign_loads(final_space, temp_space)
          temp_space.remove
        elsif args['merge_loads'] == false && args['merge_geometry']
          # reassign load instances from external model
          reassign_loads(final_space, current_spaces_hash[space_name][:space])
        end

        # merge space attribute names if requested
        if args['merge_attribute_names'] && args['merge_geometry']
          # remap attributes
          reassign_space_attributes(final_space, hash, model)
        elsif args['merge_attribute_names'] == false && args['merge_geometry'] == false
          # nothing to do, correct attributes are already with space from current model, nothing brought in from external model
        elsif args['merge_attribute_names'] && args['merge_geometry'] == false
          # re-assign attributes based on names in external space hash. If object of correct name is not found in current model then clone object from external model
          reassign_space_attributes(final_space, hash, model)
        elsif args['merge_attribute_names'] == false && args['merge_geometry']
          # re-assign attribute names back to what was used in current model space
          reassign_space_attributes(final_space, current_spaces_hash[space_name], model)
        end

        # remove current space if replacement geometry was cloned from external model
        if args['merge_geometry']
          current_spaces_hash[space_name][:space].remove
        end

      elsif args['add_spaces']
        # clone space into model
        new_space_from_ext = hash[:space].clone(model).to_Space.get
        reassign_space_attributes(new_space_from_ext, hash, model)
        runner.registerInfo("Adding #{space_name} from external model to current model. Since it doesn't exist in current model bring in all characteristics reguardless of user argument values.")
      end
    end

    # remove spaces in current model that are not in external model
    current_spaces_hash.each do |space_name, hash|
      if !external_spaces_hash.key?(space_name) && args['remove_spaces']
        hash[:space].remove
        runner.registerInfo("Removing #{space_name} from current model, since it doesn't exist in external model.")
      end
    end

    if args['merge_geometry']
      # put all of the spaces in the model into a vector
      spaces = OpenStudio::Model::SpaceVector.new
      model.getSpaces.each do |space|
        spaces << space
      end

      # match surfaces for each space in the vector
      OpenStudio::Model.matchSurfaces(spaces)
      runner.registerInfo('Matching surfaces..')
    end

    if args['merge_schedules']
      model_2.getSchedules.each do |schedule|
        # swap schedule if it is already in the model
        if model.getScheduleByName(schedule.name.get).is_initialized

          # store name and get schedule
          orig_name = schedule.name.get
          schedule_old = model.getScheduleByName(schedule.name.get).get

          # if schedule is compact convert it to ruleset and clone
          if args['compact_to_ruleset'] && schedule.to_ScheduleCompact.is_initialized
            sch_translator = ScheduleTranslator.new(model_2, schedule)
            os_sch = sch_translator.translate
            cloned_schedule = os_sch.clone(model).to_Schedule.get
          else
            cloned_schedule = schedule.clone(model).to_Schedule.get
          end

          # replace uses of schedule, model.swap(compact,os_sch) doesn't work
          schedule_old.sources.each do |source|
            source_index = source.getSourceIndices(schedule_old.handle)
            source_index.each do |field|
              source.setPointer(field, cloned_schedule.handle)
            end
          end
          schedule_old.remove
          cloned_schedule.setName(orig_name)

        end
      end
    end

    # register final condition
    runner.registerFinalCondition("The model finished with #{model.getSpaces.size} spaces.")

    return true
  end
end

# register the measure to be used by the application
MergeSpacesFromExternalFile.new.registerWithApplication
