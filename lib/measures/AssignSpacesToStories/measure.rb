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
class AssignSpacesToStories < OpenStudio::Measure::ModelMeasure
  # define the name that a user will see, this method may be deprecated as
  # the display name in PAT comes from the name field in measure.xml
  def name
    return 'AssignSpacesToStories'
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

    # find the first story with z coordinate, create one if needed
    def getStoryForNominalZCoordinate(model, minz)
      model.getBuildingStorys.each do |story|
        z = story.nominalZCoordinate
        if !z.empty?
          if minz.round(2) == z.get.round(2)
            return story
          end
        end
      end

      story = OpenStudio::Model::BuildingStory.new(model)
      story.setNominalZCoordinate(minz)
      return story
    end

    # reporting initial condition of model
    starting_stories = model.getBuildingStorys
    runner.registerInitialCondition("The building started with #{starting_stories.size} stories.")

    # get all spaces
    spaces = model.getSpaces

    # make has of spaces and minz values
    sorted_spaces = {}
    spaces.each do |space|
      # loop through space surfaces to find min z value
      z_points = []
      space.surfaces.each do |surface|
        surface.vertices.each do |vertex|
          z_points << vertex.z
        end
      end
      minz = z_points.min + space.zOrigin
      sorted_spaces[space] = minz
    end

    # pre-sort spaces
    sorted_spaces = sorted_spaces.sort_by { |a| a[1] }

    # this should take the sorted list and make and assign stories
    sorted_spaces.each do |space|
      space_obj = space[0]
      space_minz = space[1]
      if space_obj.buildingStory.empty?

        story = getStoryForNominalZCoordinate(model, space_minz)
        space_obj.setBuildingStory(story)

      end
    end

    # reporting final condition of model
    finishing_stories = model.getBuildingStorys
    runner.registerFinalCondition("The building finished with #{finishing_stories.size} stories.")

    return true
  end
end

# this allows the measure to be use by the application
AssignSpacesToStories.new.registerWithApplication
