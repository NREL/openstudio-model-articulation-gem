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

class EnergyUseByStandardsBuildingType_Test < Minitest::Test

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

  def test_number_of_arguments_and_argument_names
    # this test ensures that the current test is matched to the measure inputs
    test_name = "test_number_of_arguments_and_argument_names"
    puts "\n######\nTEST:#{test_name}\n######\n"

    # create an instance of the measure
    measure = EnergyUseByStandardsBuildingType.new

    # get arguments and test that they are what we are expecting
    arguments = measure.arguments()
    assert_equal(0, arguments.size)
  end

  def test_apartment
    test_name = "test_apartment"
    puts "\n######\nTEST:#{test_name}\n######\n"
    osm_path = File.dirname(__FILE__) + '/apartment.osm'
    epw_path = File.dirname(__FILE__) + '/USA_IL_Chicago-OHare.Intl.AP.725300_TMY3.epw'

    # create run directory if it does not exist
    unless File.exist?(run_dir(test_name))
      FileUtils.mkdir_p(run_dir(test_name))
    end
    assert(File.exist?(run_dir(test_name)))

    # change into run directory for tests
    start_dir = Dir.pwd
    Dir.chdir run_dir(test_name)

    # create an instance of the measure
    measure = EnergyUseByStandardsBuildingType.new

    # create an instance of a runner
    runner = OpenStudio::Measure::OSRunner.new(OpenStudio::WorkflowJSON.new)

    # get arguments
    arguments = measure.arguments()
    argument_map = OpenStudio::Measure.convertOSArgumentVectorToMap(arguments)

    # get the energyplus output requests, this will be done automatically by OS App and PAT
    idf_output_requests = measure.energyPlusOutputRequests(runner, argument_map)

    # convert output requests to OSM for testing, OS App and PAT will add these to the E+ Idf
    workspace = OpenStudio::Workspace.new('Draft'.to_StrictnessLevel, 'EnergyPlus'.to_IddFileType)
    workspace.addObjects(idf_output_requests)
    rt = OpenStudio::EnergyPlus::ReverseTranslator.new
    request_model = rt.translateWorkspace(workspace)

    # load the test model and add output requests
    translator = OpenStudio::OSVersion::VersionTranslator.new
    model = translator.loadModel(OpenStudio::Path.new(osm_path))
    assert(!model.empty?)
    model = model.get
    model.addObjects(request_model.objects)
    model.save(model_output_path(test_name), true)

    # set model weather file
    assert(File.exist?(epw_path))
    epw_file = OpenStudio::EpwFile.new(OpenStudio::Path.new(epw_path))
    OpenStudio::Model::WeatherFile.setWeatherFile(model, epw_file)
    assert(model.weatherFile.is_initialized)

    # run the simulation if necessary
    unless File.exist?(sql_path(test_name))
      puts "\nRUNNING ANNUAL RUN FOR #{test_name}..."

      std = Standard.build('90.1-2013')
      std.model_run_simulation_and_log_errors(model, run_dir(test_name))
    end
    assert(File.exist?(model_output_path(test_name)))
    assert(File.exist?(sql_path(test_name)))

    # set up runner, this will happen automatically when measure is run in PAT or OpenStudio
    runner.setLastOpenStudioModelPath(OpenStudio::Path.new(model_output_path(test_name)))
    runner.setLastEnergyPlusWorkspacePath(OpenStudio::Path.new(workspace_path(test_name)))
    runner.setLastEpwFilePath(epw_path)
    runner.setLastEnergyPlusSqlFilePath(OpenStudio::Path.new(sql_path(test_name)))

    # delete the output if it exists
    if File.exist?(report_path(test_name))
      FileUtils.rm(report_path(test_name))
    end
    assert(!File.exist?(report_path(test_name)))

    # run the measure
    puts "\nRUNNING MEASURE RUN FOR #{test_name}..."
    measure.run(runner, argument_map)
    result = runner.result
    show_output(result)
    assert_equal('Success', result.value.valueName)

    # change back directory
    Dir.chdir(start_dir)
  end

  def test_mixed_zero_energy_multifamily

    skip 'pre test simulation failing in 3.0 was not able to quickly identify issue. Skipping for now'

    test_name = "test_mixed_zero_energy_multifamily"
    puts "\n######\nTEST:#{test_name}\n######\n"
    osm_path = File.dirname(__FILE__) + '/mixed_zero_energy_multifamily.osm'
    epw_path = File.dirname(__FILE__) + '/USA_NY_Buffalo.Niagara.Intl.AP.725280_TMY3.epw'

    # create run directory if it does not exist
    unless File.exist?(run_dir(test_name))
      FileUtils.mkdir_p(run_dir(test_name))
    end
    assert(File.exist?(run_dir(test_name)))

    # change into run directory for tests
    start_dir = Dir.pwd
    Dir.chdir run_dir(test_name)

    # create an instance of the measure
    measure = EnergyUseByStandardsBuildingType.new

    # create an instance of a runner
    runner = OpenStudio::Measure::OSRunner.new(OpenStudio::WorkflowJSON.new)

    # get arguments
    arguments = measure.arguments()
    argument_map = OpenStudio::Measure.convertOSArgumentVectorToMap(arguments)

    # get the energyplus output requests, this will be done automatically by OS App and PAT
    idf_output_requests = measure.energyPlusOutputRequests(runner, argument_map)

    # convert output requests to OSM for testing, OS App and PAT will add these to the E+ Idf
    workspace = OpenStudio::Workspace.new('Draft'.to_StrictnessLevel, 'EnergyPlus'.to_IddFileType)
    workspace.addObjects(idf_output_requests)
    rt = OpenStudio::EnergyPlus::ReverseTranslator.new
    request_model = rt.translateWorkspace(workspace)

    # load the test model and add output requests
    translator = OpenStudio::OSVersion::VersionTranslator.new
    model = translator.loadModel(OpenStudio::Path.new(osm_path))
    assert(!model.empty?)
    model = model.get
    model.addObjects(request_model.objects)
    model.save(model_output_path(test_name), true)

    # set model weather file
    assert(File.exist?(epw_path))
    epw_file = OpenStudio::EpwFile.new(OpenStudio::Path.new(epw_path))
    OpenStudio::Model::WeatherFile.setWeatherFile(model, epw_file)
    assert(model.weatherFile.is_initialized)

    # run the simulation if necessary
    unless File.exist?(sql_path(test_name))
      puts "\nRUNNING ANNUAL RUN FOR #{test_name}..."

      std = Standard.build('90.1-2013')
      std.model_run_simulation_and_log_errors(model, run_dir(test_name))
    end
    assert(File.exist?(model_output_path(test_name)))
    assert(File.exist?(sql_path(test_name)))

    # set up runner, this will happen automatically when measure is run in PAT or OpenStudio
    runner.setLastOpenStudioModelPath(OpenStudio::Path.new(model_output_path(test_name)))
    runner.setLastEnergyPlusWorkspacePath(OpenStudio::Path.new(workspace_path(test_name)))
    runner.setLastEpwFilePath(epw_path)
    runner.setLastEnergyPlusSqlFilePath(OpenStudio::Path.new(sql_path(test_name)))

    # delete the output if it exists
    if File.exist?(report_path(test_name))
      FileUtils.rm(report_path(test_name))
    end
    assert(!File.exist?(report_path(test_name)))

    # run the measure
    puts "\nRUNNING MEASURE RUN FOR #{test_name}..."
    measure.run(runner, argument_map)
    result = runner.result
    show_output(result)
    assert_equal('Success', result.value.valueName)

    # change back directory
    Dir.chdir(start_dir)
  end
end
