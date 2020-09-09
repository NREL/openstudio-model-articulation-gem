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

# see the URL below for information on how to write OpenStudio measures
# http://openstudio.nrel.gov/openstudio-measure-writing-guide

# see the URL below for access to C++ documentation on model objects (click on "model" in the main window to view model objects)
# http://openstudio.nrel.gov/sites/openstudio.nrel.gov/files/nv_data/cpp_documentation_it/model/html/namespaces.html

# start the measure
class AlterWeekendSchedules < OpenStudio::Measure::ModelMeasure
  # define the name that a user will see, this method may be deprecated as
  # the display name in PAT comes from the name field in measure.xml
  def name
    return 'AlterWeekendSchedules'
  end

  # human readable description
  def description
    return 'This measure will alter weekend schedules to match a weekday (e.g. Monday) instead of the default DOE schedules, which are off on the weekends for schools and sometimes offices. In the future this measure could be replaced by an overall improvement in schedules used in the create_typical measure.'
  end

  # human readable description of modeling approach
  def modeler_description
    return 'Initial use is to change weekend schedules in schools and large offices for SEED project to follow weekday schedules instead of being off on weekends. Measure will loop through existing schedules and use the Monday schedules for Saturday and Sunday.'
  end

  # define the arguments that the user will input
  def arguments(model)
    args = OpenStudio::Measure::OSArgumentVector.new
    # initially starting with no arguments - we will assume Monday schedules are used to replace Saturday and Sunday schedules

    # argument for weekend_open_status
    weekend_open_status = OpenStudio::Measure::OSArgument.makeBoolArgument('weekend_open_status', true)
    weekend_open_status.setDisplayName('If the building is open on the weekend')
    weekend_open_status.setDescription('If the weekend open status is set to true the measure will run.')
    weekend_open_status.setDefaultValue(false)
    args << weekend_open_status

    return args
  end

  # define what happens when the measure is run
  def run(model, runner, user_arguments)
    super(model, runner, user_arguments)

    # use the built-in error checking
    if !runner.validateUserArguments(arguments(model), user_arguments)
      return false
    end

    # if weekend open status is true, proceed with measure. if not, skip measure.
    weekend_open_status = runner.getBoolArgumentValue('weekend_open_status', user_arguments)

    if weekend_open_status == false
      runner.registerWarning('The building is not open on the weekend, therefore schedules will not be altered and the default schedules will be used.')
      return false
    end

    # loop through ruleset schedules and
    model.getScheduleRulesets.each do |schedule|
      # loop through rules
      schedule.scheduleRules.each do |rule|
        puts "rules = #{rule.daySchedule}"
        if  rule.applyMonday == true
          monday_sch = rule.daySchedule
        end

      end
    end

    return true
  end
end

# this allows the measure to be use by the application
AlterWeekendSchedules.new.registerWithApplication
