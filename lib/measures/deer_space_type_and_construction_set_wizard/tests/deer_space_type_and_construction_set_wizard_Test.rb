# *******************************************************************************
# OpenStudio(R), Copyright (c) Alliance for Sustainable Energy, LLC.
# See also https://openstudio.net/license
# *******************************************************************************

require 'openstudio'
require 'openstudio/measure/ShowRunnerOutput'
require 'fileutils'

require_relative '../measure'
require 'minitest/autorun'

class DEERSpaceTypeAndConstructionSetWizard_Test < Minitest::Test
  def test_empty_seed
    test_name = 'empty_seed'

    # create an instance of the measure
    measure = DEERSpaceTypeAndConstructionSetWizard.new

    # create an instance of a runner
    runner = OpenStudio::Measure::OSRunner.new(OpenStudio::WorkflowJSON.new)

    # load the test model
    translator = OpenStudio::OSVersion::VersionTranslator.new
    path = OpenStudio::Path.new("#{File.dirname(__FILE__)}/EmptySeedModel.osm")
    model = translator.loadModel(path)
    assert(!model.empty?)
    model = model.get

    # get arguments and test that they are what we are expecting
    arguments = measure.arguments(model)
    assert_equal(6, arguments.size)
    count = -1
    assert_equal('building_type', arguments[count += 1].name)
    assert_equal('template', arguments[count += 1].name)
    assert_equal('climate_zone', arguments[count += 1].name)
    assert_equal('create_space_types', arguments[count += 1].name)
    assert_equal('create_construction_set', arguments[count += 1].name)
    assert_equal('set_building_defaults', arguments[count += 1].name)

    # set argument values to good values and run the measure on model with spaces
    argument_map = OpenStudio::Measure.convertOSArgumentVectorToMap(arguments)

    count = -1

    # todo - test failing, are these invalid inputs. They didn't fail in older ext gem based version
    building_type = arguments[count += 1].clone
    assert(building_type.setValue('Asm'))
    argument_map['building_type'] = building_type

    template = arguments[count += 1].clone
    assert(template.setValue('DEER 2017'))
    argument_map['template'] = template

    climate_zone = arguments[count += 1].clone
    assert(climate_zone.setValue('CEC T24-CEC8'))
    argument_map['climate_zone'] = climate_zone

    create_space_types = arguments[count += 1].clone
    assert(create_space_types.setValue(true))
    argument_map['create_space_types'] = create_space_types

    create_construction_set = arguments[count += 1].clone
    assert(create_construction_set.setValue(true))
    argument_map['create_construction_set'] = create_construction_set

    set_building_defaults = arguments[count += 1].clone
    assert(set_building_defaults.setValue(false))
    argument_map['set_building_defaults'] = set_building_defaults

    measure.run(model, runner, argument_map)
    result = runner.result
    show_output(result)
    assert(result.value.valueName == 'Success')
    # assert(result.warnings.size == 1)
    # assert(result.info.size == 2)

    # save the model in an output directory
    output_dir = File.expand_path('output', File.dirname(__FILE__))
    FileUtils.mkdir output_dir unless Dir.exist? output_dir
    model.save("#{output_dir}/#{test_name}_test.osm", true)
  end

  # TODO: - add more tests once DEER building types are re-named
end
