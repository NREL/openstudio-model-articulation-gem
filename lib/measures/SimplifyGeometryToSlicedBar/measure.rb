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

#see the URL below for information on how to write OpenStudio measures
# http://openstudio.nrel.gov/openstudio-measure-writing-guide

#see the URL below for information on using life cycle cost objects in OpenStudio
# http://openstudio.nrel.gov/openstudio-life-cycle-examples

#see the URL below for access to C++ documentation on model objects (click on "model" in the main window to view model objects)
# http://openstudio.nrel.gov/sites/openstudio.nrel.gov/files/nv_data/cpp_documentation_it/model/html/namespaces.html

begin
  #load OpenStudio measure libraries from common location
  require 'measure_resources/os_lib_geometry'
  require 'measure_resources/os_lib_helper_methods'
  require 'measure_resources/os_lib_cofee'
rescue LoadError
  # common location unavailable, load from local resources
  require_relative 'resources/os_lib_geometry'
  require_relative 'resources/os_lib_helper_methods'
  require_relative 'resources/os_lib_cofee'
end

#start the measure
class SimplifyGeometryToSlicedBar < OpenStudio::Ruleset::ModelUserScript
  
  #define the name that a user will see, this method may be deprecated as
  #the display name in PAT comes from the name field in measure.xml
  def name
    return "SimplifyGeometryToSlicedBar"
  end
  
  #define the arguments that the user will input
  def arguments(model)
    args = OpenStudio::Ruleset::OSArgumentVector.new

    #make choice argument for geometry size logic
    choices = OpenStudio::StringVector.new
    choices << "Maintain Bounding Box Aspect Ratio"
    choices << "Maintain Total Exterior Wall Area"
    choices << "Maintain Facade Specific Exterior Wall Area" #  using 2 bar solution with adiabatic ends
    logic = OpenStudio::Ruleset::OSArgument::makeChoiceArgument("logic", choices,true)
    logic.setDisplayName("Maintain Total Floor Area and the following characteristic.")
    logic.setDefaultValue("Maintain Bounding Box Aspect Ratio")
    args << logic

    return args
  end

  #define what happens when the measure is run
  def run(model, runner, user_arguments)
    super(model, runner, user_arguments)
    
    #use the built-in error checking 
    if not runner.validateUserArguments(arguments(model), user_arguments)
      return false
    end

    #assign the user inputs to variables
    logic = runner.getStringArgumentValue("logic",user_arguments)

    # get bounding box. This measure assumes ideal rotation for best bounding box is set as building rotation in source model
    boundingBox = OpenStudio::BoundingBox.new

    spaces = model.getSpaces
    spaces.each do |space|
      spaceSurfaces = space.surfaces
      spaceSurfaces.each do |spaceSurface|
        boundingBox.addPoints(space.transformation() * spaceSurface.vertices)
      end
    end

    xmin = boundingBox.minX.get
    ymin = boundingBox.minY.get
    zmin = boundingBox.minZ.get
    xmax = boundingBox.maxX.get
    ymax = boundingBox.maxY.get
    zmax = boundingBox.maxZ.get

    # get total floor area for building
    building = model.getBuilding
    totalFloorArea = building.floorArea # todo - this doesn't include spaces tagged as not included in floor area. This would include spaces like plenums and attics
    runner.registerInfo("Initial Floor Area is #{OsLib_HelperMethods.neatConvertWithUnitDisplay(totalFloorArea,"m^2","ft^2",0,unitBefore = false,unitAfter = true, space = true, parentheses = true)}.")

    # get get number of floors. Assume that user has properly used story object.
    numStories = 0
    stories = model.getBuildingStorys
    stories.each do |story|
      if story.spaces.size > 0
        numStories += 1
      end
    end
    runner.registerInfo("Initial Number of Stories is #{numStories}.")

    # warn if source model uses multiplier on zones.
    zones = model.getThermalZones
    zones.each do |zone|
      if zone.multiplier > 1
        runner.registerWarning("One or more zones have a multiplier greater than 1. This may create unexpected results.")
        break
      end
    end

    # create hash of space types used and area for each.
    spaceTypeHash = {} # spaceType object and target floor area
    totalSpaceTypeArea = 0

    # loop through space types
    spaceTypes = model.getSpaceTypes
    spaceTypes.each do |spaceType|
      next if spaceType.spaces.size == 0
      result = OsLib_HelperMethods.getAreaOfSpacesInArray(model,spaceType.spaces,areaType = "floorArea")
      spaceTypeHash[spaceType] = result["totalArea"]
      totalSpaceTypeArea += result["totalArea"]
    end

    runner.registerInfo("Initial Space Type Total Floor Area is #{OsLib_HelperMethods.neatConvertWithUnitDisplay(totalSpaceTypeArea,"m^2","ft^2",0,unitBefore = false,unitAfter = true, space = true, parentheses = true)}.")

    spaceTypeHash.sort_by {|key, value| value}.reverse.each do |k,v|
      runner.registerInfo("Floor Area for #{k.name} is  #{OsLib_HelperMethods.neatConvertWithUnitDisplay(v,"m^2","ft^2",0,unitBefore = false,unitAfter = true, space = true, parentheses = true)}.")
    end

    # todo - warn if some spaces are not included in floor area (plenum and attic)
    # todo - warn if any hard assigned constructions are found. This measure will use default constructions, except for adiabatic surfaces
    # todo - warn if some spaces don't have space type
    # todo - warn if some spaces have extra internal loads beyond the space type
    # todo - warn if it looks like building has basement, not currently setup to look at that
    # todo - this measure wont' touch HVAC systems, consider warning user if model already has HVAC, as it won't be hooked up to anything after this.

    # get wall and window area by facade
    starting_spaces = model.getSpaces
    areaByFacade = OsLib_Geometry.getExteriorWindowAndWllAreaByOrientation(model, starting_spaces, options = {})
    northWallGross = OsLib_HelperMethods.neatConvertWithUnitDisplay(areaByFacade["northWall"],"m^2","ft^2",0,unitBefore = false,unitAfter = true, space = true, parentheses = true)
    southWallGross = OsLib_HelperMethods.neatConvertWithUnitDisplay(areaByFacade["southWall"],"m^2","ft^2",0,unitBefore = false,unitAfter = true, space = true, parentheses = true)
    eastWallGross = OsLib_HelperMethods.neatConvertWithUnitDisplay(areaByFacade["eastWall"],"m^2","ft^2",0,unitBefore = false,unitAfter = true, space = true, parentheses = true)
    westWallGross = OsLib_HelperMethods.neatConvertWithUnitDisplay(areaByFacade["westWall"],"m^2","ft^2",0,unitBefore = false,unitAfter = true, space = true, parentheses = true)
    runner.registerInfo("Initial Exterior Wall Breakdown. North: #{northWallGross}, South: #{southWallGross}, East: #{eastWallGross}, West: #{westWallGross}")

    #reporting initial condition of model
    floorArea_si = OsLib_HelperMethods.getAreaOfSpacesInArray(model,starting_spaces,areaType = "floorArea")["totalArea"]
    floorArea_ip = OsLib_HelperMethods.neatConvertWithUnitDisplay(floorArea_si,"m^2","ft^2",0,unitBefore = false,unitAfter = true, space = true, parentheses = true)
    exteriorArea_si = OsLib_HelperMethods.getAreaOfSpacesInArray(model,starting_spaces,areaType = "exteriorWallArea")["totalArea"]
    exteriorArea_ip = OsLib_HelperMethods.neatConvertWithUnitDisplay(exteriorArea_si,"m^2","ft^2",0,unitBefore = false,unitAfter = true, space = true, parentheses = true)

    runner.registerInitialCondition("The building started with #{floorArea_ip} of floor area, and  #{exteriorArea_ip} of exterior wall area.")

    # remove all spaces, zones, and stories in the model
    spaces.each do |space|
      space.remove
    end
    stories.each do |story|
      story.remove
    end
    zones.each do |zone|
      zone.remove
    end

    # see which path to take
    midFloorMultiplier = 1 # show as 1 even on 1 and 2 story buildings where there is no mid floor, in addition to 3 story building
    if numStories > 3
      # use floor multiplier version. Set mid floor multiplier, use adibatic floors/ceilings and set constructions, raise up building
      midFloorMultiplier = numStories - 2
    end

    # calculate bounding box area
    lengthX = xmax - xmin
    lengthY = ymax - ymin
    areaBounding = lengthX * lengthY
    lengthX_display = OsLib_HelperMethods.neatConvertWithUnitDisplay(lengthX,"m","ft",0,unitBefore = false,unitAfter = true, space = true, parentheses = true)
    lengthY_display  =  OsLib_HelperMethods.neatConvertWithUnitDisplay(lengthY,"m","ft",0,unitBefore = false,unitAfter = true, space = true, parentheses = true)
    areaBounding_display  = OsLib_HelperMethods.neatConvertWithUnitDisplay(areaBounding,"m^2","ft^2",0,unitBefore = false,unitAfter = true, space = true, parentheses = true)
    runner.registerInfo("Bounding box area is #{areaBounding_display}. #{lengthX_display} by #{lengthY_display}.")

    # get target footprint size
    if logic == "Maintain Bounding Box Aspect Ratio"
      areaTarget = totalFloorArea/numStories
      areaMultiplier = areaTarget/areaBounding
      edgeMultiplier = Math.sqrt(areaMultiplier)
      lengthXTarget = lengthX * edgeMultiplier
      lengthYTarget = lengthY * edgeMultiplier

      # run def to create bar
      bar_AspectRatio = OsLib_Cofee.createBar(model,spaceTypeHash,lengthXTarget,lengthYTarget,totalFloorArea,numStories,midFloorMultiplier,xmin,ymin,lengthX,lengthY,zmin,zmax,true)

    elsif logic == "Maintain Total Exterior Wall Area"
      areaTarget = totalFloorArea/numStories
      perim = exteriorArea_si/(zmax-zmin)
      lengthYTarget = 0.25*perim - 0.25*Math.sqrt(perim**2 - 16*areaTarget)
      lengthXTarget = areaTarget/lengthYTarget

      # run def to create bar
      bar_ExteriorArea = OsLib_Cofee.createBar(model,spaceTypeHash,lengthXTarget,lengthYTarget,totalFloorArea,numStories,midFloorMultiplier,xmin,ymin,lengthX,lengthY,zmin,zmax,true)

    else
      areaTarget = totalFloorArea/numStories
      lengthXTarget_Bar1 = (areaByFacade["northWall"] + areaByFacade["southWall"])/(2*(zmax-zmin))
      lengthYTarget_Bar2 = (areaByFacade["eastWall"] + areaByFacade["westWall"])/(2*(zmax-zmin))
      lengthYTarget_Bar1 = areaTarget/(lengthXTarget_Bar1 + lengthYTarget_Bar2)
      lengthXTarget_Bar2 = lengthYTarget_Bar1

      # run def to create bar1
      bar1_FacadeSpecific = OsLib_Cofee.createBar(model,spaceTypeHash,lengthXTarget_Bar1,lengthYTarget_Bar1,totalFloorArea,numStories,midFloorMultiplier,xmin,ymin,lengthX,lengthY,zmin,zmax,false)

      # make ends of bar1 adiabatic
      bar1_FacadeSpecific.flatten.each do |space|
        space.surfaces.each do |surface|
          relativeAzimuth =  OpenStudio::convert(surface.azimuth,"rad","deg").get
          next if not surface.outsideBoundaryCondition == "Outdoors"
          next if not surface.surfaceType == "Wall"
          if relativeAzimuth.round == 90 or relativeAzimuth.round == 270
            construction = surface.construction # todo - this isn't really the construction I want since it wasn't an interior one, but will work for now
            surface.setOutsideBoundaryCondition("Adiabatic")
            if not construction.empty?
              surface.setConstruction(construction.get)
            end
          end
        end
      end

      # update origin position (todo - not quite working as expected)
      xmin += lengthYTarget_Bar1 + (zmax - zmin)*2 # gap equal two twice the height.

      # run def to create bar2 (todo - calling this twice is slower and ends up with wrong number of story objects, which will create problems in calibration)
      bar2_FacadeSpecific = OsLib_Cofee.createBar(model,spaceTypeHash,lengthYTarget_Bar2,lengthXTarget_Bar2,totalFloorArea,numStories,midFloorMultiplier,xmin,ymin,lengthX,lengthY,zmin,zmax,false)

      # update origin transformation or rotation  (todo - don't use building as transformation origin)
      bar2_FacadeSpecific.flatten.each do |space|
        space.changeTransformation(building.transformation)
        space.setDirectionofRelativeNorth(building.northAxis - 90)
      end

      # make ends of bar1 adiabatic
      bar2_FacadeSpecific.flatten.each do |space|
        space.surfaces.each do |surface|
          relativeAzimuth =  OpenStudio::convert(surface.azimuth,"rad","deg").get
          next if not surface.outsideBoundaryCondition == "Outdoors"
          next if not surface.surfaceType == "Wall"
          if relativeAzimuth.round == 90 or relativeAzimuth.round == 270
            construction = surface.construction # todo - this isn't really the construction I want since it wasn't an interior one, but will work for now
            surface.setOutsideBoundaryCondition("Adiabatic")
            if not construction.empty?
              surface.setConstruction(construction.get)
            end
          end
        end
      end

    end

    # get wall and window area by facade
    finishing_spaces = model.getSpaces
    areaByFacade = OsLib_Geometry.getExteriorWindowAndWllAreaByOrientation(model, finishing_spaces, options = {})
    northWallGross = OsLib_HelperMethods.neatConvertWithUnitDisplay(areaByFacade["northWall"],"m^2","ft^2",0,unitBefore = false,unitAfter = true, space = true, parentheses = true)
    southWallGross = OsLib_HelperMethods.neatConvertWithUnitDisplay(areaByFacade["southWall"],"m^2","ft^2",0,unitBefore = false,unitAfter = true, space = true, parentheses = true)
    eastWallGross = OsLib_HelperMethods.neatConvertWithUnitDisplay(areaByFacade["eastWall"],"m^2","ft^2",0,unitBefore = false,unitAfter = true, space = true, parentheses = true)
    westWallGross = OsLib_HelperMethods.neatConvertWithUnitDisplay(areaByFacade["westWall"],"m^2","ft^2",0,unitBefore = false,unitAfter = true, space = true, parentheses = true)
    runner.registerInfo("Final Exterior Wall Breakdown. North: #{northWallGross}, South: #{southWallGross}, East: #{eastWallGross}, West: #{westWallGross}")

    #reporting final condition of model
    floorArea_si = OsLib_HelperMethods.getAreaOfSpacesInArray(model,finishing_spaces,areaType = "floorArea")["totalArea"]
    floorArea_ip = OsLib_HelperMethods.neatConvertWithUnitDisplay(floorArea_si,"m^2","ft^2",0,unitBefore = false,unitAfter = true, space = true, parentheses = true)
    exteriorArea_si = OsLib_HelperMethods.getAreaOfSpacesInArray(model,finishing_spaces,areaType = "exteriorWallArea")["totalArea"]
    exteriorArea_ip = OsLib_HelperMethods.neatConvertWithUnitDisplay(exteriorArea_si,"m^2","ft^2",0,unitBefore = false,unitAfter = true, space = true, parentheses = true)

    runner.registerFinalCondition("The building finished with #{floorArea_ip} of floor area, and  #{exteriorArea_ip} of exterior wall area.")

    return true
 
  end

end

#this allows the measure to be use by the application
SimplifyGeometryToSlicedBar.new.registerWithApplication