# *******************************************************************************
# OpenStudio(R), Copyright (c) Alliance for Sustainable Energy, LLC.
# See also https://openstudio.net/license
# *******************************************************************************

require 'openstudio'
require 'openstudio/measure/ShowRunnerOutput'
require 'fileutils'

require_relative '../measure'
require 'minitest/autorun'

class SetWindowToWallRatioByFacade_Test < Minitest::Test
  # def setup
  # end

  # def teardown
  # end

  def test_SetWindowToWallRatioByFacade_fail
    # create an instance of the measure
    measure = SetWindowToWallRatioByFacade.new

    # create an instance of a runner
    runner = OpenStudio::Measure::OSRunner.new(OpenStudio::WorkflowJSON.new)

    # make an empty model
    model = OpenStudio::Model::Model.new

    # get arguments and test that they are what we are expecting
    arguments = measure.arguments(model)
    assert_equal(8, arguments.size)
    assert_equal('wwr', arguments[0].name)
    assert_equal('sillHeight', arguments[1].name)
    assert_equal('facade', arguments[2].name)
    assert_equal('exl_spaces_not_incl_fl_area', arguments[3].name)
    assert_equal('split_at_doors', arguments[4].name)
    assert_equal('inset_tri_sub', arguments[5].name)
    assert_equal('triangulate', arguments[6].name)
    assert_equal('triangulation_min_area', arguments[7].name)

    # set argument values to bad values and run the measure
    argument_map = OpenStudio::Measure.convertOSArgumentVectorToMap(arguments)
    wwr = arguments[0].clone
    assert(wwr.setValue('20'))
    argument_map['wwr'] = wwr
    measure.run(model, runner, argument_map)
    result = runner.result
    assert(result.value.valueName == 'Fail')
  end

  def test_SetWindowToWallRatioByFacade_with_model
    # create an instance of the measure
    measure = SetWindowToWallRatioByFacade.new

    # create an instance of a runner
    runner = OpenStudio::Measure::OSRunner.new(OpenStudio::WorkflowJSON.new)

    # load the test model
    translator = OpenStudio::OSVersion::VersionTranslator.new
    path = OpenStudio::Path.new("#{File.dirname(__FILE__)}/EnvelopeAndLoadTestModel_01.osm")
    model = translator.loadModel(path)
    assert(!model.empty?)
    model = model.get

    # get arguments
    arguments = measure.arguments(model)

    # set argument values to good values and run the measure on model with spaces
    argument_map = OpenStudio::Measure.convertOSArgumentVectorToMap(arguments)

    wwr = arguments[0].clone
    assert(wwr.setValue(0.4))
    argument_map['wwr'] = wwr

    sillHeight = arguments[1].clone
    assert(sillHeight.setValue(30.0))
    argument_map['sillHeight'] = sillHeight

    facade = arguments[2].clone
    assert(facade.setValue('South'))
    argument_map['facade'] = facade

    measure.run(model, runner, argument_map)
    result = runner.result
    # show_output(result)
    assert(result.value.valueName == 'Success')
    # assert(result.warnings.size == 2)
    # assert(result.info.size == 2)

    # save the model
    output_file_path = OpenStudio::Path.new("#{File.dirname(__FILE__)}/output/south.osm")
    model.save(output_file_path, true)
  end

  def test_SetWindowToWallRatioByFacade_with_model_RotationTest
    # create an instance of the measure
    measure = SetWindowToWallRatioByFacade.new

    # create an instance of a runner
    runner = OpenStudio::Measure::OSRunner.new(OpenStudio::WorkflowJSON.new)

    # load the test model
    translator = OpenStudio::OSVersion::VersionTranslator.new
    path = OpenStudio::Path.new("#{File.dirname(__FILE__)}/EnvelopeAndLoadTestModel_02_RotatedSpaceAndBuilding.osm")
    model = translator.loadModel(path)
    assert(!model.empty?)
    model = model.get

    # get arguments
    arguments = measure.arguments(model)

    # set argument values to good values and run the measure on model with spaces
    argument_map = OpenStudio::Measure.convertOSArgumentVectorToMap(arguments)

    wwr = arguments[0].clone
    assert(wwr.setValue(0.4))
    argument_map['wwr'] = wwr

    sillHeight = arguments[1].clone
    assert(sillHeight.setValue(30.0))
    argument_map['sillHeight'] = sillHeight

    facade = arguments[2].clone
    assert(facade.setValue('South'))
    argument_map['facade'] = facade

    measure.run(model, runner, argument_map)
    result = runner.result
    show_output(result)
    assert(result.value.valueName == 'Success')
    # assert(result.warnings.size == 2)
    # assert(result.info.size == 2)

    # save the model
    output_file_path = OpenStudio::Path.new("#{File.dirname(__FILE__)}/output/rotation.osm")
    model.save(output_file_path, true)
  end

  def test_SetWindowToWallRatioByFacade_with_model_MinimalCost
    # create an instance of the measure
    measure = SetWindowToWallRatioByFacade.new

    # create an instance of a runner
    runner = OpenStudio::Measure::OSRunner.new(OpenStudio::WorkflowJSON.new)

    # load the test model
    translator = OpenStudio::OSVersion::VersionTranslator.new
    path = OpenStudio::Path.new("#{File.dirname(__FILE__)}/EnvelopeAndLoadTestModel_01.osm")
    model = translator.loadModel(path)
    assert(!model.empty?)
    model = model.get

    # get arguments
    arguments = measure.arguments(model)

    # set argument values to good values and run the measure on model with spaces
    argument_map = OpenStudio::Measure.convertOSArgumentVectorToMap(arguments)

    wwr = arguments[0].clone
    assert(wwr.setValue(0.4))
    argument_map['wwr'] = wwr

    sillHeight = arguments[1].clone
    assert(sillHeight.setValue(30.0))
    argument_map['sillHeight'] = sillHeight

    facade = arguments[2].clone
    assert(facade.setValue('South'))
    argument_map['facade'] = facade

    measure.run(model, runner, argument_map)
    result = runner.result
    # show_output(result)
    assert(result.value.valueName == 'Success')
    # assert(result.warnings.size == 2)
    # assert(result.info.size == 2)
  end

  def test_SetWindowToWallRatioByFacade_with_model_NoCost
    # create an instance of the measure
    measure = SetWindowToWallRatioByFacade.new

    # create an instance of a runner
    runner = OpenStudio::Measure::OSRunner.new(OpenStudio::WorkflowJSON.new)

    # load the test model
    translator = OpenStudio::OSVersion::VersionTranslator.new
    path = OpenStudio::Path.new("#{File.dirname(__FILE__)}/EnvelopeAndLoadTestModel_01.osm")
    model = translator.loadModel(path)
    assert(!model.empty?)
    model = model.get

    # get arguments
    arguments = measure.arguments(model)

    # set argument values to good values and run the measure on model with spaces
    argument_map = OpenStudio::Measure.convertOSArgumentVectorToMap(arguments)

    wwr = arguments[0].clone
    assert(wwr.setValue(0.4))
    argument_map['wwr'] = wwr

    sillHeight = arguments[1].clone
    assert(sillHeight.setValue(30.0))
    argument_map['sillHeight'] = sillHeight

    facade = arguments[2].clone
    assert(facade.setValue('South'))
    argument_map['facade'] = facade

    measure.run(model, runner, argument_map)
    result = runner.result
    # show_output(result)
    assert(result.value.valueName == 'Success')
    # assert(result.warnings.size == 2)
    # assert(result.info.size == 2)
  end

  def test_SetWindowToWallRatioByFacade_ReverseTranslatedModel
    # create an instance of the measure
    measure = SetWindowToWallRatioByFacade.new

    # create an instance of a runner
    runner = OpenStudio::Measure::OSRunner.new(OpenStudio::WorkflowJSON.new)

    # load the test model
    translator = OpenStudio::OSVersion::VersionTranslator.new
    path = OpenStudio::Path.new("#{File.dirname(__FILE__)}/ReverseTranslatedModel.osm")
    model = translator.loadModel(path)
    assert(!model.empty?)
    model = model.get

    # get arguments
    arguments = measure.arguments(model)

    # set argument values to good values and run the measure on model with spaces
    argument_map = OpenStudio::Measure.convertOSArgumentVectorToMap(arguments)

    wwr = arguments[0].clone
    assert(wwr.setValue(0.4))
    argument_map['wwr'] = wwr

    sillHeight = arguments[1].clone
    assert(sillHeight.setValue(30.0))
    argument_map['sillHeight'] = sillHeight

    facade = arguments[2].clone
    assert(facade.setValue('East'))
    argument_map['facade'] = facade

    measure.run(model, runner, argument_map)
    result = runner.result
    # show_output(result)
    assert(result.value.valueName == 'Success')
    # assert(result.warnings.size == 1)
    # assert(result.info.empty?)
  end

  def test_SetWindowToWallRatioByFacade_EmptySpaceNoLoadsOrSurfaces
    # create an instance of the measure
    measure = SetWindowToWallRatioByFacade.new

    # create an instance of a runner
    runner = OpenStudio::Measure::OSRunner.new(OpenStudio::WorkflowJSON.new)

    # make an empty model
    model = OpenStudio::Model::Model.new

    # add a space to the model without any geometry or loads, want to make sure measure works or fails gracefully
    new_space = OpenStudio::Model::Space.new(model)

    # get arguments
    arguments = measure.arguments(model)

    # set argument values to good values and run the measure on model with spaces
    argument_map = OpenStudio::Measure.convertOSArgumentVectorToMap(arguments)

    wwr = arguments[0].clone
    assert(wwr.setValue(0.4))
    argument_map['wwr'] = wwr

    sillHeight = arguments[1].clone
    assert(sillHeight.setValue(30.0))
    argument_map['sillHeight'] = sillHeight

    facade = arguments[2].clone
    assert(facade.setValue('South'))
    argument_map['facade'] = facade

    measure.run(model, runner, argument_map)
    result = runner.result
    # show_output(result)
    assert(result.value.valueName == 'NA')
    # assert(result.warnings.size == 0)
    # assert(result.info.size == 1)
  end

  def test_triangle
    # create an instance of the measure
    measure = SetWindowToWallRatioByFacade.new

    # create an instance of a runner
    runner = OpenStudio::Measure::OSRunner.new(OpenStudio::WorkflowJSON.new)

    # load the test model
    translator = OpenStudio::OSVersion::VersionTranslator.new
    path = OpenStudio::Path.new("#{File.dirname(__FILE__)}/Triangles.osm")
    model = translator.loadModel(path)
    assert(!model.empty?)
    model = model.get

    # add a space to the model without any geometry or loads, want to make sure measure works or fails gracefully
    new_space = OpenStudio::Model::Space.new(model)

    # get arguments
    arguments = measure.arguments(model)

    # set argument values to good values and run the measure on model with spaces
    argument_map = OpenStudio::Measure.convertOSArgumentVectorToMap(arguments)

    wwr = arguments[0].clone
    assert(wwr.setValue(0.7))
    argument_map['wwr'] = wwr

    sillHeight = arguments[1].clone
    assert(sillHeight.setValue(30.0))
    argument_map['sillHeight'] = sillHeight

    facade = arguments[2].clone
    assert(facade.setValue('South'))
    argument_map['facade'] = facade

    measure.run(model, runner, argument_map)
    result = runner.result
    show_output(result)
    assert(result.value.valueName == 'Success')

    # save the model
    output_file_path = OpenStudio::Path.new("#{File.dirname(__FILE__)}/output/triangle.osm")
    model.save(output_file_path, true)
  end

  def test_pentagon
    # create an instance of the measure
    measure = SetWindowToWallRatioByFacade.new

    # create an instance of a runner
    runner = OpenStudio::Measure::OSRunner.new(OpenStudio::WorkflowJSON.new)

    # load the test model
    translator = OpenStudio::OSVersion::VersionTranslator.new
    path = OpenStudio::Path.new("#{File.dirname(__FILE__)}/Triangles.osm")
    model = translator.loadModel(path)
    assert(!model.empty?)
    model = model.get

    # add a space to the model without any geometry or loads, want to make sure measure works or fails gracefully
    new_space = OpenStudio::Model::Space.new(model)

    # get arguments
    arguments = measure.arguments(model)

    # set argument values to good values and run the measure on model with spaces
    argument_map = OpenStudio::Measure.convertOSArgumentVectorToMap(arguments)

    wwr = arguments[0].clone
    assert(wwr.setValue(0.75))
    argument_map['wwr'] = wwr

    sillHeight = arguments[1].clone
    assert(sillHeight.setValue(30.0))
    argument_map['sillHeight'] = sillHeight

    facade = arguments[2].clone
    assert(facade.setValue('East'))
    argument_map['facade'] = facade

    measure.run(model, runner, argument_map)
    result = runner.result
    show_output(result)
    # assert(result.value.valueName == 'Success')

    # save the model
    output_file_path = OpenStudio::Path.new("#{File.dirname(__FILE__)}/output/pentagon.osm")
    model.save(output_file_path, true)
  end

  def test_sloped
    # create an instance of the measure
    measure = SetWindowToWallRatioByFacade.new

    # create an instance of a runner
    runner = OpenStudio::Measure::OSRunner.new(OpenStudio::WorkflowJSON.new)

    # load the test model
    translator = OpenStudio::OSVersion::VersionTranslator.new
    path = OpenStudio::Path.new("#{File.dirname(__FILE__)}/Triangles.osm")
    model = translator.loadModel(path)
    assert(!model.empty?)
    model = model.get

    # add a space to the model without any geometry or loads, want to make sure measure works or fails gracefully
    new_space = OpenStudio::Model::Space.new(model)

    # get arguments
    arguments = measure.arguments(model)

    # set argument values to good values and run the measure on model with spaces
    argument_map = OpenStudio::Measure.convertOSArgumentVectorToMap(arguments)

    wwr = arguments[0].clone
    assert(wwr.setValue(0.7))
    argument_map['wwr'] = wwr

    sillHeight = arguments[1].clone
    assert(sillHeight.setValue(30.0))
    argument_map['sillHeight'] = sillHeight

    facade = arguments[2].clone
    assert(facade.setValue('North'))
    argument_map['facade'] = facade

    measure.run(model, runner, argument_map)
    result = runner.result
    show_output(result)
    assert(result.value.valueName == 'Success')

    # save the model
    output_file_path = OpenStudio::Path.new("#{File.dirname(__FILE__)}/output/sloped.osm")
    model.save(output_file_path, true)
  end

  def test_door_split
    # create an instance of the measure
    measure = SetWindowToWallRatioByFacade.new

    # create an instance of a runner
    runner = OpenStudio::Measure::OSRunner.new(OpenStudio::WorkflowJSON.new)

    # load the test model
    translator = OpenStudio::OSVersion::VersionTranslator.new
    path = OpenStudio::Path.new("#{File.dirname(__FILE__)}/Triangles.osm")
    model = translator.loadModel(path)
    assert(!model.empty?)
    model = model.get

    # add a space to the model without any geometry or loads, want to make sure measure works or fails gracefully
    new_space = OpenStudio::Model::Space.new(model)

    # get arguments
    arguments = measure.arguments(model)

    # set argument values to good values and run the measure on model with spaces
    argument_map = OpenStudio::Measure.convertOSArgumentVectorToMap(arguments)

    wwr = arguments[0].clone
    assert(wwr.setValue(0.7))
    argument_map['wwr'] = wwr

    sillHeight = arguments[1].clone
    assert(sillHeight.setValue(30.0))
    argument_map['sillHeight'] = sillHeight

    facade = arguments[2].clone
    assert(facade.setValue('West'))
    argument_map['facade'] = facade

    measure.run(model, runner, argument_map)
    result = runner.result
    show_output(result)
    assert(result.value.valueName == 'Success')

    # save the model
    output_file_path = OpenStudio::Path.new("#{File.dirname(__FILE__)}/output/door_split.osm")
    model.save(output_file_path, true)
  end

  def test_door_remove
    # create an instance of the measure
    measure = SetWindowToWallRatioByFacade.new

    # create an instance of a runner
    runner = OpenStudio::Measure::OSRunner.new(OpenStudio::WorkflowJSON.new)

    # load the test model
    translator = OpenStudio::OSVersion::VersionTranslator.new
    path = OpenStudio::Path.new("#{File.dirname(__FILE__)}/Triangles.osm")
    model = translator.loadModel(path)
    assert(!model.empty?)
    model = model.get

    # add a space to the model without any geometry or loads, want to make sure measure works or fails gracefully
    new_space = OpenStudio::Model::Space.new(model)

    # get arguments
    arguments = measure.arguments(model)

    # set argument values to good values and run the measure on model with spaces
    argument_map = OpenStudio::Measure.convertOSArgumentVectorToMap(arguments)

    wwr = arguments[0].clone
    assert(wwr.setValue(0.7))
    argument_map['wwr'] = wwr

    sillHeight = arguments[1].clone
    assert(sillHeight.setValue(30.0))
    argument_map['sillHeight'] = sillHeight

    facade = arguments[2].clone
    assert(facade.setValue('West'))
    argument_map['facade'] = facade

    split_at_doors = arguments[4].clone
    assert(split_at_doors.setValue('Remove Doors'))
    argument_map['split_at_doors'] = split_at_doors

    measure.run(model, runner, argument_map)
    result = runner.result
    show_output(result)
    assert(result.value.valueName == 'Success')

    # save the model
    output_file_path = OpenStudio::Path.new("#{File.dirname(__FILE__)}/output/door_remove.osm")
    model.save(output_file_path, true)
  end

  def test_door_nothing
    # create an instance of the measure
    measure = SetWindowToWallRatioByFacade.new

    # create an instance of a runner
    runner = OpenStudio::Measure::OSRunner.new(OpenStudio::WorkflowJSON.new)

    # load the test model
    translator = OpenStudio::OSVersion::VersionTranslator.new
    path = OpenStudio::Path.new("#{File.dirname(__FILE__)}/Triangles.osm")
    model = translator.loadModel(path)
    assert(!model.empty?)
    model = model.get

    # add a space to the model without any geometry or loads, want to make sure measure works or fails gracefully
    new_space = OpenStudio::Model::Space.new(model)

    # get arguments
    arguments = measure.arguments(model)

    # set argument values to good values and run the measure on model with spaces
    argument_map = OpenStudio::Measure.convertOSArgumentVectorToMap(arguments)

    wwr = arguments[0].clone
    assert(wwr.setValue(0.7))
    argument_map['wwr'] = wwr

    sillHeight = arguments[1].clone
    assert(sillHeight.setValue(30.0))
    argument_map['sillHeight'] = sillHeight

    facade = arguments[2].clone
    assert(facade.setValue('West'))
    argument_map['facade'] = facade

    split_at_doors = arguments[4].clone
    assert(split_at_doors.setValue('Do nothing to Doors'))
    argument_map['split_at_doors'] = split_at_doors

    measure.run(model, runner, argument_map)
    result = runner.result
    show_output(result)

    assert(result.value.valueName == 'Success')

    # save the model
    output_file_path = OpenStudio::Path.new("#{File.dirname(__FILE__)}/output/door_nothing.osm")
    model.save(output_file_path, true)
  end

  def test_not_in_floor_area
    # create an instance of the measure
    measure = SetWindowToWallRatioByFacade.new

    # create an instance of a runner
    runner = OpenStudio::Measure::OSRunner.new(OpenStudio::WorkflowJSON.new)

    # load the test model
    translator = OpenStudio::OSVersion::VersionTranslator.new
    path = OpenStudio::Path.new("#{File.dirname(__FILE__)}/EnvelopeAndLoadTestModel_01.osm")
    model = translator.loadModel(path)
    assert(!model.empty?)
    model = model.get

    # get arguments
    arguments = measure.arguments(model)

    # set argument values to good values and run the measure on model with spaces
    argument_map = OpenStudio::Measure.convertOSArgumentVectorToMap(arguments)

    wwr = arguments[0].clone
    assert(wwr.setValue(0.9))
    argument_map['wwr'] = wwr

    sillHeight = arguments[1].clone
    assert(sillHeight.setValue(72.0))
    argument_map['sillHeight'] = sillHeight

    facade = arguments[2].clone
    assert(facade.setValue('South'))
    argument_map['facade'] = facade

    exl_spaces_not_incl_fl_area = arguments[3].clone
    assert(exl_spaces_not_incl_fl_area.setValue(false))
    argument_map['exl_spaces_not_incl_fl_area'] = exl_spaces_not_incl_fl_area

    measure.run(model, runner, argument_map)
    result = runner.result
    # show_output(result)
    assert(result.value.valueName == 'Success')

    # save the model
    output_file_path = OpenStudio::Path.new("#{File.dirname(__FILE__)}/output/not_in_floor_area.osm")
    model.save(output_file_path, true)
  end

  def test_SetWindowToWallRatioByFacade_zero_target
    # create an instance of the measure
    measure = SetWindowToWallRatioByFacade.new

    # create an instance of a runner
    runner = OpenStudio::Measure::OSRunner.new(OpenStudio::WorkflowJSON.new)

    # load the test model
    translator = OpenStudio::OSVersion::VersionTranslator.new
    path = OpenStudio::Path.new("#{File.dirname(__FILE__)}/EnvelopeAndLoadTestModel_01.osm")
    model = translator.loadModel(path)
    assert(!model.empty?)
    model = model.get

    # get arguments
    arguments = measure.arguments(model)

    # set argument values to good values and run the measure on model with spaces
    argument_map = OpenStudio::Measure.convertOSArgumentVectorToMap(arguments)

    wwr = arguments[0].clone
    assert(wwr.setValue(0.0))
    argument_map['wwr'] = wwr

    sillHeight = arguments[1].clone
    assert(sillHeight.setValue(30.0))
    argument_map['sillHeight'] = sillHeight

    facade = arguments[2].clone
    assert(facade.setValue('South'))
    argument_map['facade'] = facade

    measure.run(model, runner, argument_map)
    result = runner.result
    show_output(result)
    assert(result.value.valueName == 'Success')
    # assert(result.warnings.size == 2)
    # assert(result.info.size == 2)

    # save the model
    output_file_path = OpenStudio::Path.new("#{File.dirname(__FILE__)}/output/zero.osm")
    model.save(output_file_path, true)
  end

  def test_SetWindowToWallRatioByFacade_all_orientations
    # create an instance of the measure
    measure = SetWindowToWallRatioByFacade.new

    # create an instance of a runner
    runner = OpenStudio::Measure::OSRunner.new(OpenStudio::WorkflowJSON.new)

    # load the test model
    translator = OpenStudio::OSVersion::VersionTranslator.new
    path = OpenStudio::Path.new("#{File.dirname(__FILE__)}/EnvelopeAndLoadTestModel_01.osm")
    model = translator.loadModel(path)
    assert(!model.empty?)
    model = model.get

    # get arguments
    arguments = measure.arguments(model)

    # set argument values to good values and run the measure on model with spaces
    argument_map = OpenStudio::Measure.convertOSArgumentVectorToMap(arguments)

    wwr = arguments[0].clone
    assert(wwr.setValue(0.7))
    argument_map['wwr'] = wwr

    sillHeight = arguments[1].clone
    assert(sillHeight.setValue(30.0))
    argument_map['sillHeight'] = sillHeight

    facade = arguments[2].clone
    assert(facade.setValue('All'))
    argument_map['facade'] = facade

    measure.run(model, runner, argument_map)
    result = runner.result
    show_output(result)
    assert(result.value.valueName == 'Success')
    # assert(result.warnings.size == 2)
    # assert(result.info.size == 2)

    # save the model
    output_file_path = OpenStudio::Path.new("#{File.dirname(__FILE__)}/output/all_orientations.osm")
    model.save(output_file_path, true)
  end

  # this has multiple sub-surafces in base surfaes, including more than 1 door and more than one window
  def test_SetWindowToWallRatioByFacade_sec_school
    # create an instance of the measure
    measure = SetWindowToWallRatioByFacade.new

    # create an instance of a runner
    runner = OpenStudio::Measure::OSRunner.new(OpenStudio::WorkflowJSON.new)

    # load the test model
    translator = OpenStudio::OSVersion::VersionTranslator.new
    path = OpenStudio::Path.new("#{File.dirname(__FILE__)}/prototype_sec_sch.osm")
    model = translator.loadModel(path)
    assert(!model.empty?)
    model = model.get

    # get arguments
    arguments = measure.arguments(model)

    # set argument values to good values and run the measure on model with spaces
    argument_map = OpenStudio::Measure.convertOSArgumentVectorToMap(arguments)

    wwr = arguments[0].clone
    assert(wwr.setValue(0.7))
    argument_map['wwr'] = wwr

    sillHeight = arguments[1].clone
    assert(sillHeight.setValue(30.0))
    argument_map['sillHeight'] = sillHeight

    facade = arguments[2].clone
    assert(facade.setValue('All'))
    argument_map['facade'] = facade

    measure.run(model, runner, argument_map)
    result = runner.result
    show_output(result)
    assert(result.value.valueName == 'Success')
    # assert(result.warnings.size == 2)
    # assert(result.info.size == 2)

    # save the model
    output_file_path = OpenStudio::Path.new("#{File.dirname(__FILE__)}/output/sec_school.osm")
    model.save(output_file_path, true)
  end
end
