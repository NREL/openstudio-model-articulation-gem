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
class FindAndReplaceObjectNames < OpenStudio::Measure::ModelMeasure
  # define the name that a user will see
  def name
    return 'Find and Replace Object Names in the Model'
  end

  # define the arguments that the user will input
  def arguments(model)
    args = OpenStudio::Measure::OSArgumentVector.new

    # make an argument for your name
    orig_string = OpenStudio::Measure::OSArgument.makeStringArgument('orig_string', true)
    orig_string.setDisplayName('Type the text you want search for in object names')
    orig_string.setDefaultValue('replace this text')
    args << orig_string

    # make an argument to add new space true/false
    new_string = OpenStudio::Measure::OSArgument.makeStringArgument('new_string', true)
    new_string.setDisplayName('Type the text you want to add in place of the found text')
    new_string.setDefaultValue('with this text')
    args << new_string

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
    orig_string = runner.getStringArgumentValue('orig_string', user_arguments)
    new_string = runner.getStringArgumentValue('new_string', user_arguments)

    # check the orig_string for reasonableness
    puts orig_string
    if orig_string == ''
      runner.registerError('No search string was entered.')
      return false
    end

    # reporting initial condition of model
    starting_spaces = model.getSpaces
    runner.registerInitialCondition("The model has #{model.objects.size} objects.")

    # array for objects with names
    named_objects = []

    # loop through model objects and rename if the object has a name
    model.objects.each do |obj|
      if !obj.name.empty?
        old_name = obj.name.get
        new_name = obj.setName(old_name.gsub(orig_string, new_string))
        if old_name != new_name
          named_objects << new_name
        end
      end
    end

    # reporting final condition of model
    runner.registerFinalCondition("#{named_objects.size} objects were renamed.")

    return true
  end
end

# this allows the measure to be use by the application
FindAndReplaceObjectNames.new.registerWithApplication
