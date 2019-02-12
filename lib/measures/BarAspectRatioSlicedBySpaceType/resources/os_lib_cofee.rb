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

module OsLib_Cofee

  # create def to use later to make bar
  def OsLib_Cofee.createBar(model, spaceTypeHash,lengthXTarget,lengthYTarget,totalFloorArea,numStories,midFloorMultiplier,xmin,ymin,lengthX,lengthY,zmin,zmax,endZones)

    # floor to floor height
    floor_to_floor_height = (zmax-zmin)/numStories

    # perimeter depth
    perimeterDepth = OpenStudio::convert(12,"ft","m").get
    perimeterBufferFactor = 1.5 # this is a margin below which I won't bother splitting the two largest spaces

    # create an array to control sort order of spaces in bar
    customSpaceTypeBar = []
    counter = 0
    spaceTypeHash.sort_by {|key, value| value}.reverse.each do |k,v|
      next if v == 0 # this line adds support for fractional values of 0
      if counter == 1
        if lengthXTarget*(v/totalFloorArea) > perimeterDepth * perimeterBufferFactor and endZones
          customSpaceTypeBar << [k,totalFloorArea * (perimeterDepth/lengthXTarget)]
          customSpaceTypeBar << [k,v - (totalFloorArea * (perimeterDepth/lengthXTarget))]
        else
          customSpaceTypeBar << [k,v]
        end
      elsif counter > 1
        customSpaceTypeBar << [k,v]
      end
      counter += 1
    end

    # add the largest space type to the end
    counter = 0
    spaceTypeHash.sort_by {|key, value| value}.reverse.each do |k,v|
      if counter == 0
        # if width is greater than 1.5x perimeter depth then split in half
        if lengthXTarget*(v/totalFloorArea) > perimeterDepth * perimeterBufferFactor and endZones
          customSpaceTypeBar << [k,v - (totalFloorArea * (perimeterDepth/lengthXTarget))]
          customSpaceTypeBar << [k,totalFloorArea * (perimeterDepth/lengthXTarget)]
        else
          customSpaceTypeBar << [k,v]
        end
      end
      break
    end

    # starting z level
    z = zmin
    storyCounter = 0
    barSpaceArray = []

    # create new stories and then add spaces
    [numStories,3].min.times do # no more than tree loops through this
      story = OpenStudio::Model::BuildingStory.new(model)
      story.setNominalFloortoFloorHeight(floor_to_floor_height)
      story.setNominalZCoordinate(z)

      # starting position for first space
      x = (lengthX - lengthXTarget)*0.5 + xmin
      y = (lengthY - lengthYTarget)*0.5 + ymin

      # temp array of spaces (this is to change floor boundary when there is mid floor multiplier)
      tempSpaceArray = []

      # loop through space types making diagram and spaces.
      #spaceTypeHash.sort_by {|key, value| value}.reverse.each do |k,v|
      customSpaceTypeBar.each do |object|

        # get values from what was hash
        k = object[0]
        v = object[1]

        # get proper zone multiplier value
        if storyCounter == 1 and midFloorMultiplier > 1
          thermalZoneMultiplier = midFloorMultiplier
        else
          thermalZoneMultiplier = 1
        end

        options = {
            "name" => nil,
            "spaceType" => k,
            "story" => story,
            "makeThermalZone" => true,
            "thermalZone" => nil,
            "thermalZoneMultiplier" => thermalZoneMultiplier,
            "floor_to_floor_height" => floor_to_floor_height,
        }

        # three paths for spaces depending upon building depth (3, 2 or one cross slices)
        if lengthYTarget > perimeterDepth * 3  # slice into core and perimeter

          # perimeter polygon a
          perim_polygon_a = OpenStudio::Point3dVector.new
          perim_origin_a = OpenStudio::Point3d.new(x,y,z)
          perim_polygon_a << perim_origin_a
          perim_polygon_a << OpenStudio::Point3d.new(x,y + perimeterDepth,z)
          perim_polygon_a << OpenStudio::Point3d.new(x + lengthXTarget*(v/totalFloorArea),y + perimeterDepth,z)
          perim_polygon_a << OpenStudio::Point3d.new(x + lengthXTarget*(v/totalFloorArea),y,z)

          # create core polygon
          core_polygon = OpenStudio::Point3dVector.new
          core_origin = OpenStudio::Point3d.new(x,y + perimeterDepth,z)
          core_polygon << core_origin
          core_polygon << OpenStudio::Point3d.new(x,y + lengthYTarget - perimeterDepth,z)
          core_polygon << OpenStudio::Point3d.new(x + lengthXTarget*(v/totalFloorArea),y + lengthYTarget - perimeterDepth,z)
          core_polygon << OpenStudio::Point3d.new(x + lengthXTarget*(v/totalFloorArea),y + perimeterDepth,z)

          # perimeter polygon b                              w
          perim_polygon_b = OpenStudio::Point3dVector.new
          perim_origin_b = OpenStudio::Point3d.new(x,y + lengthYTarget - perimeterDepth,z)
          perim_polygon_b << perim_origin_b
          perim_polygon_b << OpenStudio::Point3d.new(x,y + lengthYTarget,z)
          perim_polygon_b << OpenStudio::Point3d.new(x + lengthXTarget*(v/totalFloorArea),y + lengthYTarget,z)
          perim_polygon_b << OpenStudio::Point3d.new(x + lengthXTarget*(v/totalFloorArea),y + lengthYTarget - perimeterDepth,z)

          # run method to make spaces
          tempSpaceArray << OsLib_Geometry.makeSpaceFromPolygon(model,perim_origin_a,perim_polygon_a,options) # model, origin, polygon, options
          tempSpaceArray << OsLib_Geometry.makeSpaceFromPolygon(model,core_origin,core_polygon,options) # model, origin, polygon, options
          tempSpaceArray << OsLib_Geometry.makeSpaceFromPolygon(model,perim_origin_b,perim_polygon_b,options) # model, origin, polygon, options

        elsif lengthYTarget > perimeterDepth * 2  # slice into two peremeter zones but no core

          # perimeter polygon a
          perim_polygon_a = OpenStudio::Point3dVector.new
          perim_origin_a = OpenStudio::Point3d.new(x,y,z)
          perim_polygon_a << perim_origin_a
          perim_polygon_a << OpenStudio::Point3d.new(x,y + lengthYTarget/2,z)
          perim_polygon_a << OpenStudio::Point3d.new(x + lengthXTarget*(v/totalFloorArea),y + lengthYTarget/2,z)
          perim_polygon_a << OpenStudio::Point3d.new(x + lengthXTarget*(v/totalFloorArea),y,z)

          # perimeter polygon b
          perim_polygon_b = OpenStudio::Point3dVector.new
          perim_origin_b = OpenStudio::Point3d.new(x,y + lengthYTarget/2,z)
          perim_polygon_b << perim_origin_b
          perim_polygon_b << OpenStudio::Point3d.new(x,y + lengthYTarget,z)
          perim_polygon_b << OpenStudio::Point3d.new(x + lengthXTarget*(v/totalFloorArea),y + lengthYTarget,z)
          perim_polygon_b << OpenStudio::Point3d.new(x + lengthXTarget*(v/totalFloorArea),y + lengthYTarget/2,z)

          # run method to make spaces
          tempSpaceArray << OsLib_Geometry.makeSpaceFromPolygon(model,perim_origin_a,perim_polygon_a,options) # model, origin, polygon, options
          tempSpaceArray << OsLib_Geometry.makeSpaceFromPolygon(model,perim_origin_b,perim_polygon_b,options) # model, origin, polygon, options

        else # don't slice into core and perimeter

          # create polygon
          core_polygon = OpenStudio::Point3dVector.new
          core_origin = OpenStudio::Point3d.new(x,y,z)
          core_polygon << core_origin
          core_polygon << OpenStudio::Point3d.new(x,y + lengthYTarget,z)
          core_polygon << OpenStudio::Point3d.new(x + lengthXTarget*(v/totalFloorArea),y + lengthYTarget,z)
          core_polygon << OpenStudio::Point3d.new(x + lengthXTarget*(v/totalFloorArea),y,z)

          # run method to make space
          tempSpaceArray << OsLib_Geometry.makeSpaceFromPolygon(model,core_origin,core_polygon,options) # model, origin, polygon, options

        end

        # update points for next run
        x += lengthXTarget*(v/totalFloorArea)

      end

      # set flags for adiabatic surfaces
      floorAdiabatic = false
      ceilingAdiabatic = false

      # update z
      if midFloorMultiplier == 1
        z += floor_to_floor_height
      else
        z += floor_to_floor_height * midFloorMultiplier - floor_to_floor_height

        if storyCounter == 0
          ceilingAdiabatic = true
        elsif storyCounter == 1
          floorAdiabatic = true
          ceilingAdiabatic = true
        else
          floorAdiabatic = true
        end

        # alter surfaces boundary conditions and constructions as described above
        tempSpaceArray.each do |space|
          space.surfaces.each do |surface|
            if surface.surfaceType == "RoofCeiling" and ceilingAdiabatic
              construction = surface.construction # todo - this isn't really the construction I want since it wasn't an interior one, but will work for now
              surface.setOutsideBoundaryCondition("Adiabatic")
              if not construction.empty?
                surface.setConstruction(construction.get)
              end
            end
            if surface.surfaceType == "Floor" and floorAdiabatic
              construction = surface.construction # todo - this isn't really the construction I want since it wasn't an interior one, but will work for now
              surface.setOutsideBoundaryCondition("Adiabatic")
              if not construction.empty?
                surface.setConstruction(construction.get)
              end
            end
          end
        end

        # populate bar space array from temp array
        barSpaceArray << tempSpaceArray

      end

      # update storyCounter
      storyCounter += 1

    end

    # surface matching (seems more complex than necessary)
    spaces = OpenStudio::Model::SpaceVector.new
    model.getSpaces.each do |space|
      spaces << space
    end
    OpenStudio::Model.matchSurfaces(spaces)

    result = barSpaceArray
    return result

  end

end