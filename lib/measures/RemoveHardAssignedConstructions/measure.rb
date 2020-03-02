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
# http://openstudio.nrel.gov/openstudio-measure-writing-guide

# see the URL below for information on using life cycle cost objects in OpenStudio
# http://openstudio.nrel.gov/openstudio-life-cycle-examples

# see the URL below for access to C++ documentation on model objects (click on "model" in the main window to view model objects)
# http://openstudio.nrel.gov/sites/openstudio.nrel.gov/files/nv_data/cpp_documentation_it/model/html/namespaces.html

# start the measure
class RemoveHardAssignedConstructions < OpenStudio::Measure::ModelMeasure
  # define the name that a user will see, this method may be deprecated as
  # the display name in PAT comes from the name field in measure.xml
  def name
    return 'RemoveHardAssignedConstructions'
  end

  # define the arguments that the user will input
  def arguments(model)
    args = OpenStudio::Measure::OSArgumentVector.new

    # make an argument to skip removal of hard assigned constructions on adiabatic surfaces
    preserve_adiabatic = OpenStudio::Measure::OSArgument.makeBoolArgument('preserve_adiabatic', true)
    preserve_adiabatic.setDisplayName('Preserve Hard Assigned Constructions for Adiabatic Surfaces.')
    preserve_adiabatic.setDefaultValue(true)
    args << preserve_adiabatic

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
    preserve_adiabatic = runner.getBoolArgumentValue('preserve_adiabatic', user_arguments)

    # setup counter for initial condition
    numberOfDefaultedSurfaces = 0

    # surfaces to skip if preserve_adiabatic
    adiabaticArray = []
    model.getSurfaces.each do |surface|
      if surface.outsideBoundaryCondition == 'Adiabatic'
        adiabaticArray << surface
      end
    end

    # reset all planar surfaces
    planar_surfaces = model.getPlanarSurfaces
    planar_surfaces.each do |planar_surface|
      if planar_surface.isConstructionDefaulted
        numberOfDefaultedSurfaces += 1
      end
      if !(preserve_adiabatic && adiabaticArray.include?(planar_surface))
        planar_surface.resetConstruction
      end
    end

    # reporting initial condition of model
    runner.registerInitialCondition("The building has #{planar_surfaces.size} planar surfaces. Initially #{planar_surfaces.size - numberOfDefaultedSurfaces} surfaces have hard assigned constructions.")

    # check how many surfaces are defaulted in final model
    finalNumberOfDefaultedSurfaces = 0
    planar_surfaces.each do |planar_surface|
      if planar_surface.isConstructionDefaulted
        finalNumberOfDefaultedSurfaces += 1
      end
    end

    # reporting final condition of model
    finishing_spaces = model.getSpaces
    runner.registerFinalCondition("The final model has #{planar_surfaces.size - finalNumberOfDefaultedSurfaces} surfaces with hard assigned constructions.")

    return true
  end
end

# this allows the measure to be use by the application
RemoveHardAssignedConstructions.new.registerWithApplication
