# *******************************************************************************
# OpenStudio(R), Copyright (c) 2008-2018, Alliance for Sustainable Energy, LLC.
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

# start the measure
class RotateBuilding < OpenStudio::Measure::ModelMeasure
  # define the name that a user will see
  def name
    return 'Rotate Building'
  end

  # human readable description
  def description
    return 'Rotate your building relative to its current orientation. This will not rotate site shading objects.'
  end

  # human readable description of modeling approach
  def modeler_description
    return 'Get the North Axis field for the  OS:Building object and adjusted it based on the user specified value. If the starting value is 20 degrees and the user value is 5 degrees, then the resulting value is 25 degrees.'
  end

  # define the arguments that the user will input
  def arguments(model)
    args = OpenStudio::Measure::OSArgumentVector.new

    # make an argument for your name
    relative_building_rotation = OpenStudio::Measure::OSArgument.makeDoubleArgument('relative_building_rotation', true)
    relative_building_rotation.setDisplayName('Number of Degrees to Rotate Building (positive value is clockwise).')
    relative_building_rotation.setDefaultValue(90.0)
    relative_building_rotation.setUnits('degrees')
    args << relative_building_rotation

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
    relative_building_rotation = runner.getDoubleArgumentValue('relative_building_rotation', user_arguments)

    # check the relative_building_rotation for reasonableness
    if (relative_building_rotation > 360) || (relative_building_rotation < -360)
      relative_building_rotation -= 360.0 * (relative_building_rotation / 360.0).truncate
      runner.registerWarning("Requested rotation was not between -360 and 360. Effective relative rotation is #{relative_building_rotation} degrees.")
    end

    # reporting initial condition of model
    building = model.getBuilding
    runner.registerValue('orientation_initial', building.northAxis)
    runner.registerInitialCondition("The building's initial rotation was #{building.northAxis} degrees.")

    # report as not applicable if effective relative rotation is 0
    if relative_building_rotation == 0
      runner.registerAsNotApplicable('The requested rotation was 0 degrees. The model was not altered.')
    else
      # rotate the building
      final_building_angle = building.setNorthAxis(building.northAxis + relative_building_rotation)
      runner.registerInfo("The building has been rotated by #{relative_building_rotation} degrees.")
    end

    # check for site shading
    model_contains_site_shading = false
    shading_surface_groups = model.getShadingSurfaceGroups
    shading_surface_groups.each do |shading_surface_group|
      if shading_surface_group.shadingSurfaceType == 'Site'
        model_contains_site_shading = true
      end
    end

    # issue warning if site shading surfaces exist
    if model_contains_site_shading
      runner.registerWarning('The model contains one or more site shading groups. They were not rotated with the building.')
    end

    # reporting final condition of model
    runner.registerValue('orientation_final', building.northAxis)
    runner.registerFinalCondition("The building's final rotation is #{building.northAxis} degrees.")

    return true
  end
end

# this allows the measure to be used by the application
RotateBuilding.new.registerWithApplication
