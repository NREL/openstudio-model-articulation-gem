require 'openstudio'
require 'openstudio/ruleset/ShowRunnerOutput'
require 'minitest/autorun'
require_relative '../measure.rb'
require 'fileutils'

class ScaleGeometryTest < MiniTest::Unit::TestCase

  # def setup
  # end

  # def teardown
  # end

  def test_number_of_arguments_and_argument_names
    # create an instance of the measure
    measure = ScaleGeometry.new

    # make an empty model
    model = OpenStudio::Model::Model.new

    # get arguments and test that they are what we are expecting
    arguments = measure.arguments(model)
    assert_equal(3, arguments.size)
    assert_equal("x_scale", arguments[0].name)
    assert_equal("y_scale", arguments[1].name)
    assert_equal("z_scale", arguments[2].name)
  end

  def test_unit_scale
    # create an instance of the measure
    measure = ScaleGeometry.new

    # create an instance of a runner
    runner = OpenStudio::Ruleset::OSRunner.new

    # load the test model
    translator = OpenStudio::OSVersion::VersionTranslator.new
    path = OpenStudio::Path.new(File.dirname(__FILE__) + "/example_model.osm")
    model = translator.loadModel(path)
    assert((not model.empty?))
    model = model.get

    original_floor_area = model.getBuilding.floorArea
    original_exterior_wall_area = 0
    original_volume = 0
    model.getSpaces.each do |space|
      original_exterior_wall_area += space.exteriorWallArea
      original_volume += space.volume
    end

    # get arguments
    arguments = measure.arguments(model)
    argument_map = OpenStudio::Ruleset.convertOSArgumentVectorToMap(arguments)

    # create hash of argument values.
    # If the argument has a default that you want to use, you don't need it in the hash
    args_hash = {}
    args_hash["x_scale"] = 1
    args_hash["y_scale"] = 1
    args_hash["z_scale"] = 1

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
    assert_equal("Success", result.value.valueName)

    # check floor area
    floor_area = model.getBuilding.floorArea
    exterior_wall_area = 0
    volume = 0
    model.getSpaces.each do |space|
      exterior_wall_area += space.exteriorWallArea
      volume += space.volume
    end
    
    assert_equal((1.0*1.0*original_floor_area).round(4), floor_area.round(4))
    assert_equal((1.0*1.0*original_exterior_wall_area).round(4), exterior_wall_area.round(4))
    assert_equal((1.0*1.0*1.0*original_volume).round(4), volume.round(4))
    
    # save the model to test output directory
    output_file_path = OpenStudio::Path.new(File.dirname(__FILE__) + "/output/test_unit_scale.osm")
    model.save(output_file_path,true)
  end
  
  def test_1_1_scale
    # create an instance of the measure
    measure = ScaleGeometry.new

    # create an instance of a runner
    runner = OpenStudio::Ruleset::OSRunner.new

    # load the test model
    translator = OpenStudio::OSVersion::VersionTranslator.new
    path = OpenStudio::Path.new(File.dirname(__FILE__) + "/example_model.osm")
    model = translator.loadModel(path)
    assert((not model.empty?))
    model = model.get

    original_floor_area = model.getBuilding.floorArea
    original_exterior_wall_area = 0
    original_volume = 0
    model.getSpaces.each do |space|
      original_exterior_wall_area += space.exteriorWallArea
      original_volume += space.volume
    end

    # get arguments
    arguments = measure.arguments(model)
    argument_map = OpenStudio::Ruleset.convertOSArgumentVectorToMap(arguments)

    # create hash of argument values.
    # If the argument has a default that you want to use, you don't need it in the hash
    args_hash = {}
    args_hash["x_scale"] = 1.1
    args_hash["y_scale"] = 1.1
    args_hash["z_scale"] = 1.1

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
    assert_equal("Success", result.value.valueName)

    # check floor area 
    floor_area = model.getBuilding.floorArea
    exterior_wall_area = 0
    volume = 0
    model.getSpaces.each do |space|
      exterior_wall_area += space.exteriorWallArea
      volume += space.volume
    end
    
    assert_equal((1.1*1.1*original_floor_area).round(4), floor_area.round(4))
    assert_equal((1.1*1.1*original_exterior_wall_area).round(4), exterior_wall_area.round(4))
    assert_equal((1.1*1.1*1.1*original_volume).round(4), volume.round(4))

    # save the model to test output directory
    output_file_path = OpenStudio::Path.new(File.dirname(__FILE__) + "/output/test_1_1_scale.osm")
    model.save(output_file_path,true)
  end

  def test_0_9_scale
    # create an instance of the measure
    measure = ScaleGeometry.new

    # create an instance of a runner
    runner = OpenStudio::Ruleset::OSRunner.new

    # load the test model
    translator = OpenStudio::OSVersion::VersionTranslator.new
    path = OpenStudio::Path.new(File.dirname(__FILE__) + "/example_model.osm")
    model = translator.loadModel(path)
    assert((not model.empty?))
    model = model.get

    original_floor_area = model.getBuilding.floorArea
    original_exterior_wall_area = 0
    original_volume = 0
    model.getSpaces.each do |space|
      original_exterior_wall_area += space.exteriorWallArea
      original_volume += space.volume
    end

    # get arguments
    arguments = measure.arguments(model)
    argument_map = OpenStudio::Ruleset.convertOSArgumentVectorToMap(arguments)

    # create hash of argument values.
    # If the argument has a default that you want to use, you don't need it in the hash
    args_hash = {}
    args_hash["x_scale"] = 0.9
    args_hash["y_scale"] = 0.9
    args_hash["z_scale"] = 0.9

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
    assert_equal("Success", result.value.valueName)

    # check floor area
    floor_area = model.getBuilding.floorArea
    exterior_wall_area = 0
    volume = 0
    model.getSpaces.each do |space|
      exterior_wall_area += space.exteriorWallArea
      volume += space.volume
    end
    
    assert_equal((0.9*0.9*original_floor_area).round(4), floor_area.round(4))
    assert_equal((0.9*0.9*original_exterior_wall_area).round(4), exterior_wall_area.round(4))
    assert_equal((0.9*0.9*0.9*original_volume).round(4), volume.round(4))

    # save the model to test output directory
    output_file_path = OpenStudio::Path.new(File.dirname(__FILE__) + "/output/test_0_9_scale.osm")
    model.save(output_file_path,true)
  end
  
end
