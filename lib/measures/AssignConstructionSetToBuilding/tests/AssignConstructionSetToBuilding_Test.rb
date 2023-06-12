# *******************************************************************************
# OpenStudio(R), Copyright (c) Alliance for Sustainable Energy, LLC.
# See also https://openstudio.net/license
# *******************************************************************************

require 'openstudio'
require 'openstudio/measure/ShowRunnerOutput'
require 'fileutils'

require_relative '../measure'
require 'minitest/autorun'

class AssignConstructionSetToBuilding_Test < Minitest::Test
  def test_AssignConstructionSetToBuilding
    # create an instance of the measure
    measure = AssignConstructionSetToBuilding.new

    # create an instance of a runner
    runner = OpenStudio::Measure::OSRunner.new(OpenStudio::WorkflowJSON.new)

    # load the test model
    translator = OpenStudio::OSVersion::VersionTranslator.new
    path = OpenStudio::Path.new("#{File.dirname(__FILE__)}/LargeHotel.osm")
    model = translator.loadModel(path)
    assert(!model.empty?)
    model = model.get

    # get arguments and test that they are what we are expecting
    arguments = measure.arguments(model)

    # set argument values to good values and run the measure on model with spaces
    argument_map = OpenStudio::Measure.convertOSArgumentVectorToMap(arguments)

    construction_set = arguments[0].clone
    assert(construction_set.setValue('189.1-2009 - CZ7-8 - LrgHotel'))
    argument_map['construction_set'] = construction_set

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

  def test_AssignConstructionSetToBuilding_clear
    # create an instance of the measure
    measure = AssignConstructionSetToBuilding.new

    # create an instance of a runner
    runner = OpenStudio::Measure::OSRunner.new(OpenStudio::WorkflowJSON.new)

    # load the test model
    translator = OpenStudio::OSVersion::VersionTranslator.new
    path = OpenStudio::Path.new("#{File.dirname(__FILE__)}/LargeHotel.osm")
    model = translator.loadModel(path)
    assert(!model.empty?)
    model = model.get

    # get arguments and test that they are what we are expecting
    arguments = measure.arguments(model)

    # set argument values to good values and run the measure on model with spaces
    argument_map = OpenStudio::Measure.convertOSArgumentVectorToMap(arguments)

    construction_set = arguments[0].clone
    assert(construction_set.setValue('<clear field>'))
    argument_map['construction_set'] = construction_set

    measure.run(model, runner, argument_map)
    result = runner.result
    show_output(result)
    assert(result.value.valueName == 'Success')
    # assert(result.warnings.size == 1)
    # assert(result.info.size == 2)

    # save the model
    # output_file_path = OpenStudio::Path.new(File.dirname(__FILE__) + "/test.osm")
    # model.save(output_file_path,true)
  end
end
