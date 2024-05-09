# *******************************************************************************
# OpenStudio(R), Copyright (c) Alliance for Sustainable Energy, LLC.
# See also https://openstudio.net/license
# *******************************************************************************

# see the URL below for information on how to write OpenStudio measures
# http://nrel.github.io/OpenStudio-user-documentation/reference/measure_writing_guide/

# load openstudio-standards gem
require 'openstudio-standards'

# start the measure
class ReplaceGeometryByStory < OpenStudio::Measure::ModelMeasure

  # human readable name
  def name
    return 'Replace Geometry By Story'
  end

  # human readable description
  def description
    return 'Test measure to throw away spaces and thermal zones of a completed model, adding in custom footprint for each story, and assigning proper space types, story, and fan exhaust. HVAC will be downstream.'
  end

  # human readable description of modeling approach
  def modeler_description
    return 'This is mockup for UrbanOpt, where footprint shape will come from geojson.'
  end

  # define the arguments that the user will input
  def arguments(model)
    args = OpenStudio::Measure::OSArgumentVector.new

    return args
  end

  # define what happens when the measure is run
  def run(model, runner, user_arguments)
    super(model, runner, user_arguments)

    # use the built-in error checking
    if !runner.validateUserArguments(arguments(model), user_arguments)
      return false
    end

    # report initial condition of model
    runner.registerInitialCondition("The building started with #{model.getSpaces.size} spaces.")

    # create hash of space type by story
    story_hash = {}
    model.getBuildingStorys.each do |story|
      next if !story.spaces.first.spaceType.is_initialized

      story_hash[story] = {}
      story_hash[story][:space_type] = story.spaces.first.spaceType.get

      # set nominalZCoordinate, as it is used later on
      minz_spaces = []
      sorted_spaces = {}
      story.spaces.each do |space|
        # loop through space surfaces to find min z value
        z_points = []
        space.surfaces.each do |surface|
          surface.vertices.each do |vertex|
            z_points << vertex.z
          end
        end
        minz_spaces << z_points.min + space.zOrigin
      end
      if !minz_spaces.empty?
        story.setNominalZCoordinate(minz_spaces.min)
      end
    end
    orig_floor_area = model.getBuilding.floorArea

    # un-assign fan exhaust zone objects
    model.getFanZoneExhausts.each(&:removeFromThermalZone)

    # Identity matrix for setting space origins
    m = OpenStudio::Matrix.new(4, 4, 0)
    m[0, 0] = 1
    m[1, 1] = 1
    m[2, 2] = 1
    m[3, 3] = 1

    # target origin for all spaces
    m[0, 3] = 0.0
    m[1, 3] = 0.0
    m[2, 3] = 0.0

    # space transformation
    model.getSpaces.each do |space|
      space.changeTransformation(OpenStudio::Transformation.new(m))
    end

    # loop through surfaces
    floor_polygons = []
    starting_footprint_area = 0.0

    story_hash.each do |story, hash|
      hash[:basement] = false
      hash[:multipliers] = []

      story.spaces.each do |space|
        hash[:multipliers] << space.multiplier

        space.surfaces.each do |surface|
          next if !(surface.outsideBoundaryCondition == 'Ground' || surface.outsideBoundaryCondition == 'OtherSideCoefficients')

          if surface.surfaceType == 'Wall'
            hash[:basement] = true
            next
          elsif surface.surfaceType != 'Floor'
            next
          end
          # runner.registerInfo("#{surface.name} is a ground exposed floor")
          starting_footprint_area += surface.grossArea

          # add to polygons
          new_floor_polygon = []
          surface.vertices.each do |vertex|
            new_floor_polygon << OpenStudio::Point3d.new(vertex.x, vertex.y, 0.0)
          end
          floor_polygons << new_floor_polygon
        end
      end
    end

    # report starting footprint area
    starting_footprint_area_ip = OpenStudio.toNeatString(OpenStudio.convert(starting_footprint_area, 'm^2', 'ft^2').get, 0, true)
    runner.registerInfo("Model has #{floor_polygons.size} ground exposed floor surfaces, with an area of #{starting_footprint_area_ip} (ft^2).")

    # Combine the polygons
    combined_polygons = OpenStudio.joinAll(floor_polygons, 0.01)

    # temp code to work around bug in joinAll
    floor_polygons2 = floor_polygons
    floor_polygons.size.times do |i|
      floor_polygons2 << combined_polygons.first
      combined_polygons = OpenStudio.joinAll(floor_polygons2.rotate(i), 0.01)
    end
    combined_polygons = combined_polygons.first

    # get target wwr
    target_wwr = OsLib_Geometry.getExteriorWindowToWallRatio(model.getSpaces)
    runner.registerInfo("Initial window to wall ratio is #{target_wwr}")

    # remove geometry
    model.getThermalZones.each(&:remove)
    model.getSpaces.each(&:remove)

    # add new geometry
    story_hash.each do |story, hash|
      space_type = hash[:space_type]
      options = {}
      options['name'] = story.name.get
      options['spaceType'] = space_type
      options['story'] = story
      options['makeThermalZone'] = true
      options['thermalZoneMultiplier'] = hash[:multipliers].min
      options['floor_to_floor_height'] = story.nominalFloortoFloorHeight.get
      space = OsLib_Geometry.makeSpaceFromPolygon(model, OpenStudio::Point3d.new(0, 0, 0), combined_polygons, options)
      space.setZOrigin(story.nominalZCoordinate.get)

      # make ext walls ground if original space had any ground exposed walls
      if hash[:basement]
        space.surfaces.each do |surface|
          next if surface.surfaceType != 'Wall'

          surface.setOutsideBoundaryCondition('Ground')
        end
      end
    end
    # surface match
    spaces = OpenStudio::Model::SpaceVector.new
    model.getSpaces.each do |space|
      spaces << space
    end
    OpenStudio::Model.matchSurfaces(spaces)

    # set window to wall ratio
    model.getSpaces.each do |space|
      space.surfaces.each do |surface|
        next if surface.outsideBoundaryCondition != 'Outdoors'
        next if surface.surfaceType != 'Wall'

        surface.setWindowToWallRatio(target_wwr)
      end
    end

    # re-assign fan zone exhaust objets
    zone_hash = {} # key is zone value is floor area. It excludes zones with non 1 multiplier
    model.getThermalZones.each do |thermal_zone|
      next if thermal_zone.multiplier > 1

      zone_hash[thermal_zone] = thermal_zone.floorArea
    end
    target_zone = zone_hash.key(zone_hash.values.max)
    model.getFanZoneExhausts.each do |exhaust|
      exhaust.addToThermalZone(target_zone)
    end

    # check that footprint matches expected
    if model.getSpaces.first.floorArea.round(2) != starting_footprint_area.round(2)
      runner.registerWarning("Resulting floor area of #{model.getSpaces.first.floorArea} doesn't match expected value of #{starting_footprint_area}")
    end

    # report final condition of model
    runner.registerFinalCondition("The building finished with #{model.getSpaces.size} spaces.")

    return true
  end
end

# register the measure to be used by the application
ReplaceGeometryByStory.new.registerWithApplication
