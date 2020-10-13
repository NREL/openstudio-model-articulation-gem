# *******************************************************************************
# OpenStudio(R), Copyright (c) 2008-2018, Alliance for Sustainable Energy, LLC.
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
require 'openstudio-standards'
require 'openstudio/ruleset/ShowRunnerOutput'
require 'minitest/autorun'
require_relative '../measure.rb'
require 'fileutils'

class MultifamilyCentralWasteWaterHeatPump_Test < Minitest::Test
  def run_dir(test_name)
    # always generate test output in specially named 'output' directory so result files are not made part of the measure
    return "#{File.dirname(__FILE__)}/output/#{test_name}"
  end

  def model_output_path(test_name)
    return "#{run_dir(test_name)}/#{test_name}.osm"
  end

  def workspace_path(test_name)
    return "#{run_dir(test_name)}/run/in.idf"
  end

  def sql_path(test_name)
    return "#{run_dir(test_name)}/run/eplusout.sql"
  end

  def report_path(test_name)
    return "#{run_dir(test_name)}/reports/eplustbl.html"
  end

  # method to apply arguments, run measure, and assert results (only populate args hash with non-default argument values)
  def apply_and_run_measure(test_name, osm_path, epw_path, args, annual_run: false)

    # create run directory if it does not exist
    unless File.exist?(run_dir(test_name))
      FileUtils.mkdir_p(run_dir(test_name))
    end
    assert(File.exist?(run_dir(test_name)))

    # change into run directory for tests
    start_dir = Dir.pwd
    Dir.chdir run_dir(test_name)

    # remove prior runs if they exist
    if File.exist?(model_output_path(test_name))
      FileUtils.rm(model_output_path(test_name))
    end
    if File.exist?(report_path(test_name))
      FileUtils.rm(report_path(test_name))
    end

    if osm_path.empty?
      # generate empty model
      model = OpenStudio::Model::Model.new
    else
      # load the test model
      translator = OpenStudio::OSVersion::VersionTranslator.new
      model = translator.loadModel(OpenStudio::Path.new(osm_path))
      assert(!model.empty?)
      model = model.get
    end

    # set model weather file
    epw_file = OpenStudio::EpwFile.new(OpenStudio::Path.new(epw_path))
    OpenStudio::Model::WeatherFile.setWeatherFile(model, epw_file)
    assert(model.weatherFile.is_initialized)

    # reset the log
    reset_log

    # create an instance of the measure
    measure = MultifamilyCentralWasteWaterHeatPump.new

    # create an instance of a runner
    runner = OpenStudio::Measure::OSRunner.new(OpenStudio::WorkflowJSON.new)

    # get arguments
    arguments = measure.arguments(model)
    argument_map = OpenStudio::Measure.convertOSArgumentVectorToMap(arguments)

    # populate argument with specified hash value if specified
    arguments.each do |arg|
      temp_arg_var = arg.clone
      if args.key?(arg.name)
        assert(temp_arg_var.setValue(args[arg.name]))
      end
      argument_map[arg.name] = temp_arg_var
    end

    # run the measure
    puts "\nAPPLYING MEASURE FOR #{test_name}..."
    measure.run(model, runner, argument_map)
    result = runner.result
    log_file_path = "#{Dir.pwd}/openstudio-standards.log"
    log_messages_to_file(log_file_path, false)

    # show the output
    puts "\nMEASURE RESULTS FOR #{test_name}:"
    show_output(result)

    # save model to test output directory
    model.save(model_output_path(test_name), true)

    if annual_run && (result.value.valueName == 'Success')
      puts "\nRUNNING ANNUAL RUN FOR #{test_name}..."

      std = Standard.build('NREL ZNE Ready 2017')
      std.model_run_simulation_and_log_errors(model, run_dir(test_name))

      # check that the model ran successfully and generated a report
      assert(File.exist?(model_output_path(test_name)))
      assert(File.exist?(sql_path(test_name)))
      assert(File.exist?(report_path(test_name)))
    end

    # change back directory
    Dir.chdir(start_dir)
    return result
  end

  def test_number_of_arguments_and_argument_names
    # this test ensures that the current test is matched to the measure inputs
    test_name = "test_number_of_arguments_and_argument_names"
    puts "\n######\nTEST:#{test_name}\n######\n"

    # create an instance of the measure
    measure = MultifamilyCentralWasteWaterHeatPump.new

    # empty model
    model = OpenStudio::Model::Model.new

    # get arguments and test that they are what we are expecting
    arguments = measure.arguments(model)
    assert_equal(1, arguments.size)
    assert_equal('swh_type', arguments[0].name)
  end

  def test_simple_apartment_central
    test_name = 'test_simple_apartment_central'
    puts "\n######\nTEST:#{test_name}\n######\n"
    osm_path = File.dirname(__FILE__) + '/MidriseApartment.osm'
    epw_path = File.dirname(__FILE__) + '/USA_TX_Houston-Bush.Intercontinental.AP.722430_TMY3.epw'
    args = {}
    args['swh_type'] = 'Waste Water Heat Pump 140F Supply'
    result = apply_and_run_measure(test_name, osm_path, epw_path, args, annual_run: false)
    assert_equal(result.value.valueName, 'Success')
  end

  def test_simple_apartment_central_with_in_unit_tank
    test_name = 'test_simple_apartment_central_with_in_unit_tank'
    puts "\n######\nTEST:#{test_name}\n######\n"
    osm_path = File.dirname(__FILE__) + '/MidriseApartment.osm'
    epw_path = File.dirname(__FILE__) + '/USA_TX_Houston-Bush.Intercontinental.AP.722430_TMY3.epw'
    args = {}
    args['swh_type'] = 'Waste Water Heat Pump 90F Supply and Electric Tank'
    result = apply_and_run_measure(test_name, osm_path, epw_path, args, annual_run: false)
    assert_equal(result.value.valueName, 'Success')
  end

  def test_apartment_central
    test_name = 'test_apartment_central'
    puts "\n######\nTEST:#{test_name}\n######\n"
    osm_path = File.dirname(__FILE__) + '/apartment.osm'
    epw_path = File.dirname(__FILE__) + '/USA_IL_Chicago-OHare.Intl.AP.725300_TMY3.epw'
    args = {}
    args['swh_type'] = 'Waste Water Heat Pump 140F Supply'
    result = apply_and_run_measure(test_name, osm_path, epw_path, args, annual_run: false)
    assert_equal(result.value.valueName, 'Success')
  end

  def test_apartment_central_with_in_unit_tank
    test_name = 'test_apartment_central_with_in_unit_tank'
    puts "\n######\nTEST:#{test_name}\n######\n"
    osm_path = File.dirname(__FILE__) + '/apartment.osm'
    epw_path = File.dirname(__FILE__) + '/USA_IL_Chicago-OHare.Intl.AP.725300_TMY3.epw'
    args = {}
    args['swh_type'] = 'Waste Water Heat Pump 90F Supply and Electric Tank'
    result = apply_and_run_measure(test_name, osm_path, epw_path, args, annual_run: false)
    assert_equal(result.value.valueName, 'Success')
  end
end
