# *******************************************************************************
# OpenStudio(R), Copyright (c) Alliance for Sustainable Energy, LLC.
# See also https://openstudio.net/license
# *******************************************************************************

require 'openstudio'

module Functions
  # return an array of surfaces or subsurfaces from a specific facade.
  def self.get_surfaces_or_subsurfaces_by_facade(surfaces_or_subsurfaces, facade)
    surfaces_or_subsurfaces_by_facade = []

    surfaces_or_subsurfaces.each do |surface_or_subsurface|
      case surface_or_subsurface.class.to_s.gsub('OpenStudio::Model::', '')
      when 'Surface'
        next if surface_or_subsurface.surfaceType != 'Wall'
        next if surface_or_subsurface.outsideBoundaryCondition != 'Outdoors'

        if surface_or_subsurface.space.empty?
          runner.registerWarning("#{surface_or_subsurface.name} doesn't have a parent space and won't be included in the measure reporting or modifications.")
          next
        end
        direction_of_relative_north = surface_or_subsurface.space.get.directionofRelativeNorth
      when 'SubSurface'
        next if surface_or_subsurface.subSurfaceType == 'Door' || surface_or_subsurface.subSurfaceType == 'OverheadDoor'

        direction_of_relative_north = surface_or_subsurface.surface.get.space.get.directionofRelativeNorth
      end

      # get the absoluteAzimuth for the surface so we can categorize it
      absoluteAzimuth = OpenStudio.convert(surface_or_subsurface.azimuth, 'rad', 'deg').get + direction_of_relative_north + surface_or_subsurface.model.getBuilding.northAxis
      absoluteAzimuth -= 360.0 until absoluteAzimuth < 360.0

      case facade
      when 'North'
        next if !((absoluteAzimuth >= 315.0) || (absoluteAzimuth < 45.0))
      when 'East'
        next if !((absoluteAzimuth >= 45.0) && (absoluteAzimuth < 135.0))
      when 'South'
        next if !((absoluteAzimuth >= 135.0) && (absoluteAzimuth < 225.0))
      when 'West'
        next if !((absoluteAzimuth >= 225.0) && (absoluteAzimuth < 315.0))
      when 'All'
        # no next needed
      else
        runner.registerError("Unexpected value of facade: #{facade}.")
        return false
      end

      surfaces_or_subsurfaces_by_facade << surface_or_subsurface
    end

    return surfaces_or_subsurfaces_by_facade
  end

  # return a hash of subsurface constructions.
  def self.get_orig_sub_surf_const_for_target(subsurfaces)
    orig_sub_surf_const_for_target = {}

    subsurfaces.each do |subsurface|
      next if subsurface.subSurfaceType == 'Door' || subsurface.subSurfaceType == 'OverheadDoor'

      if subsurface.construction.is_initialized
        if orig_sub_surf_const_for_target.key?(subsurface.construction.get)
          orig_sub_surf_const_for_target[subsurface.construction.get] += 1
        else
          orig_sub_surf_const_for_target[subsurface.construction.get] = 1
        end
      end
    end

    return orig_sub_surf_const_for_target
  end

  # see if surface is rectangular (only checking non rotated on vertical wall)
  # todo - add in more robust rectangle check that can look for rotate and tilted rectangles
  def self.rectangle?(surface)
    x_vals = []
    y_vals = []
    z_vals = []
    vertices = surface.vertices
    vertices.each do |vertex|
      # initialize new vertex to old vertex
      # rounding values to address tolerance issue 10 digits digits in
      x_vals << vertex.x.round(4)
      y_vals << vertex.y.round(4)
      z_vals << vertex.z.round(4)
    end
    if x_vals.uniq.size <= 2 && y_vals.uniq.size <= 2 && z_vals.uniq.size <= 2
      return true
    else
      return false
    end
  end

  # return true if the requested window-to-wall area exceeds the maximum allowed area, false if not.
  # implements the following part of the applyViewAndDaylightingGlassRatios method, which is what setWindowToWallRatio uses.
  # https://github.com/NREL/OpenStudio/blob/760613c7ac9c2093f7dbd65f947a6853356c558d/src/utilities/geometry/Geometry.cpp#L605-L695
  def self.requested_window_area_greater_than_max?(surface, viewGlassToWallRatio)
    daylightingGlassToWallRatio = 0
    totalWWR = viewGlassToWallRatio + daylightingGlassToWallRatio

    vertices = surface.vertices
    transformation = OpenStudio::Transformation.alignFace(vertices)
    faceVertices = transformation.inverse * vertices

    # // new coordinate system has z' in direction of outward normal, y' is up
    xmin = 0
    xmax = 0
    ymin = 0
    ymax = 0
    faceVertices.each do |faceVertex|
      xmin = [xmin, faceVertex.x].min
      xmax = [xmax, faceVertex.x].max
      ymin = [ymin, faceVertex.y].min
      ymax = [ymax, faceVertex.y].max
    end

    oneInch = 0.0254 # meters

    # // DLM: preserve a 1" gap between window and edge to keep SketchUp happy
    minGlassToEdgeDistance = oneInch
    minViewToDaylightDistance = 0

    # // wall parameters
    wallWidth = xmax - xmin
    wallHeight = ymax - ymin
    wallArea = wallWidth * wallHeight

    # return false if wallWidth < 2 * minGlassToEdgeDistance

    # return false if wallHeight < 2 * minGlassToEdgeDistance + minViewToDaylightDistance

    maxWindowArea = wallArea - 2 * wallHeight * minGlassToEdgeDistance
    - (wallWidth - 2 * minGlassToEdgeDistance) * (2 * minGlassToEdgeDistance + minViewToDaylightDistance)
    requestedViewArea = viewGlassToWallRatio * wallArea
    requestedDaylightingArea = daylightingGlassToWallRatio * wallArea
    requestedTotalWindowArea = totalWWR * wallArea

    if requestedTotalWindowArea > maxWindowArea
      return true
    else
      return false
    end
  end
end
