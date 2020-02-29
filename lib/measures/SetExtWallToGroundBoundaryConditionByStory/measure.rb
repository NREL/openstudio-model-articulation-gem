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

# see the URL below for information on how to write OpenStuido measures
# http://openstudio.nrel.gov/openstudio-measure-writing-guide

# see the URL below for access to C++ documentation on mondel objects (click on "model" in the main window to view model objects)
# http://openstudio.nrel.gov/sites/openstudio.nrel.gov/files/nv_data/cpp_documentation_it/model/html/namespaces.html

# start the measure
class SetExtWallToGroundBoundaryConditionByStory < OpenStudio::Measure::ModelMeasure
  # define the name that a user will see, this method may be deprecated as
  # the display name in PAT comes from the name field in measure.xml
  def name
    return 'SetExtWallToGroundBoundaryConditionByStory'
  end

  # define the arguments that the user will input
  def arguments(model)
    args = OpenStudio::Measure::OSArgumentVector.new

    # populate choice argument for storys that are applied to surfaces in the model
    storyBasement_handles = OpenStudio::StringVector.new
    storyBasement_display_names = OpenStudio::StringVector.new

    # putting stories and names into hash
    storyBasement_args = model.getBuildingStorys
    storyBasement_args_hash = {}
    storyBasement_args.each do |storyBasement_arg|
      storyBasement_args_hash[storyBasement_arg.name.to_s] = storyBasement_arg
    end

    # looping through sorted hash of storys
    storyBasement_args_hash.sort.map do |key, value|
      storyBasement_handles << value.handle.to_s
      storyBasement_display_names << key
    end

    # make an argument for storyBasement
    # todo - warn user if surface has any sub-surfaces.
    storyBasement = OpenStudio::Measure::OSArgument.makeChoiceArgument('storyBasement', storyBasement_handles, storyBasement_display_names, true)
    storyBasement.setDisplayName('Choose a Story to Change Wall Boundary Conditions For.')
    args << storyBasement

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
    storyBasement = runner.getOptionalWorkspaceObjectChoiceValue('storyBasement', user_arguments, model) # model is passed in because of argument type

    # check the storyBasement for reasonableness
    if storyBasement.empty?
      handle = runner.getStringArgumentValue('storyBasement', user_arguments)
      if handle.empty?
        runner.registerError('No storyBasement was chosen.')
      else
        runner.registerError("The selected storyBasement with handle '#{handle}' was not found in the model. It may have been removed by another measure.")
      end
      return false
    else
      if !storyBasement.get.to_BuildingStory.empty?
        storyBasement = storyBasement.get.to_BuildingStory.get
      else
        runner.registerError('Script Error - argument not showing up as storyBasement.')
        return false
      end
    end

    stories = model.getBuildingStorys

    # reporting initial condition of model
    runner.registerInitialCondition("The building has #{stories.size} stories.")

    affectedSpaces = storyBasement.spaces
    affectedSpaces.each do |story|
      surfaces = story.surfaces
      surfaces.each do |surface|
        if (surface.surfaceType == 'Wall') && (surface.outsideBoundaryCondition == 'Outdoors')
          surface.setOutsideBoundaryCondition('Ground')
        end
      end
    end

    # reporting final condition of model
    runner.registerFinalCondition("Exterior walls on #{storyBasement.name} now have a ground boundary condition.")

    return true
  end
end

# this allows the measure to be use by the application
SetExtWallToGroundBoundaryConditionByStory.new.registerWithApplication
