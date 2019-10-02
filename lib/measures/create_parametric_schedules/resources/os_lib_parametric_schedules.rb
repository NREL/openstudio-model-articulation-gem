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
require_relative 'os_lib_schedules.rb'
class OsLib_Parametric_Schedules
  def initialize(model, hoo_start_wkdy = 9.0, hoo_end_wkdy = 17.0, hoo_start_sat = 9.0, hoo_end_sat = 12.0, hoo_start_sun = 7.0, hoo_end_sun = 18.0,
                 error_on_out_of_order = false, ramp_frequency = 0.5, runner = nil)
    @space_types_to_alter = []
    @air_loops_to_alter = []
    @thermostats_to_alter = []
    @water_use_equipment_to_alter = [] # TODO: - populate
    @model = model
    @runner = runner
    @default_schedule_set = nil
    @profile_override = [] # add to this for day types that should use weekday instead of user entered profile
    @hoo_start_wkdy = hoo_start_wkdy
    @hoo_end_wkdy = hoo_end_wkdy
    @hoo_start_sat = hoo_start_sat
    @hoo_end_sat = hoo_end_sat
    @hoo_start_sun = hoo_start_sun
    @hoo_end_sun = hoo_end_sun
    @error_on_out_of_order = error_on_out_of_order
    @ramp_frequency = ramp_frequency
  end

  # make hash of out string argument in eval. Rescue if can't be made into hash
  def process_hash(string, ruleset_name)
    begin
      # temp code to make profile_hash from original commit work with updated process hash method that doesn't expose quotes or escape characters
      string = string.delete('{').delete('}')
      string = string.gsub('"weekday":"', ':default => ').gsub('"saturday":"', ':saturday => ').gsub('"sunday":"', ':sunday => ')
      string = string.gsub('\\"', '').delete('"')

      # remove any spaces
      string = string.delete(' ')

      # break up by day type
      temp_array = string.split(']],:')

      # if saturday or sunday don't exist or if over if hours per week over 60 or 72 hour threshold then copy default profile
      saturday = false
      sunday = false
      temp_array.each do |i|
        if i.include?('saturday') then saturday = true end
        if i.include?('sunday') then sunday = true end
      end
      if !(saturday && sunday)
        temp_array[0] = temp_array[0].gsub(']]', '')
      end

      if !saturday
        temp_array << temp_array[0].gsub(':default', 'saturday').gsub(']]', '')
      end
      if !sunday
        temp_array << "#{temp_array[0].gsub(':default', 'sunday').gsub(']]', '')}]]"
      end

      if @profile_override.include?('saturday')
        temp_array[1] = temp_array[0].gsub(':default', 'saturday').gsub(']]', '')
      end
      if @profile_override.include?('sunday')
        temp_array[2] = "#{temp_array[0].gsub(':default', 'sunday').gsub(']]', '')}]]"
      end

      # day_type specific gsub
      temp_array.each_with_index do |string, i|
        day_type = string.split('=>').first.delete(':')
        if day_type == 'default'
          hoo_start = @hoo_start_wkdy
          hoo_end = @hoo_end_wkdy
        elsif day_type == 'saturday'
          hoo_start = @hoo_start_sat
          hoo_end = @hoo_end_sat
        elsif day_type == 'sunday'
          hoo_start = @hoo_start_sun
          hoo_end = @hoo_end_sun
        end

        if hoo_end >= hoo_start
          occ = hoo_end - hoo_start
        else
          occ = 24.0 + hoo_end - hoo_start
        end
        vac = 24.0 - occ
        string = string.gsub('start', hoo_start.to_s)
        string = string.gsub('end', hoo_end.to_s)
        string = string.gsub('occ', occ.to_s)
        string = string.gsub('vac', vac.to_s)
        temp_array[i] = string
      end

      # re-assemble and convert to hash
      final_string = temp_array.join(']], :')

      hash = eval("{#{final_string}}").to_hash
    rescue SyntaxError => se
      if @runner.nil?
        puts "{#{final_string}} could not be converted to a hash."
      else
        @runner.registerError("{#{final_string}} could not be converted to a hash.")
      end
      return false
    end

    # continue to process hash and interpolate values
    hash.each do |day_type, time_value_pairs|
      # re-order so first value is lowest, and last is highest (need to adjust so no negative or > 24 values first)
      neg_time_hash = {}
      temp_min_time_hash = {}
      time_value_pairs.each_with_index do |pair, i|
        # if value  24 add it to 24 so it will go on tail end of profile
        # case when value is greater than 24 can be left alone for now, will be addressed
        if pair[0] < 0.0
          neg_time_hash[i] = pair[0]
          time = pair[0] + 24.0
          time_value_pairs[i][0] = time
        else
          time = pair[0]
        end
        temp_min_time_hash[i] = pair[0]
      end
      time_value_pairs.rotate!(temp_min_time_hash.key(temp_min_time_hash.values.min))

      # validate order, issue warning and correct if out of order
      last_time = nil
      throw_order_warning = false
      pre_fix_time_value_pairs = time_value_pairs.to_s
      time_value_pairs.each_with_index do |time_value_pair, i|
        if last_time.nil?
          last_time = time_value_pair[0]
        elsif time_value_pair[0] < last_time || neg_time_hash.key?(i)

          if @error_on_out_of_order
            if @runner.nil?
              puts "Pre-interpolated processed hash for #{ruleset_name} #{day_type} has one or more out of order conflicts: #{pre_fix_time_value_pairs}. Measure will stop because Error on Out of Order was set to true."
            else
              @runner.registerError("Pre-interpolated processed hash for #{ruleset_name} #{day_type} has one or more out of order conflicts: #{pre_fix_time_value_pairs}. Measure will stop because Error on Out of Order was set to true.")
            end
            return false
          end

          if neg_time_hash.key?(i)
            orig_current_time = time_value_pair[0]
            updated_time = 0.0
            last_buffer = 'NA'
          else
            # pick midpoint and put each time there. e.g. times of (2,7,9,8,11) would be changed to  (2,7,8.5,8.5,11)
            delta = last_time - time_value_pair[0]

            # determine much space can last item move
            if i < 2
              last_buffer = time_value_pairs[i - 1][0] # can move down to 0 without any issues
            else
              last_buffer = time_value_pairs[i - 1][0] - time_value_pairs[i - 2][0]
            end

            # center if possible but don't exceed available buffer
            updated_time = time_value_pairs[i - 1][0] - [delta / 2.0, last_buffer].min
          end

          # update values in array
          orig_current_time = time_value_pair[0]
          time_value_pairs[i - 1][0] = updated_time
          time_value_pairs[i][0] = updated_time

          # reporting mostly for diagnsotic purposes
          if @runner.nil?
            puts "For #{ruleset_name} #{day_type} profile item #{i} time was #{last_time} and item #{i + 1} time was #{orig_current_time}. Last buffer is #{last_buffer}. Changing both times to #{updated_time}."
          else
            @runner.registerInfo("For #{ruleset_name} #{day_type} profile item #{i} time was #{last_time} and item #{i + 1} time was #{orig_current_time}. Last buffer is #{last_buffer}. Changing both times to #{updated_time}.")
          end
          last_time = updated_time
          throw_order_warning = true

        else
          last_time = time_value_pair[0]
        end
      end

      # issue warning if order was changed
      if throw_order_warning
        if @runner.nil?
          puts "Pre-interpolated processed hash for #{ruleset_name} #{day_type} has one or more out of order conflicts: #{pre_fix_time_value_pairs}. Time values were adjusted as shown to crate a valid profile: #{time_value_pairs}"
        else
          @runner.registerWarning("Pre-interpolated processed hash for #{ruleset_name} #{day_type} has one or more out of order conflicts: #{pre_fix_time_value_pairs}. Time values were adjusted as shown to crate a valid profile: #{time_value_pairs}")
        end
      end

      # add interpolated values at ramp_frequency
      time_value_pairs.each_with_index do |time_value_pair, i|
        # store current and next time and value
        current_time = time_value_pair[0]
        current_value = time_value_pair[1]
        if i + 1 < time_value_pairs.size
          next_time = time_value_pairs[i + 1][0]
          next_value = time_value_pairs[i + 1][1]
        else
          # use time and value of first item
          next_time = time_value_pairs[0][0] + 24 # need to adjust values for beginning of array
          next_value = time_value_pairs[0][1]
        end
        step_delta = next_time - current_time

        # skip if time between values is 0 or less than ramp frequency
        next if step_delta <= @ramp_frequency

        # skip if next value is same
        next if current_value == next_value

        # add interpolated value to array
        interpolated_time = current_time + @ramp_frequency
        interpolated_value = next_value * (interpolated_time - current_time) / step_delta + current_value * (next_time - interpolated_time) / step_delta
        time_value_pairs.insert(i + 1, [interpolated_time, interpolated_value])
      end

      # remove second instance of time when there are two
      time_values_used = []
      items_to_remove = []
      time_value_pairs.each_with_index do |time_value_pair, i|
        if time_values_used.include? time_value_pair[0]
          items_to_remove << i
        else
          time_values_used << time_value_pair[0]
        end
      end
      items_to_remove.reverse.each do |i|
        time_value_pairs.delete_at(i)
      end

      # if time is > 24 shift to front of array and adjust value
      rotate_steps = 0
      time_value_pairs.reverse.each_with_index do |time_value_pair, i|
        if time_value_pair[0] > 24
          rotate_steps -= 1
          time_value_pair[0] -= 24
        else
          next
        end
      end
      time_value_pairs.rotate!(rotate_steps)

      # add a 24 on the end of array that matches the first value
      if time_value_pairs.last[0] != 24.0
        time_value_pairs << [24.0, time_value_pairs.first[1]]
      end

      # add on text needed for createComplexSchedule
      if day_type == :saturday
        time_value_pairs.insert(0, 'Sat')
        time_value_pairs.insert(0, '1/1-12/31')
        time_value_pairs.insert(0, 'Saturday')
      elsif day_type == :sunday
        time_value_pairs.insert(0, 'Sun')
        time_value_pairs.insert(0, '1/1-12/31')
        time_value_pairs.insert(0, 'Sunday')
      else # weekday
        time_value_pairs.insert(0, 'Default')
      end

      # update hash key to use processed time value pairs (gsub and then formula run)
      hash[day_type] = time_value_pairs
    end
    return hash
  end

  def override_hours_per_week(hoo_per_week = 0.0)
    # add in logic for hours per week override
    if hoo_per_week > 0.0
      if hoo_per_week > 84
        max_hoo = [hoo_per_week / 7.0, 24.0].min
      else
        max_hoo = 12.0
      end

      # for 60 horus per week or less only alter weekday. If longer then use weekday profiles for saturday for 12 hours and then sunday
      typical_weekday_input_hours = @hoo_end_wkdy - @hoo_start_wkdy
      target_weekday_hours = [hoo_per_week / 5.0, max_hoo].min
      delta_hours_per_day = target_weekday_hours - typical_weekday_input_hours

      # shift hours as needed
      @hoo_start_wkdy -= delta_hours_per_day / 2.0
      @hoo_end_wkdy += delta_hours_per_day / 2.0
      @runner.registerInfo("Adjusted hours of operation for weekday are from #{@hoo_start_wkdy} to #{@hoo_end_wkdy}.") if !@runner.nil?

      # add logic if more than 60 hours
      if hoo_per_week > 60.0
        # for 60-72 horus per week or less only alter saturday.
        typical_weekday_input_hours = @hoo_end_sat - @hoo_start_sat
        target_weekday_hours = [(hoo_per_week - 60.0), max_hoo].min
        delta_hours_per_day = target_weekday_hours - typical_weekday_input_hours

        # code in process_hash method will alter saturday to use default profile formula

        # shift hours as needed
        @hoo_start_sat -= delta_hours_per_day / 2.0
        @hoo_end_sat += delta_hours_per_day / 2.0
        @runner.registerInfo("Adjusted hours of operation for saturday are from #{@hoo_start_sat} to #{@hoo_end_sat}. Saturday will use typical weekday profile formula.") if !@runner.nil?

        # set flag to override typical profile
        @profile_override << 'saturday'
      end

      # add logic if more than 72 hours
      if hoo_per_week > 72.0
        # for 60-72 horus per week or less only alter sunday.
        typical_weekday_input_hours = @hoo_end_sun - @hoo_start_sun
        target_weekday_hours = [(hoo_per_week - 72.0), max_hoo].min
        delta_hours_per_day = target_weekday_hours - typical_weekday_input_hours

        # code in process_hash method will alter sunday to use default profile formula

        # shift hours as needed
        @hoo_start_sun -= delta_hours_per_day / 2.0
        @hoo_end_sun += delta_hours_per_day / 2.0
        @runner.registerInfo("Adjusted hours of operation for sunday are from #{@hoo_start_sun} to #{@hoo_end_sun}. Saturday will use typical weekday profile formula.") if !@runner.nil?

        # set flag to override typical profile
        @profile_override << 'sunday'
      end

    end
  end

  def pre_process_space_types(standards_building_type = '', standards_space_type = '')
    @model.getSpaceTypes.each do |space_type|
      if standards_building_type != ''
        next if !space_type.standardsBuildingType.is_initialized
        next if space_type.standardsBuildingType.get != standards_building_type
      end
      if standards_space_type != ''
        next if !space_type.standardsSpaceType.is_initialized
        next if space_type.standardsSpaceType.get != standards_space_type
      end
      next if space_type.spaces.empty?
      @space_types_to_alter << space_type
    end
  end

  def create_default_schedule_set(standards_building_type = '', standards_space_type = '', alter_swh_wo_space = true)
    # create shared default schedule set
    @default_schedule_set = OpenStudio::Model::DefaultScheduleSet.new(@model)
    @default_schedule_set.setName('Parametric Hours of Operation Schedule Set')

    # set building default if both standard building type and standard space type are not specified
    if (standards_building_type == '') && (standards_space_type == '')

      @runner.registerInfo('Altering schedules for all spaces.') if !@runner.nil?

      # remove schedule sets for load instances
      @model.getLightss.each(&:resetSchedule)
      @model.getElectricEquipments.each(&:resetSchedule)
      @model.getGasEquipments.each(&:resetSchedule)
      @model.getSpaceInfiltrationDesignFlowRates.each(&:resetSchedule)
      @model.getPeoples.each(&:resetNumberofPeopleSchedule)
      # don't have to remove HVAC and setpoint schedules, they will be replaced individually

      # remove schedule sets.
      @model.getDefaultScheduleSets.each do |sch_set|
        next if sch_set == @default_schedule_set
        sch_set.remove
      end

      # assign default schedule set to building level
      @model.getBuilding.setDefaultScheduleSet(@default_schedule_set)

      @thermostats_to_alter = @model.getThermostatSetpointDualSetpoints
      @air_loops_to_alter = @model.getAirLoopHVACs
      @water_use_equipment_to_alter = @model.getWaterUseEquipments

    else

      # apply schedule sets to space type
      space_types_to_alter.each do |space_type|
        @runner.registerInfo("Altering schedules for #{space_type.name}") if !@runner.nil?

        # remove schedule sets for load instances
        space_type.lights.each(&:resetSchedule)
        space_type.electricEquipment.each(&:resetSchedule)
        space_type.gasEquipment.each(&:resetSchedule)
        space_type.spaceInfiltrationDesignFlowRates.each(&:resetSchedule)
        space_type.people.each(&:resetNumberofPeopleSchedule)
        # don't have to remove HVAC and setpoint schedules, they will be replaced individually

        # set default schedule set for space type
        space_type.setDefaultScheduleSet(@default_schedule_set)

        # loop through spaces to populate thermostats and airloops
        space_type.spaces.each do |space|
          thermal_zone = space.thermalZone
          if thermal_zone.is_initialized
            thermal_zone = thermal_zone.get

            # get thermostat
            thermostat = thermal_zone.thermostatSetpointDualSetpoint
            if thermostat.is_initialized
              @thermostats_to_alter << thermostat.get
            end

            # get air loop
            air_loop = thermal_zone.airLoopHVAC
            if air_loop.is_initialized
              @air_loops_to_alter << air_loop.get
            end
          end

          # get water use equipment
          space.waterUseEquipment.each do |water_use_equipment|
            @water_use_equipment_to_alter << water_use_equipment
          end
        end
      end
    end
    # add water use equipment not assigned to space if requested
    if alter_swh_wo_space
      @model.getWaterUseEquipments.each do |water_use_equipment|
        next if water_use_equipment.space.is_initialized
        @water_use_equipment_to_alter << water_use_equipment
      end
    end
  end

  def create_schedules_and_apply_default_schedule_set(lighting_profiles = nil, electric_equipment_profiles = nil, gas_equipment_profiles = nil, occupancy_profiles = nil,
                                                      infiltration_profiles = nil, hvac_availability_profiles = nil, swh_profiles = nil, thermostat_setback_profiles = nil,
                                                      htg_setpoint = 67.0, clg_setpoint = 75.0, setback_delta = 4)
    # set the default profiles
    if lighting_profiles.nil?
      string = []
      string << ':default => [[start-2,0.1],[start-1,0.3],[start,0.75],[end,0.75],[end+2,0.3],[end+vac*0.5,0.1]]'
      string << ':saturday => [[start-1,0.1],[start,0.3],[end,0.3],[end+1,0.1]]'
      string << ':sunday => [[start,0.1],[end,0.1]]'
      lighting_profiles = string.join(', ')
    end
    if electric_equipment_profiles.nil?
      string = []
      string << ':default => [[start-1,0.3],[start,0.85],[start+0.5*occ-0.5,0.85],[start+0.5*occ-0.5,0.75],[start+0.5*occ+0.5,0.75],[start+0.5*occ+0.5,0.85],[end,0.85],[end+1,0.45],[end+2,0.3]]'
      string << ':saturday => [[start-2,0.2],[start,0.35],[end,0.35],[end+6,0.2]]'
      string << ':sunday => [[start,0.2],[end,0.2]]'
      electric_equipment_profiles = string.join(', ')
    end
    if gas_equipment_profiles.nil?
      string = []
      string << ':default => [[start-1,0.3],[start,0.85],[start+0.5*occ-0.5,0.85],[start+0.5*occ-0.5,0.75],[start+0.5*occ+0.5,0.75],[start+0.5*occ+0.5,0.85],[end,0.85],[end+1,0.45],[end+2,0.3]]'
      string << ':saturday => [[start-2,0.2],[start,0.35],[end,0.35],[end+6,0.2]]'
      string << ':sunday => [[start,0.2],[end,0.2]]'
      gas_equipment_profiles = string.join(', ')
    end
    if occupancy_profiles.nil?
      string = []
      string << ':default => [[start-3,0],[start-1,0.2],[start,0.95],[start+0.5*occ-0.5,0.95],[start+0.5*occ-0.5,0.5],[start+0.5*occ+0.5,0.5],[start+0.5*occ+0.5,0.95],[end,0.95],[end+1,0.3],[end+vac*0.4,0]]'
      string << ':saturday => [[start-3,0],[start,0.3],[end,0.3],[end+1,0.1],[end+vac*0.3,0]]'
      string << ':sunday => [[start,0],[start,0.05],[end,0.05],[end,0]]'
      occupancy_profiles = string.join(', ')
    end
    if infiltration_profiles.nil?
      string = []
      string << ':default => [[start,1],[start,0.25],[end+vac*0.35,0.25],[end+vac*0.35,1]]'
      string << ':saturday => [[start,1],[start,0.25],[end+vac*0.25,0.25],[end+vac*0.25,1]]'
      string << ':sunday => [[start,1],[start,0.25],[end+vac*0.25,0.25],[end+vac*0.25,1]]'
      infiltration_profiles = string.join(', ')
    end
    if hvac_availability_profiles.nil?
      string = []
      string << ':default => [[start,0],[start,1],[end+vac*0.35,1],[end+vac*0.35,0]]'
      string << ':saturday => [[start,0],[start,1],[end+vac*0.25,1],[end+vac*0.25,0]]'
      string << ':sunday => [[start,0],[start,1],[end+vac*0.25,1],[end+vac*0.25,0]]'
      hvac_availability_profiles = string.join(', ')
    end
    if swh_profiles.nil?
      string = []
      string << ':default => [[start-2,0],[start-2,0.07],[start+0.5*occ,0.57],[vac-2,0.33],[vac,0.44],[end+vac*0.35,0.05],[end+vac*0.35,0]]'
      string << ':saturday => [[start-2,0],[start-2,0.07],[start+0.5*occ,0.23],[end+vac*0.25,0.05],[end+vac*0.25,0]]'
      string << ':sunday => [[start-2,0],[start-2,0.04],[start+0.5*occ,0.09],[end+vac*0.25,0.04],[end+vac*0.25,0]]'
      swh_profiles = string.join(', ')
    end
    if thermostat_setback_profiles.nil?
      string = []
      string << ':default => [[start-2,floor],[start-2,ceiling],[end+vac*0.35,ceiling],[end+vac*0.35,floor]]'
      string << ':saturday => [[start-2,floor],[start-2,ceiling],[end+vac*0.25,ceiling],[end+vac*0.25,floor]]'
      string << ':sunday => [[start-2,floor],[start-2,ceiling],[end+vac*0.25,ceiling],[end+vac*0.25,floor]]'
      thermostat_setback_profiles = string.join(', ')
    end
    # create schedules and apply to default schedule set
    # populate hours of operation schedule for schedule set (this schedule isn't used but in future could be used to dynamically generate schedules)
    ruleset_name = 'Parametric Hours of Operation Schedule'
    winter_design_day = nil
    summer_design_day = nil
    rules = []
    if @hoo_end_wkdy == @hoo_start_wkdy
      default_day = ['Weekday', [@hoo_start_wkdy, 0], [@hoo_end_wkdy, 0], [24, 0]]
    elsif @hoo_end_wkdy > @hoo_start_wkdy
      default_day = ['Weekday', [@hoo_start_wkdy, 0], [@hoo_end_wkdy, 1], [24, 0]]
    else
      default_day = ['Weekday', [@hoo_end_wkdy, 1], [@hoo_start_wkdy, 0], [24, 1]]
    end
    if @hoo_end_sat == @hoo_start_sat
      rules << ['Saturday', '1/1-12/31', 'Sat', [@hoo_start_sat, 0], [@hoo_end_sat, 0], [24, 0]]
    elsif @hoo_end_sat > @hoo_start_sat
      rules << ['Saturday', '1/1-12/31', 'Sat', [@hoo_start_sat, 0], [@hoo_end_sat, 1], [24, 0]]
    else
      rules << ['Saturday', '1/1-12/31', 'Sat', [@hoo_end_sat, 1], [@hoo_start_sat, 0], [24, 1]]
    end
    if @hoo_end_sun == @hoo_start_sun
      rules << ['Sunday', '1/1-12/31', 'Sun', [@hoo_start_sun, 0], [@hoo_end_sun, 0], [24, 0]]
    elsif @hoo_end_sun > @hoo_start_sun
      rules << ['Sunday', '1/1-12/31', 'Sun', [@hoo_start_sun, 0], [@hoo_end_sun, 1], [24, 0]]
    else
      rules << ['Sunday', '1/1-12/31', 'Sun', [@hoo_end_sun, 1], [@hoo_start_sun, 0], [24, 1]]
    end
    options = { 'name' => ruleset_name,
                'winter_design_day' => winter_design_day,
                'summer_design_day' => summer_design_day,
                'default_day' => default_day,
                'rules' => rules }
    hoo_sch = OsLib_Schedules.createComplexSchedule(@model, options)
    @default_schedule_set.setHoursofOperationSchedule(hoo_sch)

    # create activity schedule
    # todo - save this from model or add user argument
    ruleset_name = 'Parametric Activity Schedule'
    winter_design_day = [[24, 120]]
    summer_design_day = [[24, 120]]
    default_day = ['Weekday', [24, 120]]
    rules = []
    options = { 'name' => ruleset_name,
                'winter_design_day' => winter_design_day,
                'summer_design_day' => summer_design_day,
                'default_day' => default_day,
                'rules' => rules }
    activity_sch = OsLib_Schedules.createComplexSchedule(@model, options)
    @default_schedule_set.setPeopleActivityLevelSchedule(activity_sch)

    # generate and apply lighting schedule using hours of operation schedule and parametric inputs
    ruleset_name = 'Parametric Lighting Schedule'
    hash = process_hash(lighting_profiles, ruleset_name)
    if !hash
      @runner.registerError("Failed to generate #{ruleset_name}") if !@runner.nil?
      return false
    end
    winter_design_day = [[24, 0]]
    summer_design_day = [[24, 1]]
    default_day = hash[:default]
    rules = []
    rules << hash[:saturday]
    rules << hash[:sunday]
    options = { 'name' => ruleset_name,
                'winter_design_day' => winter_design_day,
                'summer_design_day' => summer_design_day,
                'default_day' => default_day,
                'rules' => rules }

    lighting_sch = OsLib_Schedules.createComplexSchedule(@model, options)
    lighting_sch.setComment(lighting_profiles)
    @default_schedule_set.setLightingSchedule(lighting_sch)

    # generate and apply electric_equipment schedule using hours of operation schedule and parametric inputs
    ruleset_name = 'Parametric Electric Equipment Schedule'
    hash = process_hash(electric_equipment_profiles, ruleset_name)
    if !hash
      @runner.registerError("Failed to generate #{ruleset_name}") if !@runner.nil?
      return false
    end
    winter_design_day = [[24, 0]]
    summer_design_day = [[24, 1]]
    default_day = hash[:default]
    rules = []
    rules << hash[:saturday]
    rules << hash[:sunday]
    options = { 'name' => ruleset_name,
                'winter_design_day' => winter_design_day,
                'summer_design_day' => summer_design_day,
                'default_day' => default_day,
                'rules' => rules }
    electric_equipment_sch = OsLib_Schedules.createComplexSchedule(@model, options)
    electric_equipment_sch.setComment(electric_equipment_profiles)
    @default_schedule_set.setElectricEquipmentSchedule(electric_equipment_sch)

    # generate and apply gas_equipment schedule using hours of operation schedule and parametric inputs
    ruleset_name = 'Parametric Gas Equipment Schedule'
    hash = process_hash(gas_equipment_profiles, ruleset_name)
    if !hash
      @runner.registerError("Failed to generate #{ruleset_name}") if !@runner.nil?
      return false
    end
    winter_design_day = [[24, 0]]
    summer_design_day = [[24, 1]]
    default_day = hash[:default]
    rules = []
    rules << hash[:saturday]
    rules << hash[:sunday]
    options = { 'name' => ruleset_name,
                'winter_design_day' => winter_design_day,
                'summer_design_day' => summer_design_day,
                'default_day' => default_day,
                'rules' => rules }
    gas_equipment_sch = OsLib_Schedules.createComplexSchedule(@model, options)
    gas_equipment_sch.setComment(gas_equipment_profiles)
    @default_schedule_set.setGasEquipmentSchedule(gas_equipment_sch)

    # generate and apply occupancy schedule using hours of operation schedule and parametric inputs
    ruleset_name = 'Parametric Occupancy Schedule'
    hash = process_hash(occupancy_profiles, ruleset_name)
    if !hash
      @runner.registerError("Failed to generate #{ruleset_name}") if !@runner.nil?
      return false
    end
    winter_design_day = [[24, 0]] # if DCV would we want this at 1, prototype uses 0
    summer_design_day = [[24, 1]]
    default_day = hash[:default]
    rules = []
    rules << hash[:saturday]
    rules << hash[:sunday]
    options = { 'name' => ruleset_name,
                'winter_design_day' => winter_design_day,
                'summer_design_day' => summer_design_day,
                'default_day' => default_day,
                'rules' => rules }
    occupancy_sch = OsLib_Schedules.createComplexSchedule(@model, options)
    occupancy_sch.setComment(occupancy_profiles)
    @default_schedule_set.setNumberofPeopleSchedule(occupancy_sch)

    # generate and apply infiltration schedule using hours of operation schedule and parametric inputs
    ruleset_name = 'Parametric Infiltration Schedule'
    hash = process_hash(infiltration_profiles, ruleset_name)
    if !hash
      @runner.registerError("Failed to generate #{ruleset_name}") if !@runner.nil?
      return false
    end
    winter_design_day = [[24, 1]] # TODO: - should it be 1 for both summer and winter
    summer_design_day = [[24, 1]]
    default_day = hash[:default]
    rules = []
    rules << hash[:saturday]
    rules << hash[:sunday]
    options = { 'name' => ruleset_name,
                'winter_design_day' => winter_design_day,
                'summer_design_day' => summer_design_day,
                'default_day' => default_day,
                'rules' => rules }
    infiltration_sch = OsLib_Schedules.createComplexSchedule(@model, options)
    infiltration_sch.setComment(infiltration_profiles)
    @default_schedule_set.setInfiltrationSchedule(infiltration_sch)

    # generate and apply hvac_availability schedule using hours of operation schedule and parametric inputs
    ruleset_name = 'Parametric HVAC Availability Schedule'
    hash = process_hash(hvac_availability_profiles, ruleset_name)
    if !hash
      @runner.registerError("Failed to generate #{ruleset_name}") if !@runner.nil?
      return false
    end
    winter_design_day = [[24, 1]] # TODO: - confirm proper value
    summer_design_day = [[24, 1]] # todo - confirm proper value
    default_day = hash[:default]
    rules = []
    rules << hash[:saturday]
    rules << hash[:sunday]
    options = { 'name' => ruleset_name,
                'winter_design_day' => winter_design_day,
                'summer_design_day' => summer_design_day,
                'default_day' => default_day,
                'rules' => rules }
    hvac_availability_sch = OsLib_Schedules.createComplexSchedule(@model, options)
    hvac_availability_sch.setComment(hvac_availability_profiles)

    # apply HVAC schedules
    # todo - measure currently only replaces AirLoopHVAC.setAvailabilitySchedule)
    @air_loops_to_alter.each do |air_loop|
      air_loop.setAvailabilitySchedule(hvac_availability_sch)
    end

    # generate and apply heating_setpoint schedule using hours of operation schedule and parametric inputs
    ruleset_name = 'Parametric Heating Setpoint Schedule'

    # htg setpoints
    htg_occ = OpenStudio.convert(htg_setpoint, 'F', 'C').get
    htg_vac = OpenStudio.convert(htg_setpoint - setback_delta, 'F', 'C').get

    # replace floor and celing with user specified values
    htg_setpoint_profiles = thermostat_setback_profiles.gsub('ceiling', htg_occ.to_s)
    htg_setpoint_profiles = htg_setpoint_profiles.gsub('floor', htg_vac.to_s)

    # process hash
    hash = process_hash(htg_setpoint_profiles, ruleset_name)
    if !hash
      @runner.registerError("Failed to generate #{ruleset_name}") if !@runner.nil?
      return false
    end

    winter_design_day = hash[:default].drop(1) # [[24,htg_occ]]
    summer_design_day = hash[:default].drop(1) # [[24,htg_occ]]
    default_day = hash[:default]
    rules = []
    rules << hash[:saturday]
    rules << hash[:sunday]
    options = { 'name' => ruleset_name,
                'winter_design_day' => winter_design_day,
                'summer_design_day' => summer_design_day,
                'default_day' => default_day,
                'rules' => rules }
    heating_setpoint_sch = OsLib_Schedules.createComplexSchedule(@model, options)

    # generate and apply cooling_setpoint schedule using hours of operation schedule and parametric inputs
    ruleset_name = 'Parametric Cooling Setpoint Schedule'

    # clg setpoints
    clg_occ = OpenStudio.convert(clg_setpoint, 'F', 'C').get
    clg_vac = OpenStudio.convert(clg_setpoint + setback_delta, 'F', 'C').get

    # replace floor and celing with user specified values
    clg_setpoint_profiles = thermostat_setback_profiles.gsub('ceiling', clg_occ.to_s)
    clg_setpoint_profiles = clg_setpoint_profiles.gsub('floor', clg_vac.to_s)

    # process hash
    hash = process_hash(clg_setpoint_profiles, ruleset_name)
    if !hash
      @runner.registerError("Failed to generate #{ruleset_name}") if !@runner.nil?
      return false
    end

    winter_design_day = hash[:default].drop(1) # [[24,clg_occ]]
    summer_design_day = hash[:default].drop(1) # [[24,clg_occ]]
    default_day = hash[:default]
    rules = []
    rules << hash[:saturday]
    rules << hash[:sunday]
    options = { 'name' => ruleset_name,
                'winter_design_day' => winter_design_day,
                'summer_design_day' => summer_design_day,
                'default_day' => default_day,
                'rules' => rules }
    cooling_setpoint_sch = OsLib_Schedules.createComplexSchedule(@model, options)

    # apply heating and cooling setpoint schedules
    @thermostats_to_alter.each do |thermostat|
      thermostat.setHeatingSchedule(heating_setpoint_sch)
      thermostat.setCoolingSchedule(cooling_setpoint_sch)
    end

    # generate and apply water use equipment schedule using hours of operation schedule and parametric inputs
    ruleset_name = 'Parametric SWH Schedule'
    hash = process_hash(swh_profiles, ruleset_name)
    if !hash
      @runner.registerError("Failed to generate #{ruleset_name}") if !@runner.nil?
      return false
    end
    winter_design_day = hash[:default].drop(1)
    summer_design_day = hash[:default].drop(1)
    default_day = hash[:default]
    rules = []
    rules << hash[:saturday]
    rules << hash[:sunday]
    options = { 'name' => ruleset_name,
                'winter_design_day' => winter_design_day,
                'summer_design_day' => summer_design_day,
                'default_day' => default_day,
                'rules' => rules }
    swh_sch = OsLib_Schedules.createComplexSchedule(@model, options)
    swh_sch.setComment(swh_profiles)
    @water_use_equipment_to_alter.each do |water_use_equipment|
      water_use_equipment.setFlowRateFractionSchedule(swh_sch)
    end
  end
end
