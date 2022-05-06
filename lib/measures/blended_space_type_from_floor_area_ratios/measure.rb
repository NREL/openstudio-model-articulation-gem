# *******************************************************************************
# OpenStudio(R), Copyright (c) 2008-2021, Alliance for Sustainable Energy, LLC.
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

require 'openstudio-standards'

# load OpenStudio measure libraries from openstudio-extension gem
require 'openstudio-extension'
require 'openstudio/extension/core/os_lib_helper_methods'
require 'openstudio/extension/core/os_lib_model_generation'
require 'openstudio/extension/core/os_lib_model_simplification'

# start the measure
class BlendedSpaceTypeFromFloorAreaRatios < OpenStudio::Measure::ModelMeasure
  # resource file modules
  include OsLib_HelperMethods
  include OsLib_ModelGeneration
  include OsLib_ModelSimplification

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
    space_type_standards_info_hash = OsLib_HelperMethods.getSpaceTypeStandardsInformation(model.getSpaceTypes)

    # lookup ratios
    space_type_hash = get_space_types_from_building_type(building_type, template, true)
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
    blended_space_type = blend_space_types_from_floor_area_ratio(runner, model, space_types_to_blend_hash)
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
