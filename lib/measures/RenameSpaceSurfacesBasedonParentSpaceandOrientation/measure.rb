# *******************************************************************************
# OpenStudio(R), Copyright (c) 2008-2021, Alliance for Sustainable Energy, LLC.
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

# see the URL below for access to C++ documentation on model objects (click on "model" in the main window to view model objects)
# http://openstudio.nrel.gov/sites/openstudio.nrel.gov/files/nv_data/cpp_documentation_it/model/html/namespaces.html

# start the measure
class RenameSpaceSurfacesBasedonParentSpaceandOrientation < OpenStudio::Measure::ModelMeasure
  # define the name that a user will see, this method may be deprecated as
  # the display name in PAT comes from the name field in measure.xml
  def name
    return 'RenameSpaceSurfacesBasedonParentSpaceandOrientation'
  end

  # define the arguments that the user will input
  def arguments(model)
    args = OpenStudio::Measure::OSArgumentVector.new

    # there are no arguments for this. At some point we could add arguments to customize naming logic.

    return args
  end

  # define what happens when the measure is run
  def run(model, runner, user_arguments)
    super(model, runner, user_arguments)

    # use the built-in error checking
    if !runner.validateUserArguments(arguments(model), user_arguments)
      return false
    end

    # no arguments assign the user inputs to variables

    # get model objects
    surfaces = model.getSurfaces
    subSurfaces = model.getSubSurfaces

    # reporting initial condition of model
    runner.registerInitialCondition("The building has #{surfaces.size} space surfaces and #{subSurfaces.size} sub-surfaces.")

    # give temp names to surfaces so there are no conflicts if this is re-run more than once.
    counter = 0
    surfaces.each do |surface|
      if !surface.space.empty?
        counter += 1
        surface.setName("temp #{counter}")
      else
        # issue warning about orphan surface, and delete it (could add argument to control this)
        runner.registerWarning("#{surface.name} does not have a space and will be removed from the model.")
        surface.remove
      end
    end

    # array of alpha characters to use in surface names
    suffix = ('a'..'z').to_a

    # give final names to surfaces and sub-surfaces
    surfaces = model.getSurfaces # added so don't loop through removed orphan surfaces
    surfaces.each do |surface|
      # get parent name

      # space name, surface type and azimuth
      space_name = surface.space.get.name
      surface_type = surface.surfaceType
      surface_azimuth = OpenStudio::Quantity.new(surface.azimuth, OpenStudio.createSIAngle)
      surface_azimuth = OpenStudio.convert(surface_azimuth, OpenStudio.createIPAngle).get.value
      surface_azimuth = format('%03d', surface_azimuth.round)
      if surface_azimuth == '360' then surface_azimuth = '0' end
      if surface_type == 'Wall'
        base_name = "#{space_name} - #{surface_type} #{surface_azimuth}"
      else
        base_name = "#{space_name} - #{surface_type}"
      end

      # rename (need loop to address more than one surface in space with same type and azimuth)
      counter = 0
      until suffix.include?(surface.name.get.reverse[0, 1]) # keep going until there is an alpha character at the end
        alpha = counter % 26 # gives me alpha character to use for name
        if counter > 25 # this is to address spaces with more than 26 surfaces with same azimuth. Adds second leading alpha character
          alpha2 = (counter / 26).truncate - 1
          surface.setName("#{base_name}:#{suffix[alpha2]}#{suffix[alpha]}")
        else
          surface.setName("#{base_name}:#{suffix[alpha]}") # this will be name until more than 26
        end
        counter += 1
      end
    end

    # give temp names to sub-surfaces so there are no conflicts if this is re-run more than once.
    counter = 0
    subSurfaces = model.getSubSurfaces # need to ask this a second time because some sub-surfaces may have been deleted with base surfaces
    subSurfaces.each do |subSurface|
      if !subSurface.surface.empty?
        counter += 1
        subSurface.setName("temp #{counter}")
      else
        # issue warning about orphan surface, and delete it (could add argument to control this)
        runner.registerWarning("#{subSurface.name} does not have a parent surface and will be removed from the model.")
        subSurface.remove
      end
    end

    # give final names to surfaces and sub-surfaces
    subSurfaces = model.getSubSurfaces # need to ask this again so don't loop through removed orphaned sub-surfaces
    subSurfaces.each do |subSurface|
      # get parent name

      # space name, surface type and azimuth
      surface_name = subSurface.surface.get.name

      base_name = "#{surface_name} - Sub"

      # rename (need loop to address more than one surface in space with same type and azimuth)
      counter = 0
      until suffix.include?(subSurface.name.get.reverse[0, 1]) # keep going until there is an alpha character at the end
        alpha = counter % 26 # gives me alpha character to use for name
        if counter > 25 # this is to address spaces with more than 26 surfaces with same azimuth. Adds second leading alpha character
          alpha2 = (counter / 26).truncate - 1
          subSurface.setName("#{base_name}:#{suffix[alpha2]}#{suffix[alpha]}")
        else
          subSurface.setName("#{base_name}:#{suffix[alpha]}") # this will be name until more than 26
        end
        counter += 1
      end
    end

    # TODO: - also rename shading surfaces, and try and maintain namings matched to windows by using overhang script.

    # reporting final condition of model
    runner.registerFinalCondition('All space surfaces and sub-surfaces have been renamed.')

    return true
  end
end

# this allows the measure to be use by the application
RenameSpaceSurfacesBasedonParentSpaceandOrientation.new.registerWithApplication
