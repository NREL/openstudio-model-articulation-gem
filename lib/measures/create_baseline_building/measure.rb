# frozen_string_literal: true

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

# Start the measure
class CreateBaselineBuilding < OpenStudio::Measure::ModelMeasure
  require 'openstudio-standards'

  # Define the name of the Measure.
  def name
    return 'Create Baseline Building'
  end

  # Human readable description
  def description
    return 'Creates the Performance Rating Method baseline building.  For 90.1, this is the Appendix G aka LEED Baseline.  For India ECBC, this is the Appendix D Baseline.  Note: for 90.1, this model CANNOT be used for code compliance; it is not the same as the Energy Cost Budget baseline.'
  end

  # Human readable description of modeling approach
  def modeler_description
    return ''
  end

  # Define the arguments that the user will input.
  def arguments(model)
    args = OpenStudio::Measure::OSArgumentVector.new

    # Make an argument for the standard
    standard_chs = OpenStudio::StringVector.new
    # standard_chs << '90.1-2004'
    standard_chs << '90.1-2007 BETA'
    # 1.13.1 onward supports 90.1-2010
    if model.version > OpenStudio::VersionString.new('1.13.0')
      standard_chs << '90.1-2010 BETA'
    end
    standard_chs << '90.1-2013'
    # standard_chs << 'India ECBC 2007'
    standard = OpenStudio::Measure::OSArgument.makeChoiceArgument('standard', standard_chs, true)
    standard.setDisplayName('Standard')
    standard.setDefaultValue('90.1-2013')
    args << standard

    # Make an argument for the building type
    building_type_chs = OpenStudio::StringVector.new
    building_type_chs << 'MidriseApartment'
    building_type_chs << 'SecondarySchool'
    building_type_chs << 'PrimarySchool'
    building_type_chs << 'SmallOffice'
    building_type_chs << 'MediumOffice'
    building_type_chs << 'LargeOffice'
    building_type_chs << 'SmallHotel'
    building_type_chs << 'LargeHotel'
    building_type_chs << 'Warehouse'
    building_type_chs << 'RetailStandalone'
    building_type_chs << 'RetailStripmall'
    building_type_chs << 'QuickServiceRestaurant'
    building_type_chs << 'FullServiceRestaurant'
    building_type_chs << 'Hospital'
    building_type_chs << 'Outpatient'
    building_type = OpenStudio::Measure::OSArgument.makeChoiceArgument('building_type', building_type_chs, true)
    building_type.setDisplayName('Building Type.')
    building_type.setDefaultValue('SmallOffice')
    args << building_type

    # Make an argument for the climate zone
    climate_zone_chs = OpenStudio::StringVector.new
    climate_zone_chs << 'ASHRAE 169-2013-1A'
    climate_zone_chs << 'ASHRAE 169-2013-2A'
    climate_zone_chs << 'ASHRAE 169-2013-2B'
    climate_zone_chs << 'ASHRAE 169-2013-3A'
    climate_zone_chs << 'ASHRAE 169-2013-3B'
    climate_zone_chs << 'ASHRAE 169-2013-3C'
    climate_zone_chs << 'ASHRAE 169-2013-4A'
    climate_zone_chs << 'ASHRAE 169-2013-4B'
    climate_zone_chs << 'ASHRAE 169-2013-4C'
    climate_zone_chs << 'ASHRAE 169-2013-5A'
    climate_zone_chs << 'ASHRAE 169-2013-5B'
    climate_zone_chs << 'ASHRAE 169-2013-6A'
    climate_zone_chs << 'ASHRAE 169-2013-6B'
    climate_zone_chs << 'ASHRAE 169-2013-7A'
    climate_zone_chs << 'ASHRAE 169-2013-8A'
    # climate_zone_chs << 'India ECBC Composite'
    # climate_zone_chs << 'India ECBC Hot and Dry'
    # climate_zone_chs << 'India ECBC Warm and Humid'
    # climate_zone_chs << 'India ECBC Moderate'
    # climate_zone_chs << 'India ECBC Cold'
    climate_zone = OpenStudio::Measure::OSArgument.makeChoiceArgument('climate_zone', climate_zone_chs, true)
    climate_zone.setDisplayName('Climate Zone.')
    climate_zone.setDefaultValue('ASHRAE 169-2013-2A')
    args << climate_zone

    # Make an argument for the customization
    custom_chs = OpenStudio::StringVector.new
    custom_chs << 'Xcel Energy CO EDA'
    custom_chs << '*None*'
    custom = OpenStudio::Measure::OSArgument.makeChoiceArgument('custom', custom_chs, true)
    custom.setDisplayName('Customization')
    custom.setDescription('If selected, some of the standard process will be replaced by custom logic specific to particular programs.  If these do not apply to you, select None.')
    custom.setDefaultValue('*None*')
    args << custom

    # Make an argument for enabling debug messages
    debug = OpenStudio::Measure::OSArgument.makeBoolArgument('debug', true)
    debug.setDisplayName('Show debug messages?')
    debug.setDefaultValue(false)
    args << debug

    return args
  end

  # Define what happens when the measure is run.
  def run(model, runner, user_arguments)
    super(model, runner, user_arguments)

    # Use the built-in error checking
    if !runner.validateUserArguments(arguments(model), user_arguments)
      return false
    end

    # Assign the user inputs to variables that can be accessed across the measure
    building_type = runner.getStringArgumentValue('building_type', user_arguments)
    standard = runner.getStringArgumentValue('standard', user_arguments)
    climate_zone = runner.getStringArgumentValue('climate_zone', user_arguments)
    custom = runner.getStringArgumentValue('custom', user_arguments)
    debug = runner.getBoolArgumentValue('debug', user_arguments)

    # Convert custom to nil if necessary
    if custom == '*None*'
      custom = nil
    end

    # Strip BETA from the standard choice
    if standard.include?(' BETA')
      runner.registerWarning("You have chosen #{standard}, which is still under development.  It should generally be correct, but has not been heavily tested.  Please review the output messages closely.")
      standard = standard.gsub(' BETA', '')
    end

    # Open a channel to log info/warning/error messages
    @msg_log = OpenStudio::StringStreamLogSink.new
    if debug
      @msg_log.setLogLevel(OpenStudio::Debug)
    else
      @msg_log.setLogLevel(OpenStudio::Info)
    end
    @start_time = Time.new
    @runner = runner

    # Contact info for where to report issues
    contact = "While this Measure aims to be comprehensive and was tested against a suite of models of actual building designs, there are bound to be situations that it will not handle correctly.  It is your responsibility as a modeler to review the results of this Measure and adjust accordingly.  If you find issues (beyond those listed below), please <a href='https://github.com/NREL/openstudio-standards/issues'>report them here</a>.  Please include a detailed description, the proposed model, and references to the pertinent sections of 90.1, ASHRAE interpretations, or LEED interpretations."
    OpenStudio.logFree(OpenStudio::Info, 'openstudio.standards.Model', contact)

    # List of unsupported things
    us = []
    us << 'Lighting controls (occ/vac sensors) are assumed to already be present in proposed lighting schedules, and will not be added or removed'
    us << 'Exterior lighting in the baseline model is left as found in proposed'
    us << 'Optimal start of HVAC systems is not supported'
    us << 'Skylights are not added to model, but existing skylights are scaled per Appendix G skylight-to-roof areas'
    us << 'Changing baseline glazing types based on WWR and orientation' if standard == '90.1-2004'
    us << 'No fan power allowances for MERV filters or ducted supply/return present in proposed model HVAC'
    us << 'Laboratory-specific ventilation is not handled'
    us << 'Kitchen ventilation is not handled; exhaust fans left as found in proposed'
    us << 'Commercial refrigeration equipment is left as found in proposed'
    us << 'Transformers are not added to the baseline model'
    us << 'System types 11 (for data centers) and 12/13 (for public assembly buildings)' if standard == '90.1-2013'
    us << 'Zone humidity control present in the proposed model HVAC systems is not added to baseline HVAC'

    # Report out to users
    OpenStudio.logFree(OpenStudio::Info, 'openstudio.standards.Model', '*** Currently unsupported ***')
    us.each do |msg|
      OpenStudio.logFree(OpenStudio::Info, 'openstudio.standards.Model', msg)
    end

    # List of known issues or limitations
    issues = []
    issues << 'Some control and efficiency determinations do not scale capacities/flow rates down to reflect zone multipliers'
    issues << 'Daylighting control illuminance setpoint does not vary based on space type'
    issues << 'Daylighting area calcs do not include windows in non-vertical walls'
    issues << 'Daylighting area calcs do not include skylights in non-horizontal roofs'

    # Report out to users
    OpenStudio.logFree(OpenStudio::Info, 'openstudio.standards.Model', '*** Known issues ***')
    issues.each do |msg|
      OpenStudio.logFree(OpenStudio::Info, 'openstudio.standards.Model', msg)
    end

    # Make a directory to save the resulting models for debugging
    build_dir = "#{Dir.pwd}/output"
    if !Dir.exist?(build_dir)
      Dir.mkdir(build_dir)
    end

    # Versions of OpenStudio greater than 2.4.0 use a modified version of
    # openstudio-standards with different method calls.
    if OpenStudio::VersionString.new(OpenStudio.openStudioVersion) < OpenStudio::VersionString.new('2.4.3')
      success = model.create_prm_baseline_building(building_type, standard, climate_zone, custom, build_dir, debug)
    else
      std = Standard.build(standard)
      std.model_create_prm_baseline_building(model, building_type, climate_zone, custom, build_dir, debug)
    end

    log_msgs(debug)
    return success
  end # end the run method

  # Get all the log messages and put into output
  # for users to see.
  def log_msgs(debug)
    # Log the messages to file for easier review
    log_name = 'create_baseline.log'
    log_file_path = "#{Dir.pwd}/#{log_name}"
    messages = log_messages_to_file(log_file_path, debug)
    @runner.registerFinalCondition("Messages below saved to <a href='file:///#{log_file_path}'>#{log_name}</a>.")
    @msg_log.logMessages.each do |msg|
      # DLM: you can filter on log channel here for now
      if /openstudio.*/.match?(msg.logChannel) # /openstudio\.model\..*/
        # Skip certain messages that are irrelevant/misleading
        next if msg.logMessage.include?('Skipping layer') || # Annoying/bogus "Skipping layer" warnings
                msg.logChannel.include?('runmanager') || # RunManager messages
                msg.logChannel.include?('setFileExtension') || # .ddy extension unexpected
                msg.logChannel.include?('Translator') || # Forward translator and geometry translator
                msg.logMessage.include?('UseWeatherFile') || # 'UseWeatherFile' is not yet a supported option for YearDescription
                msg.logMessage.include?('has multiple parents') # Object of type 'OS:Curve:Cubic' and named 'VSD-TWR-FAN-FPLR' has multiple parents. Returning the first.
        # Report the message in the correct way
        if msg.logLevel == OpenStudio::Info
          @runner.registerInfo(msg.logMessage)
        elsif msg.logLevel == OpenStudio::Warn
          @runner.registerWarning(msg.logMessage.to_s)
        elsif msg.logLevel == OpenStudio::Error
          @runner.registerError(msg.logMessage.to_s)
        elsif msg.logLevel == OpenStudio::Debug && debug
          @runner.registerInfo("DEBUG - #{msg.logMessage}")
        end
      end
    end
    @runner.registerInfo("Total Time = #{(Time.new - @start_time).round}sec.")
  end
end # end the measure

# this allows the measure to be use by the application
CreateBaselineBuilding.new.registerWithApplication
