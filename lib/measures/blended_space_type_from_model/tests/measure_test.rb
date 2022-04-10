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
require_relative '../measure.rb'
require 'fileutils'

class BlendedSpaceTypeFromModelTest < MiniTest::Test
  # method to apply arguments, run measure, and assert results (only populate args hash with non-default argument values)
  def apply_measure_to_model(test_name, args, model_name = nil, result_value = 'Success', warnings_count = 0, info_count = nil)
    # create an instance of the measure
    measure = BlendedSpaceTypeFromModel.new

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
    argument_map = OpenStudio::Measure.convertOSArgumentVectorToMap(arguments)

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
    unless warnings_count.nil? then assert(result.warnings.size == warnings_count) end

    # if 'Fail' passed in make sure at least one error message (while not typical there may be more than one message)
    if result_value == 'Fail' then assert(result.errors.size >= 1) end

    # save the model to test output directory
    output_file_path = OpenStudio::Path.new(File.dirname(__FILE__) + "/output/#{test_name}_test_output.osm")
    model.save(output_file_path, true)

    return model
  end

  def test_example_model
    args = {}
    apply_measure_to_model(__method__.to_s.gsub('test_', ''), args, 'example_model.osm')
  end

  def test_large_hotel
    args = {}
    apply_measure_to_model(__method__.to_s.gsub('test_', ''), args, '0916_lrg_htl_1_12_0.osm')
  end

  def test_medium_office_2010
    args = {}
    apply_measure_to_model(__method__.to_s.gsub('test_', ''), args, '0922_md_off_1_12_0.osm', 'Success', 12)
  end

  def test_medium_office_2004
    args = {}
    apply_measure_to_model(__method__.to_s.gsub('test_', ''), args, '0923_med_off_2004_1_13_0.osm')
  end

  def test_full_service_rest_2004
    args = {}
    apply_measure_to_model(__method__.to_s.gsub('test_', ''), args, '0926_full_rest_1_12_0.osm', 'Success', 1)
  end

  def test_mixed_hotel_rest_by_whole_buiding
    args = {}
    apply_measure_to_model(__method__.to_s.gsub('test_', ''), args, 'large_hotel_restaurant_from_create_typical.osm')
  end

  def test_mixed_hotel_rest_by_building_type
    args = {}
    args['blend_method'] = 'Building Type'
    apply_measure_to_model(__method__.to_s.gsub('test_', ''), args, 'large_hotel_restaurant_from_create_typical.osm')
  end

  def test_mixed_hotel_rest_by_story
    args = {}
    args['blend_method'] = 'Building Story'
    apply_measure_to_model(__method__.to_s.gsub('test_', ''), args, 'large_hotel_restaurant_from_create_typical.osm')
  end

  def test_basement_infil_test
    args = {}
    args['blend_method'] = 'Building Story'
    model = apply_measure_to_model(__method__.to_s.gsub('test_', ''), args, 'basement_infil_test.osm')

    # check for nan in space infiltration
    model.getSpaceInfiltrationDesignFlowRates.each do |infil|
      if infil.flowperExteriorSurfaceArea.is_initialized
        assert(!infil.flowperExteriorSurfaceArea.get.nan?)
      end
    end
  end
end
