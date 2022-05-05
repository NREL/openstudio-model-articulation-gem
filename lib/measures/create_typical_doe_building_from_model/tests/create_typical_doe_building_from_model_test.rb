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

require 'openstudio'
require 'openstudio/measure/ShowRunnerOutput'
require 'minitest/autorun'
require_relative '../measure'
require 'fileutils'

class CreateTypicalDOEBuildingFromModel_Test < Minitest::Test
  def run_dir(test_name)
    # will make directory if it doesn't exist
    output_dir = File.expand_path('output', File.dirname(__FILE__))
    FileUtils.mkdir output_dir unless Dir.exist? output_dir

    # always generate test output in specially named 'output' directory so result files are not made part of the measure
    "#{File.dirname(__FILE__)}/output/#{test_name}"
  end

  # TODO: - remove excess test files
  # todo - consider minimal testing if combined measuers has full test set

  # method to apply arguments, run measure, and assert results (only populate args hash with non-default argument values)
  def apply_measure_to_model(test_name, args, model_name = nil, result_value = 'Success', warnings_count = 0, info_count = nil)
    # create an instance of the measure
    measure = CreateTypicalDOEBuildingFromModel.new

    # create an instance of a runner with OSW
    osw_path = OpenStudio::Path.new("#{File.dirname(__FILE__)}/measure_test.osw")
    osw = OpenStudio::WorkflowJSON.load(osw_path).get
    runner = OpenStudio::Measure::OSRunner.new(osw)

    if model_name.nil?
      # make an empty model
      model = OpenStudio::Model::Model.new
    else
      # load the test model
      translator = OpenStudio::OSVersion::VersionTranslator.new
      path = OpenStudio::Path.new("#{File.dirname(__FILE__)}/#{model_name}")
      model = translator.loadModel(path)
      assert(!model.empty?)
      model = model.get
    end

    # set the weather file for the test model
    epw_file = OpenStudio::EpwFile.new("#{__dir__}/USA_TX_Houston-Bush.Intercontinental.AP.722430_TMY3.epw")
    OpenStudio::Model::WeatherFile.setWeatherFile(model, epw_file).get

    # Set the day of week for start day
    model.getYearDescription.setDayofWeekforStartDay('Thursday')

    # get arguments
    arguments = measure.arguments(model)
    argument_map = OpenStudio::Measure.convertOSArgumentVectorToMap(arguments)

    # populate argument with specified hash value if specified
    arguments.each do |arg|
      temp_arg_var = arg.clone
      if args.key?(arg.name)
        assert(temp_arg_var.setValue(args[arg.name]))
      end
      argument_map[arg.name] = temp_arg_var
    end

    # temporarily change directory to the run directory and run the measure (because of sizing run)
    start_dir = Dir.pwd
    begin
      unless Dir.exist?(run_dir(test_name))
        Dir.mkdir(run_dir(test_name))
      end
      Dir.chdir(run_dir(test_name))

      # run the measure
      reset_log
      measure.run(model, runner, argument_map)
      result = runner.result
      log_file_path = "#{Dir.pwd}/openstudio-standards.log"
      log_messages_to_file(log_file_path, false)
    ensure
      Dir.chdir(start_dir)

      # delete sizing run dir
      # FileUtils.rm_rf(run_dir(test_name))
    end

    # show the output
    puts "measure results for #{test_name}"
    show_output(result)

    # assert that it ran correctly
    if result_value.nil? then result_value = 'Success' end
    assert_equal(result_value, result.value.valueName)

    # check count of warning and info messages
    unless info_count.nil? then assert(result.info.size == info_count) end
    unless warnings_count.nil? then assert(result.warnings.size == warnings_count) end

    # if 'Fail' passed in make sure at least one error message (while not typical there may be more than one message)
    if result_value == 'Fail' then assert(result.errors.size >= 1) end

    # save the model to test output directory
    output_file_path = OpenStudio::Path.new(File.dirname(__FILE__) + "/output/#{test_name}_test_output.osm")
    model.save(output_file_path, true)

    # standard = Standard.build('90.1-2004')
    # success = standard.model_run_simulation_and_log_errors(model, File.dirname(__FILE__) + "/output/#{test_name}")
    # assert(success, "")
  end

  def test_midrise_apartment
    apply_measure_to_model(__method__.to_s.gsub('test_', ''), {}, 'MidriseApartment.osm', nil, nil)
  end

  def test_small_office
    apply_measure_to_model(__method__.to_s.gsub('test_', ''), {}, 'SmallOffice.osm', nil, nil)
  end

  # might be cleaner to update standards to not make ext light object with multipler of 0, but for now it does seem to run through E+ fine.
  def test_no_onsite_parking
    args = {}
    args['onsite_parking_fraction'] = 0.0
    apply_measure_to_model(__method__.to_s.gsub('test_', ''), args, 'SmallOffice.osm', nil, nil)
  end

  def test_large_office
    args = {}
    args['add_elevators'] = false
    args['add_internal_mass'] = false
    apply_measure_to_model(__method__.to_s.gsub('test_', ''), args, 'LargeOffice04.osm', nil, nil)
  end

  def test_small_office_no_extra_loads_with_pvav
    args = {}
    args['add_elevators'] = false
    args['add_internal_mass'] = false
    args['add_exhaust'] = false
    args['add_exterior_lights'] = false
    args['add_swh'] = false
    # args['system_type'] = "Packaged VAV Air Loop with Boiler"

    apply_measure_to_model(__method__.to_s.gsub('test_', ''), args, 'SmallOffice.osm', nil, nil)
  end

  # made this test for temp work around for night cycle mode
  def test_pfp_boxes
    args = {}
    args['system_type'] = 'VAV chiller with PFP boxes'
    apply_measure_to_model(__method__.to_s.gsub('test_', ''), args, 'SmallOffice.osm', nil, nil)
  end

  def test_generic_gbxml
    args = {}
    apply_measure_to_model(__method__.to_s.gsub('test_', ''), args, 'GenericGbxml.osm', nil, nil)
  end
end
