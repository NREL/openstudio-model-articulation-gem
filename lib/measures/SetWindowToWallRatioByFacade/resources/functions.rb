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

end
