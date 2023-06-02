# *******************************************************************************
# OpenStudio(R), Copyright (c) Alliance for Sustainable Energy, LLC.
# See also https://openstudio.net/license
# *******************************************************************************

# see the URL below for information on how to write OpenStudio measures
# http://nrel.github.io/OpenStudio-user-documentation/reference/measure_writing_guide/

# start the measure
class ScaleGeometry < OpenStudio::Measure::ModelMeasure
  # human readable name
  def name
    return 'scale_geometry'
  end

  # human readable description
  def description
    return 'Scales geometry in the model by fixed multiplier in the x, y, z directions.  Does not guarantee that the resulting model will be correct (e.g. not self-intersecting).  '
  end

  # human readable description of modeling approach
  def modeler_description
    return 'Scales all PlanarSurfaceGroup origins and then all PlanarSurface vertices in the model. Also applies to DaylightingControls, GlareSensors, and IlluminanceMaps.'
  end

  # define the arguments that the user will input
  def arguments(model)
    args = OpenStudio::Measure::OSArgumentVector.new

    # x scale
    x_scale = OpenStudio::Measure::OSArgument.makeDoubleArgument('x_scale', true)
    x_scale.setDisplayName('X Scale')
    x_scale.setDescription('Multiplier to apply to X direction.')
    x_scale.setDefaultValue(1.0)
    args << x_scale

    # y scale
    y_scale = OpenStudio::Measure::OSArgument.makeDoubleArgument('y_scale', true)
    y_scale.setDisplayName('Y Scale')
    y_scale.setDescription('Multiplier to apply to Y direction.')
    y_scale.setDefaultValue(1.0)
    args << y_scale

    # z scale
    z_scale = OpenStudio::Measure::OSArgument.makeDoubleArgument('z_scale', true)
    z_scale.setDisplayName('Z Scale')
    z_scale.setDescription('Multiplier to apply to Z direction.')
    z_scale.setDefaultValue(1.0)
    args << z_scale

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
    x_scale = runner.getDoubleArgumentValue('x_scale', user_arguments)
    y_scale = runner.getDoubleArgumentValue('y_scale', user_arguments)
    z_scale = runner.getDoubleArgumentValue('z_scale', user_arguments)

    # report initial condition of model
    runner.registerInitialCondition("The building started with floor area of #{model.getBuilding.floorArea} m^2.")

    model.getPlanarSurfaceGroups.each do |group|
      group.setXOrigin(x_scale * group.xOrigin)
      group.setYOrigin(y_scale * group.yOrigin)
      group.setZOrigin(z_scale * group.zOrigin)
    end

    model.getPlanarSurfaces.each do |surface|
      vertices = surface.vertices
      new_vertices = OpenStudio::Point3dVector.new
      vertices.each do |vertex|
        new_vertices << OpenStudio::Point3d.new(x_scale * vertex.x, y_scale * vertex.y, z_scale * vertex.z)
      end
      surface.setVertices(new_vertices)
    end

    model.getDaylightingControls.each do |control|
      control.setPositionXCoordinate(x_scale * control.positionXCoordinate)
      control.setPositionYCoordinate(y_scale * control.positionYCoordinate)
      control.setPositionZCoordinate(z_scale * control.positionZCoordinate)
    end

    model.getGlareSensors.each do |sensor|
      sensor.setPositionXCoordinate(x_scale * sensor.positionXCoordinate)
      sensor.setPositionYCoordinate(y_scale * sensor.positionYCoordinate)
      sensor.setPositionZCoordinate(z_scale * sensor.positionZCoordinate)
    end

    model.getGlareSensors.each do |map|
      map.setOriginXCoordinate(x_scale * map.originXCoordinate)
      map.setOriginYCoordinate(y_scale * map.originYCoordinate)
      map.setXLength(x_scale * map.xLength)
      map.setYLength(y_scale * map.yLength)
    end

    # report final condition of model
    runner.registerFinalCondition("The building finished with floor area of #{model.getBuilding.floorArea} m^2.")

    return true
  end
end

# register the measure to be used by the application
ScaleGeometry.new.registerWithApplication
