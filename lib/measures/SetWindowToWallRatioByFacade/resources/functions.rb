require 'openstudio'

module Functions

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
  def self.requested_window_area_greater_than_max?(surface, wwr)
    
    viewGlassToWallRatio = wwr
    daylightingGlassToWallRatio = 0
    totalWWR = viewGlassToWallRatio + daylightingGlassToWallRatio

    xvals = []
    yvals = []
    surface.vertices.each do |vertex|
      xvals << vertex.x
      yvals << vertex.y
    end

    oneInch = 0.0254 # meters
    minGlassToEdgeDistance = oneInch
    minViewToDaylightDistance = 0

    wallWidth = xvals.max - xvals.min
    wallHeight = yvals.max - yvals.min
    wallArea = wallWidth * wallHeight

    # return false if wallWidth < 2 * minGlassToEdgeDistance

    # return false if wallHeight < 2 * minGlassToEdgeDistance + minViewToDaylightDistance

    maxWindowArea = wallArea - 2 * wallHeight * minGlassToEdgeDistance
                          - (wallWidth - 2 * minGlassToEdgeDistance) * (2 * minGlassToEdgeDistance + minViewToDaylightDistance)
    requestedViewArea = viewGlassToWallRatio * wallArea;
    requestedDaylightingArea = daylightingGlassToWallRatio * wallArea;
    requestedTotalWindowArea = totalWWR * wallArea;

    if requestedTotalWindowArea > maxWindowArea 
      return false
    else
      return true
    end

  end

end
