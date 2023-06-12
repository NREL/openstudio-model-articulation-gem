# *******************************************************************************
# OpenStudio(R), Copyright (c) Alliance for Sustainable Energy, LLC.
# See also https://openstudio.net/license
# *******************************************************************************

require 'openstudio'
require 'openstudio/measure/ShowRunnerOutput'
require 'minitest/autorun'
require_relative '../measure'
require 'fileutils'

class MergeSpacesFromExternalFile_Test < MiniTest::Test
  def test_geo_loads_attributes
    test_name = 'geo_loads_attributes'

    # create an instance of the measure
    measure = MergeSpacesFromExternalFile.new

    # create an instance of a runner with OSW
    osw_path = OpenStudio::Path.new("#{File.dirname(__FILE__)}/measure_test.osw")
    osw = OpenStudio::WorkflowJSON.load(osw_path).get
    runner = OpenStudio::Measure::OSRunner.new(osw)

    # load the test model
    translator = OpenStudio::OSVersion::VersionTranslator.new
    path = OpenStudio::Path.new("#{File.dirname(__FILE__)}/current_model_test.osm")
    model = translator.loadModel(path)
    assert(!model.empty?)
    model = model.get

    # get arguments
    arguments = measure.arguments(model)
    argument_map = OpenStudio::Measure.convertOSArgumentVectorToMap(arguments)

    # create hash of argument values.
    # If the argument has a default that you want to use, you don't need it in the hash
    args_hash = {}
    args_hash['external_model_name'] = 'external_model_test.osm'
    args_hash['merge_geometry'] = true
    args_hash['merge_loads'] = true
    args_hash['merge_attribute_names'] = true
    # using defaults values from measure.rb for other arguments

    # populate argument with specified hash value if specified
    arguments.each do |arg|
      temp_arg_var = arg.clone
      if args_hash.key?(arg.name)
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
    output_file_path = OpenStudio::Path.new(File.dirname(__FILE__) + "/output/#{test_name}.osm")
    model.save(output_file_path, true)
  end

  def test_geo
    test_name = 'geo'

    # create an instance of the measure
    measure = MergeSpacesFromExternalFile.new

    # create an instance of a runner with OSW
    osw_path = OpenStudio::Path.new("#{File.dirname(__FILE__)}/measure_test.osw")
    osw = OpenStudio::WorkflowJSON.load(osw_path).get
    runner = OpenStudio::Measure::OSRunner.new(osw)

    # load the test model
    translator = OpenStudio::OSVersion::VersionTranslator.new
    path = OpenStudio::Path.new("#{File.dirname(__FILE__)}/current_model_test.osm")
    model = translator.loadModel(path)
    assert(!model.empty?)
    model = model.get

    # get arguments
    arguments = measure.arguments(model)
    argument_map = OpenStudio::Measure.convertOSArgumentVectorToMap(arguments)

    # create hash of argument values.
    # If the argument has a default that you want to use, you don't need it in the hash
    args_hash = {}
    args_hash['external_model_name'] = 'external_model_test.osm'
    args_hash['merge_geometry'] = true
    args_hash['merge_loads'] = false
    args_hash['merge_attribute_names'] = false
    # using defaults values from measure.rb for other arguments

    # populate argument with specified hash value if specified
    arguments.each do |arg|
      temp_arg_var = arg.clone
      if args_hash.key?(arg.name)
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

    # save the model to test output directory
    output_file_path = OpenStudio::Path.new(File.dirname(__FILE__) + "/output/#{test_name}.osm")
    model.save(output_file_path, true)
  end

  def test_loads_attributes
    test_name = 'loads_attributes'

    # create an instance of the measure
    measure = MergeSpacesFromExternalFile.new

    # create an instance of a runner with OSW
    osw_path = OpenStudio::Path.new("#{File.dirname(__FILE__)}/measure_test.osw")
    osw = OpenStudio::WorkflowJSON.load(osw_path).get
    runner = OpenStudio::Measure::OSRunner.new(osw)

    # load the test model
    translator = OpenStudio::OSVersion::VersionTranslator.new
    path = OpenStudio::Path.new("#{File.dirname(__FILE__)}/current_model_test.osm")
    model = translator.loadModel(path)
    assert(!model.empty?)
    model = model.get

    # get arguments
    arguments = measure.arguments(model)
    argument_map = OpenStudio::Measure.convertOSArgumentVectorToMap(arguments)

    # create hash of argument values.
    # If the argument has a default that you want to use, you don't need it in the hash
    args_hash = {}
    args_hash['external_model_name'] = 'external_model_test.osm'
    args_hash['merge_geometry'] = false
    args_hash['merge_loads'] = true
    args_hash['merge_attribute_names'] = true
    # using defaults values from measure.rb for other arguments

    # populate argument with specified hash value if specified
    arguments.each do |arg|
      temp_arg_var = arg.clone
      if args_hash.key?(arg.name)
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

    # save the model to test output directory
    output_file_path = OpenStudio::Path.new(File.dirname(__FILE__) + "/output/#{test_name}.osm")
    model.save(output_file_path, true)
  end

  def test_none
    test_name = 'none'

    # create an instance of the measure
    measure = MergeSpacesFromExternalFile.new

    # create an instance of a runner with OSW
    osw_path = OpenStudio::Path.new("#{File.dirname(__FILE__)}/measure_test.osw")
    osw = OpenStudio::WorkflowJSON.load(osw_path).get
    runner = OpenStudio::Measure::OSRunner.new(osw)

    # load the test model
    translator = OpenStudio::OSVersion::VersionTranslator.new
    path = OpenStudio::Path.new("#{File.dirname(__FILE__)}/current_model_test.osm")
    model = translator.loadModel(path)
    assert(!model.empty?)
    model = model.get

    # get arguments
    arguments = measure.arguments(model)
    argument_map = OpenStudio::Measure.convertOSArgumentVectorToMap(arguments)

    # create hash of argument values.
    # If the argument has a default that you want to use, you don't need it in the hash
    args_hash = {}
    args_hash['external_model_name'] = 'external_model_test.osm'
    args_hash['merge_geometry'] = false
    args_hash['merge_loads'] = false
    args_hash['merge_attribute_names'] = false
    args_hash['merge_schedules'] = false
    # using defaults values from measure.rb for other arguments

    # populate argument with specified hash value if specified
    arguments.each do |arg|
      temp_arg_var = arg.clone
      if args_hash.key?(arg.name)
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
    assert_equal('NA', result.value.valueName)

    # save the model to test output directory
    output_file_path = OpenStudio::Path.new(File.dirname(__FILE__) + "/output/#{test_name}.osm")
    model.save(output_file_path, true)
  end
end
