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

# see the URL below for information on using life cycle cost objects in OpenStudio
# http://openstudio.nrel.gov/openstudio-life-cycle-examples

# see the URL below for access to C++ documentation on model objects (click on "model" in the main window to view model objects)
# http://openstudio.nrel.gov/sites/openstudio.nrel.gov/files/nv_data/cpp_documentation_it/model/html/namespaces.html

# start the measure
class AssignConstructionSetToBuilding < OpenStudio::Measure::ModelMeasure
  # define the name that a user will see, this method may be deprecated as
  # the display name in PAT comes from the name field in measure.xml
  def name
    return 'AssignConstructionSetToBuilding'
  end

  # define the arguments that the user will input
  def arguments(model)
    args = OpenStudio::Measure::OSArgumentVector.new

    # make a choice argument for model objects
    construction_set_handles = OpenStudio::StringVector.new
    construction_set_display_names = OpenStudio::StringVector.new

    # putting model object and names into hash
    construction_set_args = model.getDefaultConstructionSets
    construction_set_args_hash = {}
    construction_set_args.each do |construction_set_arg|
      construction_set_args_hash[construction_set_arg.name.to_s] = construction_set_arg
    end

    # looping through sorted hash of model objects
    construction_set_args_hash.sort.map do |key, value|
      construction_set_handles << value.handle.to_s
      construction_set_display_names << key
    end

    # add building to string vector with construction set
    building = model.getBuilding
    construction_set_handles << building.handle.to_s
    construction_set_display_names << '<clear field>'

    # make a choice argument for construction set
    construction_set = OpenStudio::Measure::OSArgument.makeChoiceArgument('construction_set', construction_set_handles, construction_set_display_names)
    construction_set.setDisplayName('Set the Default Construction Set for the Building.')
    construction_set.setDefaultValue('<clear field>') # if no construction set is chosen this field will be cleared out
    args << construction_set

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
    object = runner.getOptionalWorkspaceObjectChoiceValue('construction_set', user_arguments, model)

    # check the user_name for reasonableness
    clear_field = false
    construction_set = nil
    if object.empty?
      handle = runner.getStringArgumentValue('construction_set', user_arguments)
      if handle.empty?
        runner.registerError('No construction set was chosen.')
      else
        runner.registerError("The selected construction set with handle '#{handle}' was not found in the model. It may have been removed by another measure.")
      end
      return false
    else
      if !object.get.to_DefaultConstructionSet.empty?
        construction_set = object.get.to_DefaultConstructionSet.get
      elsif !object.get.to_Building.empty?
        clear_field = true
      else
        runner.registerError('Script Error - argument not showing up as construction set or building.')
        return false
      end
    end

    # reporting initial condition of model
    building = model.getBuilding
    defaultConstructionSet = building.defaultConstructionSet
    if !defaultConstructionSet.empty?
      runner.registerInitialCondition("The initial default construction set for the building is #{defaultConstructionSet.get.name}.")
    else
      runner.registerInitialCondition("The initial model doesn't have a default construction set for the building.")
    end

    # alter default construction set as requested
    if clear_field
      building.resetDefaultConstructionSet
    else
      building.setDefaultConstructionSet(construction_set)
    end

    # reporting final condition of model
    defaultConstructionSet = building.defaultConstructionSet
    if !defaultConstructionSet.empty?
      runner.registerFinalCondition("The final default construction set for the building is #{defaultConstructionSet.get.name}.")
    else
      runner.registerFinalCondition("The final model doesn't have a default construction set for the building.")
    end

    return true
  end
end

# this allows the measure to be use by the application
AssignConstructionSetToBuilding.new.registerWithApplication
