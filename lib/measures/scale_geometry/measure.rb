# frozen_string_literal: true

# *******************************************************************************
# OpenStudio(R), Copyright (c) 2008-2020, Alliance for Sustainable Energy, LLC.
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
