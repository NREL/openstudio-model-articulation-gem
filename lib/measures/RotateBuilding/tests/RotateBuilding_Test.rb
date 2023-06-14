# *******************************************************************************
# OpenStudio(R), Copyright (c) Alliance for Sustainable Energy, LLC.
# See also https://openstudio.net/license
# *******************************************************************************

require 'openstudio'
require 'openstudio/measure/ShowRunnerOutput'
require 'fileutils'

require_relative '../measure'
require 'minitest/autorun'

class RotateBuilding_Test < Minitest::Test
  # def setup
  # end

  # def teardown
  # end

  def test_RotateBuilding
    # create an instance of the measure
    measure = RotateBuilding.new

    # create an instance of a runner
    runner = OpenStudio::Measure::OSRunner.new(OpenStudio::WorkflowJSON.new)

    # make an empty model
    model = OpenStudio::Model::Model.new

    # get arguments and test that they are what we are expecting
    arguments = measure.arguments(model)
    assert_equal(1, arguments.size)
    assert_equal('relative_building_rotation', arguments[0].name)

    # load the test model
    translator = OpenStudio::OSVersion::VersionTranslator.new
    path = OpenStudio::Path.new("#{File.dirname(__FILE__)}/RotateBuilding_TestModel_01.osm")
    model = translator.loadModel(path)
    assert(!model.empty?)
    model = model.get

    # set argument values to good values and run the measure on model with spaces
    arguments = measure.arguments(model)
    argument_map = OpenStudio::Measure.convertOSArgumentVectorToMap(arguments)

    relative_building_rotation = arguments[0].clone
    assert(relative_building_rotation.setValue('500.2'))
    argument_map['relative_building_rotation'] = relative_building_rotation

    measure.run(model, runner, argument_map)
    result = runner.result
    # show_output(result)
    assert(result.value.valueName == 'Success')
    assert(result.warnings.size == 2)
    assert(result.info.size == 1)
  end

  # this was just made to test if building object was made on new model. It it was not then rotate building woudl not have worked.
  def test_RotateBuilding_EmptySpaceNoLoadsOrSurfaces
    # create an instance of the measure
    measure = RotateBuilding.new

    # create an instance of a runner
    runner = OpenStudio::Measure::OSRunner.new(OpenStudio::WorkflowJSON.new)

    # make an empty model
    model = OpenStudio::Model::Model.new

    # get arguments and test that they are what we are expecting
    arguments = measure.arguments(model)
    assert_equal(1, arguments.size)
    assert_equal('relative_building_rotation', arguments[0].name)

    # make an empty model
    model = OpenStudio::Model::Model.new

    # set argument values to good values and run the measure on model with spaces
    arguments = measure.arguments(model)
    argument_map = OpenStudio::Measure.convertOSArgumentVectorToMap(arguments)

    relative_building_rotation = arguments[0].clone
    assert(relative_building_rotation.setValue('500.2'))
    argument_map['relative_building_rotation'] = relative_building_rotation

    measure.run(model, runner, argument_map)
    result = runner.result
    show_output(result)
    # assert(result.value.valueName == "Success")
    # assert(result.warnings.size == 2)
    # assert(result.info.size == 1)
  end
end
