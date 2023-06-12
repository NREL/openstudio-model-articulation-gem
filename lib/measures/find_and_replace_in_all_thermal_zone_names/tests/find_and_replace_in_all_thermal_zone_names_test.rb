# *******************************************************************************
# OpenStudio(R), Copyright (c) Alliance for Sustainable Energy, LLC.
# See also https://openstudio.net/license
# *******************************************************************************

require 'openstudio'
require 'openstudio/measure/ShowRunnerOutput'
require 'fileutils'

require_relative '../measure'
require 'minitest/autorun'

class FindAndReplaceInAllThermalZoneNamesTest < Minitest::Test
  def test_number_of_arguments_and_argument_names
    # create an instance of the measure
    measure = FindAndReplaceInAllThermalZoneNames.new

    # create an instance of a runner
    runner = OpenStudio::Measure::OSRunner.new(OpenStudio::WorkflowJSON.new)

    # make an empty model
    model = OpenStudio::Model::Model.new

    # get arguments and test that they are what we are expecting
    arguments = measure.arguments(model)
    assert_equal(2, arguments.size)
    assert_equal('orig_string', arguments[0].name)
    assert_equal('new_string', arguments[1].name)
  end

  def test_bad_argument_values
    # create an instance of the measure
    measure = FindAndReplaceInAllThermalZoneNames.new

    # create an instance of a runner
    runner = OpenStudio::Measure::OSRunner.new(OpenStudio::WorkflowJSON.new)

    # make an empty model
    model = OpenStudio::Model::Model.new

    # get arguments
    arguments = measure.arguments(model)
    argument_map = OpenStudio::Measure.convertOSArgumentVectorToMap(arguments)

    # set argument values to bad values and run the measure
    orig_string = arguments[0].clone
    assert(orig_string.setValue(''))
    argument_map['orig_string'] = orig_string
    measure.run(model, runner, argument_map)
    result = runner.result
    assert(result.value.valueName == 'Fail')
  end

  def test_imported_idf_model
    # create an instance of the measure
    measure = FindAndReplaceInAllThermalZoneNames.new

    # create an instance of a runner
    runner = OpenStudio::Measure::OSRunner.new(OpenStudio::WorkflowJSON.new)

    # load the test model
    translator = OpenStudio::OSVersion::VersionTranslator.new
    path = OpenStudio::Path.new("#{File.dirname(__FILE__)}/ImportedIdf_RefFsr.osm")
    model = translator.loadModel(path)
    assert(!model.empty?)
    model = model.get

    # get arguments
    arguments = measure.arguments(model)
    argument_map = OpenStudio::Measure.convertOSArgumentVectorToMap(arguments)

    # run the measure
    measure.run(model, runner, argument_map)
    result = runner.result
    show_output(result)
    assert(result.value.valueName == 'Success')

    # save the model
    output_dir = File.expand_path('output', File.dirname(__FILE__))
    FileUtils.mkdir output_dir unless Dir.exist? output_dir
    output_file_path = OpenStudio::Path.new("#{output_dir}/test_imported_idf_model_results.osm")
    model.save(output_file_path, true)
  end
end
