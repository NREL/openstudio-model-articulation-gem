require 'openstudio'
require 'openstudio/ruleset/ShowRunnerOutput'
require 'minitest/autorun'

require_relative '../measure.rb'

require 'fileutils'

class CreateSpacesFromDXFDiagramTest < MiniTest::Unit::TestCase

  def test_acad360
    # create an instance of the measure
    measure = CreateSpacesFromDXFDiagram.new

    # create an instance of a runner
    runner = OpenStudio::Ruleset::OSRunner.new

    # make an empty model
    model = OpenStudio::Model::Model.new

    # check that there are no spaces
    assert_equal(0, model.getSpaces.size)

    # get arguments
    arguments = measure.arguments(model)
    argument_map = OpenStudio::Ruleset.convertOSArgumentVectorToMap(arguments)

    # set argument values to good values
    dxf_path = arguments[0].clone
    assert(dxf_path.setValue(File.dirname(__FILE__) + "/autocad360_polygon_cw.dxf"))
    argument_map["dxf_path"] = dxf_path

    floor_to_floor_height = arguments[1].clone
    assert(floor_to_floor_height.setValue(10.0))
    argument_map["floor_to_floor_height"] = floor_to_floor_height

    num_floors = arguments[2].clone
    assert(num_floors.setValue(3))
    argument_map["num_floors"] = num_floors

    base_height = arguments[3].clone
    assert(base_height.setValue(20))
    argument_map["base_height"] = base_height

    # run the measure
    measure.run(model, runner, argument_map)
    result = runner.result
    show_output(result)
    assert_equal("Success", result.value.valueName)

    #save the model
    #output_file_path = OpenStudio::Path.new(File.dirname(__FILE__) + "output/test_acad360.osm")
    #model.save(output_file_path,true)

  end

  def test_inkscape
    # create an instance of the measure
    measure = CreateSpacesFromDXFDiagram.new

    # create an instance of a runner
    runner = OpenStudio::Ruleset::OSRunner.new

    # make an empty model
    model = OpenStudio::Model::Model.new

    # check that there are no spaces
    assert_equal(0, model.getSpaces.size)

    # get arguments
    arguments = measure.arguments(model)
    argument_map = OpenStudio::Ruleset.convertOSArgumentVectorToMap(arguments)

    # set argument values to good values
    dxf_path = arguments[0].clone
    #assert(dxf_path.setValue(File.dirname(__FILE__) + "/inkscape_test.dxf"))
    #assert(dxf_path.setValue(File.dirname(__FILE__) + "/inkscape_test2a.dxf"))
    #assert(dxf_path.setValue(File.dirname(__FILE__) + "/inkscape_test2b.dxf"))
    assert(dxf_path.setValue(File.dirname(__FILE__) + "/inkscape_test3.dxf"))
    argument_map["dxf_path"] = dxf_path

    floor_to_floor_height = arguments[1].clone
    assert(floor_to_floor_height.setValue(10.0))
    argument_map["floor_to_floor_height"] = floor_to_floor_height

    num_floors = arguments[2].clone
    assert(num_floors.setValue(3))
    argument_map["num_floors"] = num_floors

    base_height = arguments[3].clone
    assert(base_height.setValue(20))
    argument_map["base_height"] = base_height

    # run the measure
    measure.run(model, runner, argument_map)
    result = runner.result
    show_output(result)
    assert_equal("Success", result.value.valueName)

    #save the model
    output_file_path = OpenStudio::Path.new(File.dirname(__FILE__) + "/output/test_inkscape.osm")
    model.save(output_file_path,true)

  end

end
