# *******************************************************************************
# OpenStudio(R), Copyright (c) Alliance for Sustainable Energy, LLC.
# See also https://openstudio.net/license
# *******************************************************************************

require 'openstudio'
require 'openstudio/measure/ShowRunnerOutput'
require 'fileutils'

require_relative '../measure'
require 'minitest/autorun'

class FindAndReplaceObjectNames_Test < Minitest::Test
  # def setup
  # end

  # def teardown
  # end

  def test_FindAndReplaceObjectNames
    # create an instance of the measure
    measure = FindAndReplaceObjectNames.new

    # create an instance of a runner
    runner = OpenStudio::Measure::OSRunner.new(OpenStudio::WorkflowJSON.new)

    # make an empty model
    model = OpenStudio::Model::Model.new

    # get arguments and test that they are what we are expecting
    arguments = measure.arguments(model)
    assert_equal(2, arguments.size)
    assert_equal('orig_string', arguments[0].name)
    assert_equal('new_string', arguments[1].name)

    # set argument values to bad values and run the measure
    argument_map = OpenStudio::Measure.convertOSArgumentVectorToMap(arguments)
    orig_string = arguments[0].clone
    assert(orig_string.setValue(''))
    argument_map['orig_string'] = orig_string
    measure.run(model, runner, argument_map)
    result = runner.result
    assert(result.value.valueName == 'Fail')

    # create an instance of a runner
    runner = OpenStudio::Measure::OSRunner.new(OpenStudio::WorkflowJSON.new)

    # load the test model
    translator = OpenStudio::OSVersion::VersionTranslator.new
    path = OpenStudio::Path.new("#{File.dirname(__FILE__)}/EnvelopeAndLoadTestModel_01.osm")
    model = translator.loadModel(path)
    assert(!model.empty?)
    model = model.get

    # refresh arguments
    arguments = measure.arguments(model)

    # set argument values to good values and run the measure on model with spaces
    argument_map = OpenStudio::Measure.convertOSArgumentVectorToMap(arguments)
    orig_string = arguments[0].clone
    assert(orig_string.setValue('_'))
    argument_map['orig_string'] = orig_string
    new_string = arguments[1].clone
    assert(new_string.setValue(' '))
    argument_map['new_string'] = new_string
    measure.run(model, runner, argument_map)
    result = runner.result
    show_output(result)
    assert(result.value.valueName == 'Success')
  end
end
