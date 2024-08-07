# *******************************************************************************
# OpenStudio(R), Copyright (c) Alliance for Sustainable Energy, LLC.
# See also https://openstudio.net/license
# *******************************************************************************

# see the URL below for information on how to write OpenStudio measures
# http://nrel.github.io/OpenStudio-user-documentation/reference/measure_writing_guide/

require 'openstudio-standards'

# start the measure
class BlendedSpaceTypeFromFloorAreaRatios < OpenStudio::Measure::ModelMeasure

  # human readable name
  def name
    return 'Blended Space Type from Floor Area Ratios'
  end

  # human readable description
  def description
    return 'This measure will take a string argument describing the space type ratios, for space types already in the model. There is also an argument to set the new blended space type as the default space type for the building. The space types refererenced by this argument should already exist in the model.'
  end

  # human readable description of modeling approach
  def modeler_description
    return 'To determine default ratio look at the building type, and try to infer template (from building name) and set default ratios saved in the resources folder.'
  end

  # gather standards info for space type array
  def getSpaceTypeStandardsInformation(spaceTypeArray)
    # hash of space types
    spaceTypeStandardsInfoHash = {}

    spaceTypeArray.each do |spaceType|
      # get standards building
      if !spaceType.standardsBuildingType.empty?
        standardsBuilding = spaceType.standardsBuildingType.get
      else
        standardsBuilding = nil
      end

      # get standards space type
      if !spaceType.standardsSpaceType.empty?
        standardsSpaceType = spaceType.standardsSpaceType.get
      else
        standardsSpaceType = nil
      end

      # populate hash
      spaceTypeStandardsInfoHash[spaceType] = [standardsBuilding, standardsSpaceType]
    end

    return spaceTypeStandardsInfoHash
  end

  # define the arguments that the user will input
  def arguments(model)
    args = OpenStudio::Measure::OSArgumentVector.new

    # get building type, floor area, and name
    if model.getBuilding.standardsBuildingType.is_initialized
      building_type = model.getBuilding.standardsBuildingType.get
    else
      building_type = 'Unknown'
    end

    building_area = model.getBuilding.floorArea
    building_name = model.getBuilding.name

    # map office to small medium or large.
    if building_type == 'Office'
      if building_name.get.include?('SmallOffice')
        building_type = 'SmallOffice'
      elsif building_name.get.include?('LargeOffice')
        building_type = 'LargeOffice'
      elsif building_name.get.include?('MediumOffice')
        building_type = 'MediumOffice'
      else
        # TODO: - use building area as backup to building name
        building_type = 'MediumOffice'
      end
    end

    # map Apartment to MidriseApartment or HighriseApartment
    if building_type == 'Apartment'
      if building_name.get.include?('MidriseApartment')
        building_type = 'MidriseApartment'
      elsif building_name.get.include?('HighriseApartment')
        building_type = 'HighriseApartment'
      else
        # TODO: - use building area as backup to building name
        building_type = 'MidriseApartment'
      end
    end

    # map Retail
    if building_type == 'Retail'
      building_type = 'RetailStandalone'
    end
    if building_type == 'StripMall'
      building_type = 'RetailStandalone'
    end

    # infer template
    if building_name.get.include?('DOE Ref Pre-1980')
      template = 'DOE Ref Pre-1980'
    elsif building_name.get.include?('DOE Ref 1980-2004')
      template = 'DOE Ref 1980-2004'
    elsif building_name.get.include?('90.1-2004')
      template = '90.1-2004'
    elsif building_name.get.include?('90.1-2007')
      template = '90.1-2007'
    elsif building_name.get.include?('90.1-2010')
      template = '90.1-2010'
    elsif building_name.get.include?('90.1-2013')
      template = '90.1-2013'
    else
      # assume 2013 if can't infer from name
      template = '90.1-2013'
    end
    
    # get standards info for existing space types
    space_type_standards_info_hash = getSpaceTypeStandardsInformation(model.getSpaceTypes)

    # lookup ratios
    space_type_hash = OpenstudioStandards::CreateTypical.get_space_types_from_building_type(building_type) #just 1 instead of 4 args
    if space_type_hash == false
      default_string = 'Attempt to automatically generate space type ratio string failed, enter manually.'
    else
      default_string_array = []
      space_type_hash.each do |space_type_standards_name, hash|
        # find name of first spcce type with this standards info and add to string
        space_type_standards_info_hash.each do |space_type, standards_info|
          # TODO: - also confirm building type (can't use adjusted building type)
          if standards_info[1] == space_type_standards_name
            default_string_array << "\'#{space_type.name.get}\' => #{hash[:ratio]}"
          end
        end
      end
      default_string = default_string_array.join(',')
    end

    # create space type ratio string input with default value based on building type and infered template
    space_type_ratio_string = OpenStudio::Measure::OSArgument.makeStringArgument('space_type_ratio_string', true)
    space_type_ratio_string.setDisplayName('Space Type Ratio String.')
    space_type_ratio_string.setDescription("\'Space Type A\' => ratio,\'Space Type B,ratio\', etc.")
    space_type_ratio_string.setDefaultValue(default_string)
    args << space_type_ratio_string

    # bool argument to set building default space type
    set_default_space_type = OpenStudio::Measure::OSArgument.makeBoolArgument('set_default_space_type', true)
    set_default_space_type.setDisplayName('Set Default Space Type using Blended Space Type.')
    set_default_space_type.setDefaultValue(true)
    args << set_default_space_type

    return args
  end

  # define what happens when the measure is run
  def run(model, runner, user_arguments)
    super(model, runner, user_arguments)

    # use the built-in error checking
    if !runner.validateUserArguments(arguments(model), user_arguments)
      return false
    end

    # get arguments
    space_type_ratio_string = runner.getStringArgumentValue('space_type_ratio_string', user_arguments)
    set_default_space_type = runner.getBoolArgumentValue('set_default_space_type', user_arguments)

    # report initial condition of model
    runner.registerInitialCondition("The initial building used #{model.getSpaceTypes.size} space types.")

    # make hash of out string arguemnt in eval. Rescue if can't be made into hash
    begin
      space_type_ratio_hash = eval("{#{space_type_ratio_string}}")
    rescue SyntaxError => e
      runner.registerError("{#{space_type_ratio_string}} could not be converted to a hash.")
      return false
    end

    # loop through space types and add to blend
    space_types_to_blend_hash = {}
    model.getSpaceTypes.each do |space_type|
      if space_type_ratio_hash.key?(space_type.name.get)
        # create hash with space type object as key and ratio as has
        floor_area_ratio = space_type_ratio_hash[space_type.name.get]
        space_types_to_blend_hash[space_type] = { floor_area_ratio: floor_area_ratio }
      end
    end

    # run method to create blended space type
    blended_space_type = OpenstudioStandards::CreateTypical.blend_space_types_from_floor_area_ratio(model, space_types_to_blend_hash)
    if blended_space_type.nil?
      return false
    end

    # set default if requested
    if set_default_space_type
      model.getBuilding.setSpaceType(blended_space_type)
      runner.registerInfo("Setting default space type for building to #{blended_space_type.name.get}")

      # remove all space type assignments, except for spaces not included in building area.
      model.getSpaces.each do |space|
        next if !space.partofTotalFloorArea

        space.resetSpaceType
      end
    end

    # report final condition of model
    runner.registerFinalCondition("The final building uses #{model.getSpaceTypes.size} spaces types.")

    return true
  end
end

# register the measure to be used by the application
BlendedSpaceTypeFromFloorAreaRatios.new.registerWithApplication
