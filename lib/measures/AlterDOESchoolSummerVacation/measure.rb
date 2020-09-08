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
class AlterDOESchoolSummerVacation < OpenStudio::Measure::ModelMeasure
  # define the name that a user will see, this method may be deprecated as
  # the display name in PAT comes from the name field in measure.xml
  def name
    return 'AlterDOESchoolSummerVacation'
  end

  # human readable description
  def description
    return 'This measure will alter seasonal components of schedules that already have rules in place for seasonal adjustments.  Initially it just shortens summer vacation, but could be updated to lengthen it. Can be generalized in future to measure named Shift Existing Seasonal Schedule Rules.'
  end

  # human readable description of modeling approach
  def modeler_description
    return 'Initial use is to change summer vacations in primary and secondary school. Primary input will be number of months long the school year is. This is meant to be used on DOE prototype schedules which represent a 10 month school year. 11 or 12 month input will shorten or remove the summer break. Shortening from the end of the break leaving the beginning un-touched. If this measure is run on unexpected models it will not have the desired impact.'
  end

  # define the arguments that the user will input
  def arguments(model)
    args = OpenStudio::Measure::OSArgumentVector.new

    # argument for months_open
    months_open = OpenStudio::Measure::OSArgument.makeDoubleArgument('months_open', true)
    months_open.setDisplayName('Number of Months per year school is in session')
    months_open.setDescription('This will be used to shorten the summer vacation from initial 2 months on DOE Prototype school schedules.')
    args << months_open

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
    months_open = runner.getDoubleArgumentValue('months_open', user_arguments)
    assumed_starting_months_open = 10

    # check the input for reasonableness
    if months_open < 10 || months_open > 12
      runner.registerWarning('We currently only support shortening summer vacation. Please enter 10-12 months as an input for Number of Months in School Year.')
      return false
    end

    # round to integer for now but could support double in future.
    orig_val = months_open
    months_open = months_open.truncate
    if orig_val != months_open.to_f
      runner.registerInfo("Currently just support whole months, converting #{orig_val} to #{months_open}.")
    end

    # setup test date and end of year date
    yd = model.getYearDescription
    threshold_date = yd.makeDate(7, 15) # only change dates later than this
    end_year_date = yd.makeDate(12, 31)

    # store string of dates for initial and final model reporting
    # todo - doesn't sort for reporting. may want to store as integer day of year and then convert to date if wanted for reporting
    orig_rule_day_months = []
    final_rule_day_months = []

    # loop through ruleset schedules and
    model.getScheduleRulesets.each do |schedule|
      # loop through rules
      schedule.scheduleRules.each do |rule|
        # while file has month and day for rule the API has an OpenStudio:date object for startDate and endDate

        # inspect start date of rule
        if rule.startDate.is_initialized
          orig_date = rule.startDate.get
          orig_rule_day_months << "#{orig_date}"

          # test and change date
          # todo - could add logic to skip if months_open is 10 but should not change if it passes through.
          if orig_date > threshold_date && orig_date < end_year_date

            # note: tried to change month and date but that can result in invalid dates
            # Changing month only can result in invalid date such as Bad Date: year = 2006, month = Jun(6), day = 31
            # switched to using day of year but kept this so can be used later of extra code to validate date is added
            #
            #orig_month = orig_date.monthOfYear.value
            #orig_day = orig_date.dayOfMonth
            #new_month = orig_month - (months_open - 10)
            #new_date = yd.makeDate(new_month, orig_day)

            orig_day_of_year = orig_date.dayOfYear
            new_day_of_year = orig_day_of_year - (30.5 * (months_open - assumed_starting_months_open)).truncate
            new_date = OpenStudio::Date::fromDayOfYear(new_day_of_year)
            rule.setStartDate(new_date)
            runner.registerInfo("Changing start date for #{rule.name} #{orig_date} to #{new_date}")

          end

          # store final dates (request from rule again instead of using orig_date variable)
          final_rule_day_months << "#{rule.startDate.get}"
        end

        # inspect end date for rule
        if rule.endDate.is_initialized
          orig_date = rule.endDate.get
          orig_rule_day_months << "#{orig_date}"

          # test and change
          # todo - could add logic to skip if months_open is 10 but should not change if it passes through.
          if orig_date > threshold_date && orig_date < end_year_date

            orig_day_of_year = orig_date.dayOfYear
            new_day_of_year = orig_day_of_year - (30.5 * (months_open - assumed_starting_months_open)).truncate
            new_date = OpenStudio::Date::fromDayOfYear(new_day_of_year)
            rule.setEndDate(new_date)
            runner.registerInfo("Changing end date for #{rule.name} #{orig_date} to #{new_date}")

          end

          # store final dates (request from rule again instead of using orig_date variable)
          final_rule_day_months << "#{rule.endDate.get}"
        end

      end
    end

    # report initial condition of model
    # todo - sort doesn't work on array of OpenStudio:date objects chronologically, may have to process that if we want to clean up message.
    runner.registerInitialCondition("Initial rule dates found in ruleset schedules are #{orig_rule_day_months.sort.uniq.join(",")}.")

    # report final condition of model
    # todo - sort doesn't work on array of OpenStudio:date objects chronologically, may have to process that if we want to clean up message.
    runner.registerFinalCondition("Final rule dates found in ruleset schedules are #{final_rule_day_months.sort.uniq.join(",")}.")

    return true
  end
end

# this allows the measure to be use by the application
AlterDOESchoolSummerVacation.new.registerWithApplication
