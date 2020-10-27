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
# http://openstudio.nrel.gov/openstudio-measure-writing-guide

# see the URL below for information on using life cycle cost objects in OpenStudio
# http://openstudio.nrel.gov/openstudio-life-cycle-examples

# see the URL below for access to C++ documentation on model objects (click on "model" in the main window to view model objects)
# http://openstudio.nrel.gov/sites/openstudio.nrel.gov/files/nv_data/cpp_documentation_it/model/html/namespaces.html

# start the measure
class CleanupSpaceOrigins < OpenStudio::Measure::ModelMeasure
  # define the name that a user will see, this method may be deprecated as
  # the display name in PAT comes from the name field in measure.xml
  def name
    return 'CleanupSpaceOrigins'
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

    # assign the user inputs to variables

    def cleanup_group(group)
      boundingBox = group.transformation * group.boundingBox

      if boundingBox.isEmpty
        return
      end

      matrix = OpenStudio::Matrix.new(4, 4, 0)
      matrix[0, 0] = 1
      matrix[1, 1] = 1
      matrix[2, 2] = 1
      matrix[3, 3] = 1
      matrix[0, 3] = boundingBox.minX.get
      matrix[1, 3] = boundingBox.minY.get
      matrix[2, 3] = boundingBox.minZ.get
      translation = OpenStudio::Transformation.new(matrix)
      group.changeTransformation(translation)
    end

    # reporting initial condition of model
    planarSurfaceGroups = model.getPlanarSurfaceGroups
    runner.registerInitialCondition("The building has #{planarSurfaceGroups.size} planar surface groups.")

    # do spaces first as these may contain other groups
    model.getSpaces.each do |space|
      next if !runner.inSelection(space)
      cleanup_group(space)

      space.shadingSurfaceGroups.each do |group|
        cleanup_group(group)
      end

      space.interiorPartitionSurfaceGroups.each do |group|
        cleanup_group(group)
      end
    end

    # now do shading surfaces
    model.getShadingSurfaceGroups.each do |group|
      next if !runner.inSelection(group)
      cleanup_group(group)
    end

    # now do interior partition surface groups
    model.getInteriorPartitionSurfaceGroups.each do |group|
      next if !runner.inSelection(group)
      cleanup_group(group)
    end

    # reporting final condition of model
    runner.registerFinalCondition('All planar surface group origins have been inspected, and adjusted as necessary.')

    return true
  end
end

# this allows the measure to be use by the application
CleanupSpaceOrigins.new.registerWithApplication
