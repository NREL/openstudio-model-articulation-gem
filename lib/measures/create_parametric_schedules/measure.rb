# *******************************************************************************
# OpenStudio(R), Copyright (c) 2008-2019, Alliance for Sustainable Energy, LLC.
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
# http://nrel.github.io/OpenStudio-user-documentation/reference/measure_writing_guide/

require 'json'

begin
  #load OpenStudio measure libraries from common location
  require 'measure_resources/os_lib_helper_methods'
  require 'measure_resources/os_lib_schedules'
  require 'measure_resources/os_lib_parametric_schedules'
rescue LoadError
  # common location unavailable, load from local resources
  require_relative 'resources/os_lib_helper_methods'
  require_relative 'resources/os_lib_schedules'
  require_relative 'resources/os_lib_parametric_schedules'
end

# start the measure
class CreateParametricSchedules < OpenStudio::Ruleset::ModelUserScript

  # resource file modules
  include OsLib_HelperMethods
  include OsLib_Schedules

  # human readable name
  def name
    return "Create Parametric Schedules"
  end

  # human readable description
  def description
    return "Create parametric schedules for internal loads and HVAC availability. Replace existing schedules in model with newly generated schedules. New schedules along with hours of operation schedule will go in a building level schedule set."
  end

  # human readable description of modeling approach
  def modeler_description
    return "This measure doesn't alter existing schedules. It only creates new schedules to replace them. Do this by creating a building level schedule set and removing all schedules from instances. HVAC schedules and thermostats will have to be applied differently."
  end

  # define the arguments that the user will input
  def arguments(model)
    args = OpenStudio::Ruleset::OSArgumentVector.new

    # Make argument for hoo_start_wkdy
    hoo_start_wkdy = OpenStudio::Ruleset::OSArgument.makeDoubleArgument("hoo_start_wkdy", true)
    hoo_start_wkdy.setDisplayName("Hours of Operation Start - Weekday")
    hoo_start_wkdy.setDescription("Energy 24 hour values with fractional values converted to minutes. e.g. 17.25 = 5:15pm.")
    hoo_start_wkdy.setUnits("Hours")
    hoo_start_wkdy.setDefaultValue(9.0)
    args << hoo_start_wkdy

    # Make argument for hoo_end_wkdy
    hoo_end_wkdy = OpenStudio::Ruleset::OSArgument.makeDoubleArgument("hoo_end_wkdy", true)
    hoo_end_wkdy.setDisplayName("Hours of Operation End - Weekday")
    hoo_end_wkdy.setDescription("If Hours of Operation End matches Hours of Operation Start it will be assumed to be 0 hours vs. 24.0")
    hoo_end_wkdy.setUnits("Hours")
    hoo_end_wkdy.setDefaultValue(17.0)
    args << hoo_end_wkdy

    # Make argument for hoo_start_sat
    hoo_start_sat = OpenStudio::Ruleset::OSArgument.makeDoubleArgument("hoo_start_sat", true)
    hoo_start_sat.setDisplayName("Hours of Operation Start - Saturday")
    hoo_start_sat.setDescription("Energy 24 hour values with fractional values converted to minutes. e.g. 17.25 = 5:15pm.")
    hoo_start_sat.setUnits("Hours")
    hoo_start_sat.setDefaultValue(9.0)
    args << hoo_start_sat

    # Make argument for hoo_end_sat
    hoo_end_sat = OpenStudio::Ruleset::OSArgument.makeDoubleArgument("hoo_end_sat", true)
    hoo_end_sat.setDisplayName("Hours of Operation End - Saturday")
    hoo_end_sat.setUnits("Hours")
    hoo_end_sat.setDefaultValue(12.0)
    args << hoo_end_sat

    # Make argument for hoo_start_sun
    hoo_start_sun = OpenStudio::Ruleset::OSArgument.makeDoubleArgument("hoo_start_sun", true)
    hoo_start_sun.setDisplayName("Hours of Operation Start - Sunday")
    hoo_start_sun.setDescription("Energy 24 hour values with fractional values converted to minutes. e.g. 17.25 = 5:15pm.")
    hoo_start_sun.setUnits("Hours")
    hoo_start_sun.setDefaultValue(7.0)
    args << hoo_start_sun

    # Make argument for hoo_end_sun
    hoo_end_sun = OpenStudio::Ruleset::OSArgument.makeDoubleArgument("hoo_end_sun", true)
    hoo_end_sun.setDisplayName("Hours of Operation End - Sunday")
    hoo_end_sun.setDescription("Energy 24 hour values with fractional values converted to minutes. e.g. 17.25 = 5:15pm.")
    hoo_end_sun.setUnits("Hours")
    hoo_end_sun.setDefaultValue(18.0)
    args << hoo_end_sun

    # Make argument for hoo_per_week
    hoo_per_week = OpenStudio::Ruleset::OSArgument.makeDoubleArgument("hoo_per_week", true)
    hoo_per_week.setDisplayName("Hours of Operation Per Week")
    hoo_per_week.setDescription("If this is a non zero value it will override all of the other hours of operations inputs, however the base hours and profile shapes for weekday will be starting point to define center of day to expand/contract from.")
    hoo_per_week.setUnits("Hours")
    hoo_per_week.setDefaultValue(0.0)
    args << hoo_per_week

    # make argument for valid_building_names
    valid_building_names = OpenStudio::Ruleset::OSArgument.makeStringArgument("valid_building_names", true)
    valid_building_names.setDisplayName("Comma Separated List of Valid Building Names To Alter.")
    valid_building_names.setDescription("This measure will only alter building names which exactly match one of the commera separted building names. Currently this check is not case sensitive. Leading or spaces from the comma separted values will be removed for comparision. An empty string will apply this to buildings of any name")
    valid_building_names.setDefaultValue("")
    args << valid_building_names

    # make argument for standards_building_type
    standards_building_type = OpenStudio::Ruleset::OSArgument.makeStringArgument("standards_building_type", true)
    standards_building_type.setDisplayName("Only alter Space Types with this Standards Building Type")
    standards_building_type.setDescription("Pick valid Standards Building Type name. An empty string won't filter out any space types by Standards Building Type value.")
    standards_building_type.setDefaultValue("")
    args << standards_building_type

    # make argument for standards_space_type
    standards_space_type = OpenStudio::Ruleset::OSArgument.makeStringArgument("standards_space_type", true)
    standards_space_type.setDisplayName("Only alter Space Types with this Standards Space Type")
    standards_space_type.setDescription("Pick valid Standards Space Type name. An empty string won't filter out any space types by Standards Space Type value.")
    standards_space_type.setDefaultValue("")
    args << standards_space_type

    # Make argument for lighting_profiles
    string = []
    string << ":default => [[start-2,0.1],[start-1,0.3],[start,0.75],[end,0.75],[end+2,0.3],[end+vac*0.5,0.1]]"
    string << ":saturday => [[start-1,0.1],[start,0.3],[end,0.3],[end+1,0.1]]"
    string << ":sunday => [[start,0.1],[end,0.1]]"
    lighting_profiles = OpenStudio::Ruleset::OSArgument.makeStringArgument("lighting_profiles", true)
    lighting_profiles.setDisplayName("Lighting Profiles")
    lighting_profiles.setDefaultValue(string.join(", "))
    args << lighting_profiles

    # Make argument for electric_equipment_profiles
    string = []
    string << ":default => [[start-1,0.3],[start,0.85],[start+0.5*occ-0.5,0.85],[start+0.5*occ-0.5,0.75],[start+0.5*occ+0.5,0.75],[start+0.5*occ+0.5,0.85],[end,0.85],[end+1,0.45],[end+2,0.3]]"
    string << ":saturday => [[start-2,0.2],[start,0.35],[end,0.35],[end+6,0.2]]"
    string << ":sunday => [[start,0.2],[end,0.2]]"
    electric_equipment_profiles = OpenStudio::Ruleset::OSArgument.makeStringArgument("electric_equipment_profiles", true)
    electric_equipment_profiles.setDisplayName("Electric Equipment Profiles")
    electric_equipment_profiles.setDefaultValue(string.join(", "))
    args << electric_equipment_profiles

    # make argument for EPD
    # todo - add code using this arg
    electric_equipment_value = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("electric_equipment_value",true)
    electric_equipment_value.setDisplayName("Target Electric Power Density.")
    electric_equipment_value.setUnits("W/ft^2")
    electric_equipment_value.setDefaultValue(0.0)
    args << electric_equipment_value

    # make choice argument on what to do for plug loads
    # todo - add code using this arg
    choices = OpenStudio::StringVector.new
    choices << "Do Nothing"
    choices << "Replace schedules for existing load instances"
    choices << "Replace load definitions for existing load instances" # should also reset multiplier
    choices << "Replace schedules and load definitions for existing load instances" # should also reset multiplier
    choices << "Add new load instance and apply selected schedule and load density"
    electric_equipment_action = OpenStudio::Ruleset::OSArgument::makeChoiceArgument("electric_equipment_action", choices,true)
    electric_equipment_action.setDisplayName("Select desired electric equipment action")
    electric_equipment_action.setDescription("Schedules and or load values from earlier arguments may be ignored depending on what is selected for this action.")
    electric_equipment_action.setDefaultValue("Replace schedules for existing load instances")
    args << electric_equipment_action

    # Make argument for gas_equipment_profiles
    string = []
    string << ":default => [[start-1,0.3],[start,0.85],[start+0.5*occ-0.5,0.85],[start+0.5*occ-0.5,0.75],[start+0.5*occ+0.5,0.75],[start+0.5*occ+0.5,0.85],[end,0.85],[end+1,0.45],[end+2,0.3]]"
    string << ":saturday => [[start-2,0.2],[start,0.35],[end,0.35],[end+6,0.2]]"
    string << ":sunday => [[start,0.2],[end,0.2]]"
    gas_equipment_profiles = OpenStudio::Ruleset::OSArgument.makeStringArgument("gas_equipment_profiles", true)
    gas_equipment_profiles.setDisplayName("Gas Equipment Profiles")
    gas_equipment_profiles.setDefaultValue(string.join(", "))
    args << gas_equipment_profiles

    # Make argument for occupancy_profiles
    string = []
    string << ":default => [[start-3,0],[start-1,0.2],[start,0.95],[start+0.5*occ-0.5,0.95],[start+0.5*occ-0.5,0.5],[start+0.5*occ+0.5,0.5],[start+0.5*occ+0.5,0.95],[end,0.95],[end+1,0.3],[end+vac*0.4,0]]"
    string << ":saturday => [[start-3,0],[start,0.3],[end,0.3],[end+1,0.1],[end+vac*0.3,0]]"
    string << ":sunday => [[start,0],[start,0.05],[end,0.05],[end,0]]"
    occupancy_profiles = OpenStudio::Ruleset::OSArgument.makeStringArgument("occupancy_profiles", true)
    occupancy_profiles.setDisplayName("Occupancy Profiles")
    occupancy_profiles.setDefaultValue(string.join(", "))
    args << occupancy_profiles

    # note: infiltration, setpoints, and hvac availability follow the same time parameters but use different values

    # Make argument for infiltration_profiles
    string = []
    string << ":default => [[start,1],[start,0.25],[end+vac*0.35,0.25],[end+vac*0.35,1]]"
    string << ":saturday => [[start,1],[start,0.25],[end+vac*0.25,0.25],[end+vac*0.25,1]]"
    string << ":sunday => [[start,1],[start,0.25],[end+vac*0.25,0.25],[end+vac*0.25,1]]"
    infiltration_profiles = OpenStudio::Ruleset::OSArgument.makeStringArgument("infiltration_profiles", true)
    infiltration_profiles.setDisplayName("Infiltration Profiles")
    infiltration_profiles.setDefaultValue(string.join(", "))
    args << infiltration_profiles

    # todo - update thermostat setback so user can customize heating and cooling setbacks to vary from HVAC availability
    # Make argument for thermostat_setback_profiles
    string = []
    string << ":default => [[start-2,floor],[start-2,ceiling],[end+vac*0.35,ceiling],[end+vac*0.35,floor]]"
    string << ":saturday => [[start-2,floor],[start-2,ceiling],[end+vac*0.25,ceiling],[end+vac*0.25,floor]]"
    string << ":sunday => [[start-2,floor],[start-2,ceiling],[end+vac*0.25,ceiling],[end+vac*0.25,floor]]"
    thermostat_setback_profiles = OpenStudio::Ruleset::OSArgument.makeStringArgument("thermostat_setback_profiles", true)
    thermostat_setback_profiles.setDisplayName("Thermostat Setback Profiles")
    thermostat_setback_profiles.setDefaultValue(string.join(", "))
    args << thermostat_setback_profiles

    # Make argument for heating_setpoint
    htg_setpoint = OpenStudio::Ruleset::OSArgument.makeDoubleArgument("htg_setpoint", true)
    htg_setpoint.setDisplayName("Heating Setpoint During Occupied Hours")
    htg_setpoint.setUnits("F")
    htg_setpoint.setDefaultValue(67.0)
    args << htg_setpoint

    # Make argument for vac_setpoint
    clg_setpoint = OpenStudio::Ruleset::OSArgument.makeDoubleArgument("clg_setpoint", true)
    clg_setpoint.setDisplayName("Cooling Setpoint During Occupied Hours")
    clg_setpoint.setUnits("F")
    clg_setpoint.setDefaultValue(75.0)
    args << clg_setpoint

    # Make argument for setback_delta
    setback_delta = OpenStudio::Ruleset::OSArgument.makeDoubleArgument("setback_delta", true)
    setback_delta.setDisplayName("Thermostat Setback Delta During Unoccupied Hours")
    setback_delta.setUnits("F")
    setback_delta.setDefaultValue(4)
    args << setback_delta

    # Make argument for hvac_availability_profiles
    string = []
    string << ":default => [[start,0],[start,1],[end+vac*0.35,1],[end+vac*0.35,0]]"
    string << ":saturday => [[start,0],[start,1],[end+vac*0.25,1],[end+vac*0.25,0]]"
    string << ":sunday => [[start,0],[start,1],[end+vac*0.25,1],[end+vac*0.25,0]]"
    hvac_availability_profiles = OpenStudio::Ruleset::OSArgument.makeStringArgument("hvac_availability_profiles", true)
    hvac_availability_profiles.setDisplayName("HVAC availability Profiles")
    hvac_availability_profiles.setDefaultValue(string.join(", "))
    args << hvac_availability_profiles

    # make argument for swh_profiles
    string = []
    string << ":default => [[start-2,0],[start-2,0.07],[start+0.5*occ,0.57],[vac-2,0.33],[vac,0.44],[end+vac*0.35,0.05],[end+vac*0.35,0]]"
    string << ":saturday => [[start-2,0],[start-2,0.07],[start+0.5*occ,0.23],[end+vac*0.25,0.05],[end+vac*0.25,0]]"
    string << ":sunday => [[start-2,0],[start-2,0.04],[start+0.5*occ,0.09],[end+vac*0.25,0.04],[end+vac*0.25,0]]"
    swh_profiles = OpenStudio::Ruleset::OSArgument.makeStringArgument("swh_profiles", true)
    swh_profiles.setDisplayName("Service Water Heating Profiles")
    swh_profiles.setDefaultValue(string.join(", "))
    args << swh_profiles

    # Make argument swh bool
    alter_swh_wo_space = OpenStudio::Ruleset::OSArgument.makeBoolArgument("alter_swh_wo_space", true)
    alter_swh_wo_space.setDisplayName("Apply to un-assigned Service Water Equipment Instances.")
    alter_swh_wo_space.setDescription("When applying profiles to sub-set of space types in the building, setting to true will apply these profiles to water use equipment instances that are not assigned to a space.")
    alter_swh_wo_space.setDefaultValue(true)
    args << alter_swh_wo_space

    # Make argument for ramp_frequency
    ramp_frequency = OpenStudio::Ruleset::OSArgument.makeDoubleArgument("ramp_frequency", true)
    ramp_frequency.setDisplayName("Ramp Frequency")
    ramp_frequency.setUnits("Hours")
    ramp_frequency.setDefaultValue(0.5)
    args << ramp_frequency

    # Make argument for error_on_out_of_order
    error_on_out_of_order = OpenStudio::Ruleset::OSArgument.makeBoolArgument("error_on_out_of_order", true)
    error_on_out_of_order.setDisplayName("Error on Out of Order Processed Profiles.")
    error_on_out_of_order.setDescription("When set to false, out of order profile times trigger a warning, but the measure will attempt to reconsile the conflict by moving the problematic times.")
    error_on_out_of_order.setDefaultValue(false)
    args << error_on_out_of_order

    return args
  end

  # define what happens when the measure is run
  def run(model, runner, user_arguments)
    super(model, runner, user_arguments)

    # assign the user inputs to variables
    args = OsLib_HelperMethods.createRunVariables(runner, model,user_arguments, arguments(model))
    if !args then return false end

    # create array from argument, clean up and check if measure should alter model
    valid_building_names = []
    args['valid_building_names'].split(",").each do |name|
      valid_building_names = name.downcase.strip
    end
    if not valid_building_names.include?(model.getBuilding.name.to_s.downcase) and args['valid_building_names'] != ''
      runner.registerAsNotApplicable("#{model.getBuilding.name} isn't listed as building to apply measure to. Model won't be altered")
      return true
    end

    # look at upstream measure for 'hoo_per_week' argument
    hoo_per_week_from_osw = OsLib_HelperMethods.check_upstream_measure_for_arg(runner, 'hoo_per_week')
    if hoo_per_week_from_osw.size > 0
      runner.registerInfo("Replacing argument named 'hoo_per_week' from current measure with a value of #{hoo_per_week_from_osw[:value]} from #{hoo_per_week_from_osw[:measure_name]}.")
      args['hoo_per_week'] = hoo_per_week_from_osw[:value].to_f
    end

    # todo - add in input error checking
    if args['hoo_per_week'] > 0.0
      runner.registerInfo("Hours per week input was a non zero value, it will override the user intered hours of operation for weekday, saturday, and sunday")
    end

    param_Schedules = OsLib_Parametric_Schedules.new
    param_Schedules.override_hours_per_week(args['hoo_per_week'], args['hoo_start_wkdy'], args['hoo_end_wkdy'], args['hoo_start_sat'], args['hoo_end_sat'], args['hoo_start_sun'], args['hoo_end_sun'])

    # report initial condition of model
    runner.registerInitialCondition("The building started with #{model.getSchedules.size} schedules.")

    param_Schedules.pre_process_space_types(args['standards_building_type'])

    param_Schedules.create_default_schedule_set

    param_Schedules.create_schedules_and_apply_default_schedule_set

    # report final condition of model
    runner.registerFinalCondition("The building finished with #{model.getSchedules.size} schedules.")

    return true

  end
end

# register the measure to be used by the application
CreateParametricSchedules.new.registerWithApplication
