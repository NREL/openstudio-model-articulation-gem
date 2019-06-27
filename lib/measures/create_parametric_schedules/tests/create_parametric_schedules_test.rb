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

require 'openstudio'
require 'openstudio/ruleset/ShowRunnerOutput'
require 'minitest/autorun'
require_relative '../measure.rb'
require 'fileutils'

class CreateParametricSchedules_Test < MiniTest::Test
  # method to apply arguments, run measure, and assert results (only populate args hash with non-default argument values)
  def apply_measure_to_model(test_name, args, model_name = nil, result_value = 'Success', warnings_count = 0, info_count = nil)
    # create an instance of the measure
    measure = CreateParametricSchedules.new

    # create an instance of a runner
    runner = OpenStudio::Measure::OSRunner.new(OpenStudio::WorkflowJSON.new)

    if model_name.nil?
      # make an empty model
      model = OpenStudio::Model::Model.new
    else
      # load the test model
      translator = OpenStudio::OSVersion::VersionTranslator.new
      path = OpenStudio::Path.new(File.dirname(__FILE__) + '/' + model_name)
      model = translator.loadModel(path)
      assert(!model.empty?)
      model = model.get
    end

    # get arguments
    arguments = measure.arguments(model)
    argument_map = OpenStudio::Ruleset.convertOSArgumentVectorToMap(arguments)

    # populate argument with specified hash value if specified
    arguments.each do |arg|
      temp_arg_var = arg.clone
      if args.key?(arg.name)
        assert(temp_arg_var.setValue(args[arg.name]))
      end
      argument_map[arg.name] = temp_arg_var
    end

    # run the measure
    measure.run(model, runner, argument_map)
    result = runner.result

    # show the output
    puts "measure results for #{test_name}"
    show_output(result)

    # assert that it ran correctly
    if result_value.nil? then result_value = 'Success' end
    assert_equal(result_value, result.value.valueName)

    # check count of warning and info messages
    unless info_count.nil? then assert(result.info.size == info_count) end
    # TODO: - update tests and un-comment this
    # unless warnings_count.nil? then assert(result.warnings.size == warnings_count) end

    # if 'Fail' passed in make sure at least one error message (while not typical there may be more than one message)
    if result_value == 'Fail' then assert(result.errors.size >= 1) end

    # save the model to test output directory
    output_file_path = OpenStudio::Path.new(File.dirname(__FILE__) + "/output/#{test_name}_test_output.osm")
    model.save(output_file_path, true)
  end

  def test_good_argument_values
    args = {}

    apply_measure_to_model(__method__.to_s.gsub('test_', ''), args, 'example_model.osm')
  end

  def test_no_sat_sun_lighting_profiles
    args = {}
    args['lighting_profiles'] = ':default => [[start-2,0.1],[start-1,0.3],[start,0.75],[end,0.75],[end+2,0.3],[end+vac*0.4,0.1]]'

    apply_measure_to_model(__method__.to_s.gsub('test_', ''), args, 'example_model.osm')
  end

  def test_custom_profile_overlaping_start_end
    args = {}
    args['lighting_profiles'] = ':default => [[start-6,0],[start,1],[end,1],[end+6,0]]'
    args['hoo_start_wkdy'] = 4.0
    args['hoo_end_wkdy'] = 20.0
    apply_measure_to_model(__method__.to_s.gsub('test_', ''), args, 'example_model.osm', 'Success', 1)
  end

  # there is code in process_hash method to support string arguments of older format. May eventually remove it, but for now this tests that code
  def test_legacy_profile_hash_string
    args = {}
    profile_hash = {}
    profile_hash[:weekday] = '[["start-2",0.1],["start-1",0.3],["start",0.75],["end",0.75],["end+2",0.3],["end+vac*0.4",0.1]]'
    profile_hash[:saturday] = '[["start-1",0.1],["start",0.3],["end",0.3],["end+1",0.1]]'
    profile_hash[:sunday] = '[["start",0.1],["end",0.1]]'
    args['lighting_profiles'] = profile_hash.to_json

    apply_measure_to_model(__method__.to_s.gsub('test_', ''), args, 'example_model.osm')
  end

  def test_hours_per_week_60
    args = {}
    args['hoo_per_week'] = 60.0

    apply_measure_to_model(__method__.to_s.gsub('test_', ''), args, 'example_model.osm')
  end

  def test_hours_per_week_70
    args = {}
    args['hoo_per_week'] = 60.0

    apply_measure_to_model(__method__.to_s.gsub('test_', ''), args, 'example_model.osm')
  end

  def test_hours_per_week_80
    args = {}
    args['hoo_per_week'] = 80.0

    apply_measure_to_model(__method__.to_s.gsub('test_', ''), args, 'example_model.osm')
  end

  def test_hours_per_week_120
    args = {}
    args['hoo_per_week'] = 120.0
    args['hoo_start_sun'] = 12.0
    args['hoo_end_sun'] = 22.0

    apply_measure_to_model(__method__.to_s.gsub('test_', ''), args, 'example_model.osm')
  end

  # TODO: - still soe odd behavior in reporting of hours of operation
  def test_hours_per_week_168
    args = {}
    args['hoo_per_week'] = 168.0

    apply_measure_to_model(__method__.to_s.gsub('test_', ''), args, 'example_model.osm', 'Success', 14)
  end

  def test_hours_per_week_05
    args = {}
    args['hoo_per_week'] = 5.0
    args['ramp_frequency'] = 0.1 # every 6 minutes vs. default of 30

    apply_measure_to_model(__method__.to_s.gsub('test_', ''), args, 'example_model.osm')
  end

  def test_hours_per_week_20
    args = {}
    args['hoo_per_week'] = 20.0

    apply_measure_to_model(__method__.to_s.gsub('test_', ''), args, 'example_model.osm')
  end

  def test_no_hoo_weekday
    args = {}
    args['hoo_start_wkdy'] = 0.0
    args['hoo_end_wkdy'] = 0.0

    # three warnings for out of order schedule profiles after formula applied
    apply_measure_to_model(__method__.to_s.gsub('test_', ''), args, 'example_model.osm', 'Success', 4)
  end

  def test_no_hoo_weekday_b
    args = {}
    args['hoo_start_wkdy'] = 9.0
    args['hoo_end_wkdy'] = 9.0

    # three warnings for out of order schedule profiles after formula applied
    apply_measure_to_model(__method__.to_s.gsub('test_', ''), args, 'example_model.osm', 'Success', 3)
  end

  def test_custom_hoo_fail_on_out_of_order
    args = {}
    args['hoo_start_wkdy'] = 9.0
    args['hoo_end_wkdy'] = 9.25
    args['error_on_out_of_order'] = true

    # will not attemp to reconsile out of order profile
    apply_measure_to_model(__method__.to_s.gsub('test_', ''), args, 'example_model.osm', 'Fail')
  end

  def test_long_day
    args = {}
    args['hoo_start_wkdy'] = 2.0
    args['hoo_end_wkdy'] = 20.0

    apply_measure_to_model(__method__.to_s.gsub('test_', ''), args, 'example_model.osm')
  end

  def test_wrap_around
    args = {}
    args['hoo_start_wkdy'] = 20.0
    args['hoo_end_wkdy'] = 10.0

    apply_measure_to_model(__method__.to_s.gsub('test_', ''), args, 'example_model.osm')
  end

  def test_building_found
    args = {}
    args['valid_building_names'] = 'some building name, BUILDING 1'

    apply_measure_to_model(__method__.to_s.gsub('test_', ''), args, 'example_model.osm')
  end

  def test_building_not_found
    args = {}
    args['valid_building_names'] = 'Not my building, still not my building'

    apply_measure_to_model(__method__.to_s.gsub('test_', ''), args, 'example_model.osm', 'NA')
  end

  def test_single_space_type
    args = {}
    args['standards_building_type'] = 'Office'
    args['standards_space_type'] = 'Conference'
    args['alter_swh_wo_space'] = false

    apply_measure_to_model(__method__.to_s.gsub('test_', ''), args, 'example_model.osm')
  end
end
