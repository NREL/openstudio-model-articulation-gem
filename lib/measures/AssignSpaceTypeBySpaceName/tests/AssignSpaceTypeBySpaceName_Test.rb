# *******************************************************************************
# OpenStudio(R), Copyright (c) Alliance for Sustainable Energy, LLC.
# See also https://openstudio.net/license
# *******************************************************************************

require 'openstudio'
require 'openstudio/measure/ShowRunnerOutput'
require 'fileutils'

require_relative '../measure'
require 'minitest/autorun'

class AssignSpaceTypeBySpaceName_Test < Minitest::Test
  def test_AssignSpaceTypeBySpaceName_skipAssigned
    # create an instance of the measure
    measure = AssignSpaceTypeBySpaceName.new

    # create an instance of a runner
    runner = OpenStudio::Measure::OSRunner.new(OpenStudio::WorkflowJSON.new)

    # load the test model
    translator = OpenStudio::OSVersion::VersionTranslator.new
    path = OpenStudio::Path.new("#{File.dirname(__FILE__)}/ImportedIdf_TestModel.osm")
    model = translator.loadModel(path)
    assert(!model.empty?)
    model = model.get

    # get arguments and test that they are what we are expecting
    arguments = measure.arguments(model)

    # set argument values to good values and run the measure on model with spaces
    argument_map = OpenStudio::Measure.convertOSArgumentVectorToMap(arguments)

    search_string = arguments[0].clone
    assert(search_string.setValue('Corridor'))
    argument_map['search_string'] = search_string

    space_type = arguments[1].clone
    assert(space_type.setValue('189.1-2009 - LrgHotel - Corridor - CZ1-3'))
    argument_map['space_type'] = space_type

    skip_already_assigned = arguments[2].clone
    assert(skip_already_assigned.setValue(true))
    argument_map['skip_already_assigned'] = skip_already_assigned

    measure.run(model, runner, argument_map)
    result = runner.result
    show_output(result)
    assert(result.value.valueName == 'Success')
    # assert(result.warnings.size == 1)
    # assert(result.info.size == 2)

    # save the model in an output directory
    output_dir = File.expand_path('output', File.dirname(__FILE__))
    FileUtils.mkdir output_dir unless Dir.exist? output_dir
    model.save("#{output_dir}/test.osm", true)
  end

  def test_AssignSpaceTypeBySpaceName
    # create an instance of the measure
    measure = AssignSpaceTypeBySpaceName.new

    # create an instance of a runner
    runner = OpenStudio::Measure::OSRunner.new(OpenStudio::WorkflowJSON.new)

    # load the test model
    translator = OpenStudio::OSVersion::VersionTranslator.new
    path = OpenStudio::Path.new("#{File.dirname(__FILE__)}/ImportedIdf_TestModel.osm")
    model = translator.loadModel(path)
    assert(!model.empty?)
    model = model.get

    # get arguments and test that they are what we are expecting
    arguments = measure.arguments(model)

    # set argument values to good values and run the measure on model with spaces
    argument_map = OpenStudio::Measure.convertOSArgumentVectorToMap(arguments)

    search_string = arguments[0].clone
    assert(search_string.setValue('Corridor'))
    argument_map['search_string'] = search_string

    space_type = arguments[1].clone
    assert(space_type.setValue('189.1-2009 - LrgHotel - Corridor - CZ1-3'))
    argument_map['space_type'] = space_type

    skip_already_assigned = arguments[2].clone
    assert(skip_already_assigned.setValue(false))
    argument_map['skip_already_assigned'] = skip_already_assigned

    measure.run(model, runner, argument_map)
    result = runner.result
    # show_output(result)
    assert(result.value.valueName == 'Success')
    # assert(result.warnings.size == 1)
    # assert(result.info.size == 2)

    # save the model
    # output_file_path = OpenStudio::Path.new(File.dirname(__FILE__) + "/test.osm")
    # model.save(output_file_path,true)
  end
end
