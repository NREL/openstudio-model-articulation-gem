# *******************************************************************************
# OpenStudio(R), Copyright (c) Alliance for Sustainable Energy, LLC.
# See also https://openstudio.net/license
# *******************************************************************************

require 'openstudio'
require 'openstudio/measure/ShowRunnerOutput'
require 'minitest/autorun'
require_relative '../measure'
require 'fileutils'

class CloneBuildingFromExternalModelTest < MiniTest::Test
  # def setup
  # end

  # def teardown
  # end

  def test_good_argument_values
    # create an instance of the measure
    measure = CloneBuildingFromExternalModel.new

    # create an instance of a runner
    runner = OpenStudio::Measure::OSRunner.new(OpenStudio::WorkflowJSON.new)

    # load the test model
    translator = OpenStudio::OSVersion::VersionTranslator.new
    path = OpenStudio::Path.new("#{File.dirname(__FILE__)}/example_model.osm")
    model = translator.loadModel(path)
    assert(!model.empty?)
    model = model.get

    # get arguments
    arguments = measure.arguments(model)
    argument_map = OpenStudio::Measure.convertOSArgumentVectorToMap(arguments)

    # create hash of argument values.
    # If the argument has a default that you want to use, you don't need it in the hash
    args_hash = {}
    args_hash['external_model_name'] = "#{File.dirname(__FILE__)}/AedgK12HvacDualDuctDoas_ASHRAE 169-2006-5B.osm"

    # populate argument with specified hash value if specified
    arguments.each do |arg|
      temp_arg_var = arg.clone
      if args_hash[arg.name]
        assert(temp_arg_var.setValue(args_hash[arg.name]))
      end
      argument_map[arg.name] = temp_arg_var
    end

    # run the measure
    measure.run(model, runner, argument_map)
    result = runner.result

    # show the output
    show_output(result)

    # assert that it ran correctly
    assert_equal('Success', result.value.valueName)
    # assert(result.info.size == 1)
    # assert(result.warnings.size == 0)

    # save the model to test output directory
    output_file_path = OpenStudio::Path.new("#{File.dirname(__FILE__)}/output/test_output.osm")
    model.save(output_file_path, true)
  end

  def test_file_name_only
    # create an instance of the measure
    measure = CloneBuildingFromExternalModel.new

    # create an instance of a runner with OSW
    osw_path = OpenStudio::Path.new("#{File.dirname(__FILE__)}/measure_test.osw")
    osw = OpenStudio::WorkflowJSON.load(osw_path).get
    runner = OpenStudio::Measure::OSRunner.new(osw)

    # load the test model
    translator = OpenStudio::OSVersion::VersionTranslator.new
    path = OpenStudio::Path.new("#{File.dirname(__FILE__)}/example_model.osm")
    model = translator.loadModel(path)
    assert(!model.empty?)
    model = model.get

    # get arguments
    arguments = measure.arguments(model)
    argument_map = OpenStudio::Measure.convertOSArgumentVectorToMap(arguments)

    # create hash of argument values.
    # If the argument has a default that you want to use, you don't need it in the hash
    args_hash = {}
    args_hash['external_model_name'] = 'AedgK12HvacDualDuctDoas_ASHRAE 169-2006-5B.osm'

    # populate argument with specified hash value if specified
    arguments.each do |arg|
      temp_arg_var = arg.clone
      if args_hash[arg.name]
        assert(temp_arg_var.setValue(args_hash[arg.name]))
      end
      argument_map[arg.name] = temp_arg_var
    end

    # run the measure
    measure.run(model, runner, argument_map)
    result = runner.result

    # show the output
    show_output(result)

    # assert that it ran correctly
    assert_equal('Success', result.value.valueName)
    # assert(result.info.size == 1)
    # assert(result.warnings.size == 0)

    # save the model to test output directory
    output_file_path = OpenStudio::Path.new("#{File.dirname(__FILE__)}/output/test_output.osm")
    model.save(output_file_path, true)
  end
end
