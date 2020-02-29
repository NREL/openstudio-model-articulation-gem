# *******************************************************************************
# OpenStudio(R), Copyright (c) 2008-2020, Alliance for Sustainable Energy, LLC.
# All rights reserved.
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are met:
#
# (1) Redistributions of source code must retain the above copyright notice,
# this list of conditions and the following disclaimer.
#
# (2) Redistributions in binary form must reproduce the above copyright notice,
# this list of conditions and the following disclaimer in the documentation
# and/or other materials provided with the distribution.
#
# (3) Neither the name of the copyright holder nor the names of any contributors
# may be used to endorse or promote products derived from this software without
# specific prior written permission from the respective party.
#
# (4) Other than as required in clauses (1) and (2), distributions in any form
# of modifications or other derivative works may not use the "OpenStudio"
# trademark, "OS", "os", or any other confusingly similar designation without
# specific prior written permission from Alliance for Sustainable Energy, LLC.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDER(S) AND ANY CONTRIBUTORS
# "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO,
# THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
# ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER(S), ANY CONTRIBUTORS, THE
# UNITED STATES GOVERNMENT, OR THE UNITED STATES DEPARTMENT OF ENERGY, NOR ANY OF
# THEIR EMPLOYEES, BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
# EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT
# OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
# INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT,
# STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY
# OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
# *******************************************************************************

require 'openstudio'
require 'openstudio/measure/ShowRunnerOutput'
require 'fileutils'

require_relative '../measure.rb'
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
