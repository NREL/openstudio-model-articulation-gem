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
# http://openstudio.nrel.gov/openstudio-measure-writing-guide

# see the URL below for information on using life cycle cost objects in OpenStudio
# http://openstudio.nrel.gov/openstudio-life-cycle-examples

# see the URL below for access to C++ documentation on model objects (click on "model" in the main window to view model objects)
# http://openstudio.nrel.gov/sites/openstudio.nrel.gov/files/nv_data/cpp_documentation_it/model/html/namespaces.html

# start the measure
class BarAspectRatioStudy < OpenStudio::Measure::ModelMeasure
  # define the name that a user will see, this method may be deprecated as
  # the display name in PAT comes from the name field in measure.xml
  def name
    return 'Bar Aspect Ratio Study'
  end

  # define the arguments that the user will input
  def arguments(model)
    args = OpenStudio::Measure::OSArgumentVector.new

    # make an argument for total floor area
    total_bldg_area_ip = OpenStudio::Measure::OSArgument.makeDoubleArgument('total_bldg_area_ip', true)
    total_bldg_area_ip.setDisplayName('Total Building Floor Area')
    total_bldg_area_ip.setUnits('ft^2')
    total_bldg_area_ip.setDefaultValue(10000.0)
    args << total_bldg_area_ip

    # make an argument for aspect ratio
    ns_to_ew_ratio = OpenStudio::Measure::OSArgument.makeDoubleArgument('ns_to_ew_ratio', true)
    ns_to_ew_ratio.setDisplayName('Ratio of North/South Facade Length Relative to East/West Facade Length.')
    ns_to_ew_ratio.setDefaultValue(2.0)
    args << ns_to_ew_ratio

    # make an argument for number of floors
    num_floors = OpenStudio::Measure::OSArgument.makeIntegerArgument('num_floors', true)
    num_floors.setDisplayName('Number of Floors.')
    num_floors.setDefaultValue(2)
    args << num_floors

    # make an argument for floor height
    floor_to_floor_height_ip = OpenStudio::Measure::OSArgument.makeDoubleArgument('floor_to_floor_height_ip', true)
    floor_to_floor_height_ip.setDisplayName('Floor to Floor Height')
    floor_to_floor_height_ip.setUnits('ft')
    floor_to_floor_height_ip.setDefaultValue(10.0)
    args << floor_to_floor_height_ip

    # make an argument to surface match
    surface_matching = OpenStudio::Measure::OSArgument.makeBoolArgument('surface_matching', true)
    surface_matching.setDisplayName('Surface Matching?')
    surface_matching.setDefaultValue(true)
    args << surface_matching

    # make an argument to create zones from spaces
    make_zones = OpenStudio::Measure::OSArgument.makeBoolArgument('make_zones', true)
    make_zones.setDisplayName('Make Thermal Zones from Spaces?')
    make_zones.setDefaultValue(true)
    args << make_zones

    return args
  end

  # define what happens when the measure is run
  def run(model, runner, user_arguments)
    super(model, runner, user_arguments)

    # use the built-in error checking
    if !runner.validateUserArguments(arguments(model), user_arguments)
      return false
    end

    # assign the user inputs to variables
    total_bldg_area_ip = runner.getDoubleArgumentValue('total_bldg_area_ip', user_arguments)
    ns_to_ew_ratio = runner.getDoubleArgumentValue('ns_to_ew_ratio', user_arguments)
    num_floors = runner.getIntegerArgumentValue('num_floors', user_arguments)
    floor_to_floor_height_ip = runner.getDoubleArgumentValue('floor_to_floor_height_ip', user_arguments)
    surface_matching = runner.getBoolArgumentValue('surface_matching', user_arguments)
    make_zones = runner.getBoolArgumentValue('make_zones', user_arguments)

    # test for positive inputs
    if total_bldg_area_ip <= 0
      runner.registerError('Enter a total building area greater than 0.')
    end
    if ns_to_ew_ratio <= 0
      runner.registerError('Enter ratio grater than 0.')
    end
    if num_floors <= 0
      runner.registerError('Enter a number of stories 1 or greater.')
    end
    if floor_to_floor_height_ip <= 0
      runner.registerError('Enter a positive floor height.')
    end

    # helper to make numbers pretty (converts 4125001.25641 to 4,125,001.26 or 4,125,001). The definition be called through this measure.
    def neat_numbers(number, roundto = 2) # round to 0 or 2)
      if roundto == 2
        number = format '%.2f', number
      else
        number = number.round
      end
      # regex to add commas
      number.to_s.reverse.gsub(/([0-9]{3}(?=([0-9])))/, '\\1,').reverse
    end

    # helper to make it easier to do unit conversions on the fly.  The definition be called through this measure.
    def unit_helper(number, from_unit_string, to_unit_string)
      converted_number = OpenStudio.convert(OpenStudio::Quantity.new(number, OpenStudio.createUnit(from_unit_string).get), OpenStudio.createUnit(to_unit_string).get).get.value
    end

    # calculate needed variables
    footprint_ip = total_bldg_area_ip / num_floors
    footprint_si = unit_helper(footprint_ip, 'ft^2', 'm^2')
    floor_to_floor_height = unit_helper(floor_to_floor_height_ip, 'ft', 'm')

    # variables from original rectangle script not exposed in this measure
    width = Math.sqrt(footprint_si / ns_to_ew_ratio)
    length = footprint_si / width
    plenum_height = 0 # this doesn't look like it is used anywhere

    # determine if core and perimeter zoning can be used
    if (length > 10) && (width > 10)
      perimeter_zone_depth = 4.57 # hard coded in meters
    else
      perimeter_zone_depth = 0 # if any size is to small then just model floor as single zone, issue warning
      runner.registerWarning('Due to the size of the building modeling each floor as a single zone.')
    end

    # reporting initial condition of model
    starting_spaces = model.getSpaces
    runner.registerInitialCondition("The building started with #{starting_spaces.size} spaces.")

    # Loop through the number of floors
    for floor in (0..num_floors - 1)

      z = floor_to_floor_height * floor

      # Create a new story within the building
      story = OpenStudio::Model::BuildingStory.new(model)
      story.setNominalFloortoFloorHeight(floor_to_floor_height)
      story.setName("Story #{floor + 1}")

      nw_point = OpenStudio::Point3d.new(0, width, z)
      ne_point = OpenStudio::Point3d.new(length, width, z)
      se_point = OpenStudio::Point3d.new(length, 0, z)
      sw_point = OpenStudio::Point3d.new(0, 0, z)

      # Identity matrix for setting space origins
      m = OpenStudio::Matrix.new(4, 4, 0)
      m[0, 0] = 1
      m[1, 1] = 1
      m[2, 2] = 1
      m[3, 3] = 1

      # Define polygons for a rectangular building
      if perimeter_zone_depth > 0
        perimeter_nw_point = nw_point + OpenStudio::Vector3d.new(perimeter_zone_depth, -perimeter_zone_depth, 0)
        perimeter_ne_point = ne_point + OpenStudio::Vector3d.new(-perimeter_zone_depth, -perimeter_zone_depth, 0)
        perimeter_se_point = se_point + OpenStudio::Vector3d.new(-perimeter_zone_depth, perimeter_zone_depth, 0)
        perimeter_sw_point = sw_point + OpenStudio::Vector3d.new(perimeter_zone_depth, perimeter_zone_depth, 0)

        west_polygon = OpenStudio::Point3dVector.new
        west_polygon << sw_point
        west_polygon << nw_point
        west_polygon << perimeter_nw_point
        west_polygon << perimeter_sw_point
        west_space = OpenStudio::Model::Space.fromFloorPrint(west_polygon, floor_to_floor_height, model)
        west_space = west_space.get
        m[0, 3] = sw_point.x
        m[1, 3] = sw_point.y
        m[2, 3] = sw_point.z
        west_space.changeTransformation(OpenStudio::Transformation.new(m))
        west_space.setBuildingStory(story)
        west_space.setName("Story #{floor + 1} West Perimeter Space")

        north_polygon = OpenStudio::Point3dVector.new
        north_polygon << nw_point
        north_polygon << ne_point
        north_polygon << perimeter_ne_point
        north_polygon << perimeter_nw_point
        north_space = OpenStudio::Model::Space.fromFloorPrint(north_polygon, floor_to_floor_height, model)
        north_space = north_space.get
        m[0, 3] = perimeter_nw_point.x
        m[1, 3] = perimeter_nw_point.y
        m[2, 3] = perimeter_nw_point.z
        north_space.changeTransformation(OpenStudio::Transformation.new(m))
        north_space.setBuildingStory(story)
        north_space.setName("Story #{floor + 1} North Perimeter Space")

        east_polygon = OpenStudio::Point3dVector.new
        east_polygon << ne_point
        east_polygon << se_point
        east_polygon << perimeter_se_point
        east_polygon << perimeter_ne_point
        east_space = OpenStudio::Model::Space.fromFloorPrint(east_polygon, floor_to_floor_height, model)
        east_space = east_space.get
        m[0, 3] = perimeter_se_point.x
        m[1, 3] = perimeter_se_point.y
        m[2, 3] = perimeter_se_point.z
        east_space.changeTransformation(OpenStudio::Transformation.new(m))
        east_space.setBuildingStory(story)
        east_space.setName("Story #{floor + 1} East Perimeter Space")

        south_polygon = OpenStudio::Point3dVector.new
        south_polygon << se_point
        south_polygon << sw_point
        south_polygon << perimeter_sw_point
        south_polygon << perimeter_se_point
        south_space = OpenStudio::Model::Space.fromFloorPrint(south_polygon, floor_to_floor_height, model)
        south_space = south_space.get
        m[0, 3] = sw_point.x
        m[1, 3] = sw_point.y
        m[2, 3] = sw_point.z
        south_space.changeTransformation(OpenStudio::Transformation.new(m))
        south_space.setBuildingStory(story)
        south_space.setName("Story #{floor + 1} South Perimeter Space")

        core_polygon = OpenStudio::Point3dVector.new
        core_polygon << perimeter_sw_point
        core_polygon << perimeter_nw_point
        core_polygon << perimeter_ne_point
        core_polygon << perimeter_se_point
        core_space = OpenStudio::Model::Space.fromFloorPrint(core_polygon, floor_to_floor_height, model)
        core_space = core_space.get
        m[0, 3] = perimeter_sw_point.x
        m[1, 3] = perimeter_sw_point.y
        m[2, 3] = perimeter_sw_point.z
        core_space.changeTransformation(OpenStudio::Transformation.new(m))
        core_space.setBuildingStory(story)
        core_space.setName("Story #{floor + 1} Core Space")

        # Minimal zones
      else
        core_polygon = OpenStudio::Point3dVector.new
        core_polygon << sw_point
        core_polygon << nw_point
        core_polygon << ne_point
        core_polygon << se_point
        core_space = OpenStudio::Model::Space.fromFloorPrint(core_polygon, floor_to_floor_height, model)
        core_space = core_space.get
        m[0, 3] = sw_point.x
        m[1, 3] = sw_point.y
        m[2, 3] = sw_point.z
        core_space.changeTransformation(OpenStudio::Transformation.new(m))
        core_space.setBuildingStory(story)
        core_space.setName("Story #{floor + 1} Core Space")

      end

      # Set vertical story position
      story.setNominalZCoordinate(z)

    end

    # put all of the spaces in the model into a vector
    spaces = OpenStudio::Model::SpaceVector.new
    model.getSpaces.each do |space|
      spaces << space
      if make_zones
        # create zones
        new_zone = OpenStudio::Model::ThermalZone.new(model)
        space.setThermalZone(new_zone)
        zone_name = space.name.get.gsub('Space', 'Zone')
        new_zone.setName(zone_name)
      end
    end

    if surface_matching
      # match surfaces for each space in the vector
      OpenStudio::Model.matchSurfaces(spaces)
    end

    # reporting final condition of model
    finishing_spaces = model.getSpaces
    runner.registerFinalCondition("The building finished with #{finishing_spaces.size} spaces.")

    return true
  end
end

# this allows the measure to be use by the application
BarAspectRatioStudy.new.registerWithApplication
