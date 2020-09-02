# insert your copyright here

# see the URL below for information on how to write OpenStudio measures
# http://nrel.github.io/OpenStudio-user-documentation/reference/measure_writing_guide/

# start the measure
class AlterDOESchoolSummerVacation < OpenStudio::Measure::ModelMeasure
  # human readable name
  def name
    # Measure name should be the title case of the class name.
    return 'Alter DOE School Summer Vacation'
  end

  # human readable description
  def description
    return 'This measure will alter seasonal components of schedules that already have rules in place for seasonal adjustments.  Initially it just shortens summery vacation, but could be updated to lengthen it. Can be generalized in future to measure named Shift Existing Seasonal Schedule Rules.'
  end

  # human readable description of modeling approach
  def modeler_description
    return 'Initial use is to change summer vacations in primary and secondary school. Primary input will be number of months long the school year is. This is meant to be used on DOE prototype schedules which represent a 10 month school year. 11 or 12 month input will shorten or remove the summer break. Shortening from the end of the break leaving the beginning un-touched. If this measure is run on unexpected models it will not have the desired impact.'
  end

  # define the arguments that the user will input
  def arguments(model)
    args = OpenStudio::Measure::OSArgumentVector.new

    # argument for months_school
    months_school = OpenStudio::Measure::OSArgument.makeDoubleArgument('months_school', true)
    months_school.setDisplayName('Number of Months per Year School is in Session')
    months_school.setDescription('This name will be used as the name of the new space.')
    args << months_school

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
    months_school = runner.getDoubleArgumentValue('months_school', user_arguments)
    assumed_starting_months_school = 10

    # check the space_name for reasonableness
    if months_school < 10 || months_school > 12
      runner.registerError('We currnetly only spport shortening summer vacation. Please enter 10-12 months as an ainput for Number of Months in School Year.')
      return false
    end

    # round to integer for now but could support double in future.
    orig_val = months_school
    months_school = months_school.truncate
    if orig_val != months_school.to_f
      runner.registerInfo("Currently just support whole months, converting #{orig_val} to #{months_school}.")
    end

    # setup test date and end of year date
    yd = model.getYearDescription
    threshold_date = yd.makeDate(7, 15) # only change dates later than this
    end_year_date = yd.makeDate(12, 31)

    # store string of dates for initial and final model reporting
    # todo - need to pad so sort works
    orig_rule_day_months = []
    final_rule_day_months = []

    # loop through ruleset scheduels and 
    model.getScheduleRulesets.each do |schedule|
      # loop through rules
      schedule.scheduleRules.each do |rule|
        # while file has month and day for rule the API has an OpenStudio:date object for startDate and endDate

        # inspect start date of rule
        if rule.startDate.is_initialized
          orig_date = rule.startDate.get
          orig_rule_day_months << "#{orig_date}"

          # test and change date
          # todo - could add logic to skip if months_school is 10 but should not change if it passes through.
          if orig_date > threshold_date && orig_date < end_year_date

            # note: tried to change month and date but that can result in invalid dates
            # Changing month only can result in invalid date such as Bad Date: year = 2006, month = Jun(6), day = 31
            # switched to using day of year but kept this so can be used later of extra code to validate date is added
            #
            #orig_month = orig_date.monthOfYear.value
            #orig_day = orig_date.dayOfMonth
            #new_month = orig_month - (months_school - 10)
            #new_date = yd.makeDate(new_month, orig_day)
            
            orig_day_of_year = orig_date.dayOfYear
            new_day_of_year = (orig_day_of_year - (30.5 * (months_school - assumed_starting_months_school).truncate)).to_i
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
          # todo - could add logic to skip if months_school is 10 but should not change if it passes through.
          if orig_date > threshold_date && orig_date < end_year_date
 
            orig_day_of_year = orig_date.dayOfYear
            new_day_of_year = (orig_day_of_year - (30.5 * (months_school - assumed_starting_months_school).truncate)).to_i
            new_date = OpenStudio::Date::fromDayOfYear(new_day_of_year)
            rule.setStartDate(new_date)
            runner.registerInfo("Changing end date for #{rule.name} #{orig_date} to #{new_date}")

          end

          # store final dates (request from rule again instead of using orig_date variable)
          final_rule_day_months << "#{rule.endDate.get}"
        end

      end
    end

    # report initial condition of model
    # todo - sort doesn't work on array of OpenStuiod:date objects chronologically, may have to process that if weant to clean up message.
    runner.registerInitialCondition("Initial rule dates found in ruleset scheduels are #{orig_rule_day_months.sort.uniq.join(",")}.")

    # report final condition of model
    # todo - sort doesn't work on array of OpenStuiod:date objects chronologically, may have to process that if weant to clean up message.
    runner.registerFinalCondition("Final rule dates found in ruleset scheduels are #{final_rule_day_months.sort.uniq.join(",")}.")

    return true
  end
end

# register the measure to be used by the application
AlterDOESchoolSummerVacation.new.registerWithApplication
