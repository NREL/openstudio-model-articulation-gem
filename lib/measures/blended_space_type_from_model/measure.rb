# see the URL below for information on how to write OpenStudio measures
# http://nrel.github.io/OpenStudio-user-documentation/reference/measure_writing_guide/

# start the measure
class BlendedSpaceTypeFromModel < OpenStudio::Ruleset::ModelUserScript

  # require all .rb files in resources folder
  Dir[File.dirname(__FILE__) + '/resources/*.rb'].each {|file| require file }

  # contains code to blend space types
  include OsLib_ModelSimplification

  # human readable name
  def name
    return "Blended Space Type from Model"
  end

  # human readable description
  def description
    return "This measure will remove all space type assignemnts and hard assigned internal loads from spaces that are included in the building floor area. Spaces such as plenums and attics will be left alone. A blended space type will be created from the original internal loads and assigned at the building level. Thermostats, Service Water Heating, and HVAC systems will not be altered. Any constructions associated with space types will be hard assigned prior to the space type assignemnt being removed."
  end

  # human readable description of modeling approach
  def modeler_description
    return "The goal of this measure is to create a single space type that represents the loads and schedules of a collection of space types in a model. When possible the measure will create mulitple load instances of a specific type in the resulting blended space type. This allows the original schedules to be used, and can allow for down stream EE measures on specific internal loads. Design Ventilation Outdoor Air objects will have to be merged into a single object. Will try to maintain the load design type (power, per area, per person) when possible. Need to account for zone multipliers when createding blended internal loads. Also address what happens to daylighting control objets. Original space types will be left in the model, some may still be assigned to spaces not included in the building area."
  end

  # define the arguments that the user will input
  def arguments(model)
    args = OpenStudio::Ruleset::OSArgumentVector.new

    # make choice argument for blend_method
    choices = OpenStudio::StringVector.new
    choices << "Building Type"
    choices << "Building Story"
    choices << "Building"
    blend_method = OpenStudio::Ruleset::OSArgument::makeChoiceArgument("blend_method", choices,true)
    blend_method.setDisplayName("Blend Space Types that are part of the same")
    blend_method.setDefaultValue("Building")
    args << blend_method

    # any of these in the end will be an array of spaces.
    # if choose building types, spaces without space types or without standards space type info are ignored (or go to their own blend)
    # if choose building story spaces not on building story will be ignored or combined to its own space type.
    # Think about how to handle plenums and attics (this is for building type or building story)

    return args
  end

  # define what happens when the measure is run
  def run(model, runner, user_arguments)
    super(model, runner, user_arguments)

    # use the built-in error checking
    if !runner.validateUserArguments(arguments(model), user_arguments)
      return false
    end

    #assign the user inputs to variables
    blend_method = runner.getStringArgumentValue("blend_method",user_arguments)

    # divide the building up based on blend method
    space_type_hash = {}
    if blend_method == "Building Type"

      # loop through spaces and organize by building type
      model.getSpaceTypes.each do |space_type|

        # skip if not used
        next if space_type.floorArea == 0

        # skip if space_type isn't associated with standards building type
        if not space_type.standardsBuildingType.is_initialized
          runner.registerWarning("#{space_type.name} does not have a building type associated with it. Spaces using this space type will be ignored")
          next
        end

        # add space to array within space_type_hash
        building_type = space_type.standardsBuildingType.get
        if not space_type_hash.has_key?(building_type)
          space_type_hash[building_type] = []
        end
        space_type_hash[building_type] << space_type
      end

    elsif blend_method == "Building Story"

      # loop through building stories
      model.getBuildingStorys.sort.each do |story|

        # array of space types for this building story
        story_space_types = {} # key original space type, value is cloned space type

        # loop through spaces in story and gather and clone space types as needed
        story.spaces.each do |space|

          # skip if space isn't assigned to a space type
          if not space.spaceType.is_initialized
            runner.registerWarning("#{space.name} is not assigned to a space type, it will be ignored")
            next
          else
            space_type = space.spaceType.get
          end

          # skip if space_type isn't associated with standards building type
          if not space_type.standardsBuildingType.is_initialized
            runner.registerWarning("#{space_type.name} does not have a building type associated with it. #{space} which uses that space type will be ignored")
            next
          end

          # clone space first time used for each story
          if not story_space_types.include?(space_type)
            orig_name = space_type.name
            new_space_type = space_type.clone(model).to_SpaceType.get
            new_space_type.setName("#{orig_name} #{story.name}")
            story_space_types[space_type] = new_space_type
          end
          # re-assign space to clone of space type
          space.setSpaceType(story_space_types[space_type])

        end

        # populate space_type_hash
        space_type_hash[story.name] = story_space_types.values

      end

      # remove unused space_types (which includes original spaces types that were cloned for building stories as needed)
      model.getSpaceTypes.each do |space_type|
        if space_type.floorArea == 0
          space_type.remove
        end
      end

      # warn if spaces in model that are not on building story (re-assign to cloned space type)
      model.getSpaces.each do |space|
        next if space.buildingStory.is_initialized
        runner.registerWarning("#{space.name} is not assigned to a building story. It will be ignored.")
      end

    else
      space_type_hash[blend_method] = model.getSpaceTypes.sort
    end

    # report initial condition of model
    initial_cond_space_type_hash = {}
    model.getSpaceTypes.sort.each do |space_type|
      next if space_type.floorArea == 0
      floor_area_si = 0
      # loop through spaces so I can skip if not included in floor area
      space_type.spaces.each do |space|
        next if not space.partofTotalFloorArea
        floor_area_si += space.floorArea * space.multiplier
      end
      next if floor_area_si == 0
      initial_cond_space_type_hash[space_type] = floor_area_si
    end
    runner.registerInitialCondition("The initial building uses #{initial_cond_space_type_hash.size} spaces types.")

    # blend space types
    blend_space_type_collections(runner,model,space_type_hash)

    # report final condition of model
    # re-run same same code used for initial condition
    final_cond_space_type_hash = {}
    model.getSpaceTypes.sort.each do |space_type|
      next if space_type.floorArea == 0
      floor_area_si = 0
      # loop through spaces so I can skip if not included in floor area
      space_type.spaces.each do |space|
        next if not space.partofTotalFloorArea
        floor_area_si += space.floorArea * space.multiplier
      end
      next if floor_area_si == 0
      final_cond_space_type_hash[space_type] = floor_area_si
    end
    runner.registerFinalCondition("The final building uses #{final_cond_space_type_hash.size} spaces types.")

    return true

  end
  
end

# register the measure to be used by the application
BlendedSpaceTypeFromModel.new.registerWithApplication
