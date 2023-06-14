# frozen_string_literal: true

# *******************************************************************************
# OpenStudio(R), Copyright (c) Alliance for Sustainable Energy, LLC.
# See also https://openstudio.net/license
# *******************************************************************************

require 'openstudio'
require 'openstudio/measure/ShowRunnerOutput'
require 'fileutils'

require_relative '../measure'
require 'minitest/autorun'

require 'json'
require 'socket'

class CreateBaselineBuildingTest < Minitest::Unit::TestCase
  def setup
    # Make a directory to save the resulting models
    @test_dir = "#{File.dirname(__FILE__)}/output"
    if !Dir.exist?(@test_dir)
      Dir.mkdir(@test_dir)
    end
  end

  def apply_measure_to_model(model_name, standard, climate_zone, building_type)
    # Create an instance of the measure
    measure = CreateBaselineBuilding.new

    # Create an instance of a runner
    runner = OpenStudio::Measure::OSRunner.new(OpenStudio::WorkflowJSON.new)

    # Load the test model
    translator = OpenStudio::OSVersion::VersionTranslator.new
    path = OpenStudio::Path.new("#{__dir__}/#{model_name}")
    model = translator.loadModel(path)
    assert(model.is_initialized)
    model = model.get

    # set the weather file for the test model
    epw_file = OpenStudio::EpwFile.new("#{__dir__}/USA_TX_Houston-Bush.Intercontinental.AP.722430_TMY3.epw")
    OpenStudio::Model::WeatherFile.setWeatherFile(model, epw_file).get

    # Create an empty argument map
    arguments = measure.arguments(model)
    argument_map = OpenStudio::Measure.convertOSArgumentVectorToMap(arguments)

    # Set argument values
    arg_values = {
      'standard' => standard,
      'building_type' => building_type,
      'climate_zone' => climate_zone,
      'custom' => '*None*',
      'debug' => false
    }

    i = 0
    arg_values.each do |name, val|
      arg = arguments[i].clone
      assert(arg.setValue(val), "Could not set #{name} to #{val}")
      argument_map[name] = arg
      i += 1
    end

    # Run the measure
    measure.run(model, runner, argument_map)
    result = runner.result
    show_output(result)

    # Ensure the measure finished as expected
    assert(result.value.valueName == 'Success')

    model.save(OpenStudio::Path.new("output/#{model_name}_baseline.osm"), true)

    return model
  end

  def test_901_2013_sec_school
    model = apply_measure_to_model('SecondarySchool-DOE Ref Pre-1980-ASHRAE 169-2006-2A.osm', '90.1-2013', 'ASHRAE 169-2013-2A', 'SecondarySchool')
  end

  def test_901_2007_sec_school
    model = apply_measure_to_model('SecondarySchool-DOE Ref Pre-1980-ASHRAE 169-2006-2A.osm', '90.1-2007 BETA', 'ASHRAE 169-2013-2A', 'SecondarySchool')
  end

  def test_901_2010_sec_school
    model = apply_measure_to_model('SecondarySchool-DOE Ref Pre-1980-ASHRAE 169-2006-2A.osm', '90.1-2010 BETA', 'ASHRAE 169-2013-2A', 'SecondarySchool')
  end
end
