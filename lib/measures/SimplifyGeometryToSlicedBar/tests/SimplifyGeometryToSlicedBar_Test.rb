require 'openstudio'

require 'openstudio/ruleset/ShowRunnerOutput'

require_relative '../measure.rb'

require 'minitest/autorun'

class SimplifyGeometryToSlicedBar_Test < MiniTest::Unit::TestCase

  
  def test_SimplifyGeometryToSlicedBar
     
    # create an instance of the measure
    measure = SimplifyGeometryToSlicedBar.new
    
    # create an instance of a runner
    runner = OpenStudio::Ruleset::OSRunner.new

    # load the test model
    translator = OpenStudio::OSVersion::VersionTranslator.new
    path = OpenStudio::Path.new(File.dirname(__FILE__) + "/UShapedHotelExample.osm")
    model = translator.loadModel(path)
    assert((not model.empty?))
    model = model.get
    
    # get arguments and test that they are what we are expecting
    arguments = measure.arguments(model)
    assert_equal(1, arguments.size)
       
    # set argument values to good values and run the measure on model with spaces
    argument_map = OpenStudio::Ruleset::OSArgumentMap.new

    logic = arguments[0].clone
    #assert(logic.setValue("Maintain Bounding Box Aspect Ratio"))
    #assert(logic.setValue("Maintain Total Exterior Wall Area"))
    assert(logic.setValue("Maintain Facade Specific Exterior Wall Area"))
    argument_map["logic"] = logic

    measure.run(model, runner, argument_map)
    result = runner.result
    show_output(result)
    assert(result.value.valueName == "Success")
    #assert(result.warnings.size == 1)
    #assert(result.info.size == 2)

    # save the model in an output directory
    output_dir = File.expand_path('output', File.dirname(__FILE__))
    FileUtils.mkdir output_dir unless Dir.exist? output_dir
    model.save("#{output_dir}/test.osm", true)

  end  

end
