# *******************************************************************************
# OpenStudio(R), Copyright (c) 2008-2021, Alliance for Sustainable Energy, LLC.
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
require 'minitest/autorun'
require 'json'
require_relative '../measure'
require 'fileutils'
require 'socket'

class CreateDEERPrototypeBuildingTest < Minitest::Test
  # Make a directory to save all test output
  def setup
    @test_output_dir = "#{__dir__}/output"
    if !Dir.exist?(@test_output_dir)
      Dir.mkdir(@test_output_dir)
    end
  end

  # method to apply arguments, run measure, and assert results
  def create_deer_prototype_test(test_name, args)
    # create an instance of the measure
    measure = CreateDEERPrototypeBuilding.new

    # create an empty model
    model = OpenStudio::Model::Model.new

    # create a directory to run this test in
    test_dir = "#{@test_output_dir}/#{test_name}"
    if !Dir.exist?(test_dir)
      Dir.mkdir(test_dir)
    end

    # create an instance of a runner with OSW
    osw = OpenStudio::WorkflowJSON.new
    runner = OpenStudio::Measure::OSRunner.new(osw)

    # get arguments
    arguments = measure.arguments(model)
    argument_map = OpenStudio::Measure.convertOSArgumentVectorToMap(arguments)

    # populate argument with specified hash value if specified
    arguments.each do |arg|
      temp_arg_var = arg.clone
      if args.key?(arg.name)
        assert(temp_arg_var.setValue(args[arg.name]), "Could not set #{arg.name} to #{args[arg.name]}")
      end
      argument_map[arg.name] = temp_arg_var
    end

    # temporarily change directory to the run directory and run the measure (because of sizing run)
    start_dir = Dir.pwd
    begin
      Dir.chdir(test_dir)

      # run the measure
      measure.run(model, runner, argument_map)
      result = runner.result
    ensure
      Dir.chdir(start_dir)

      # delete sizing run dir
      # FileUtils.rm_rf(run_dir(test_name))
    end

    # show the output
    puts "measure results for #{test_name}"
    show_output(result)

    # assert that it ran correctly
    assert_equal('Success', result.value.valueName)

    # if 'Fail' passed in make sure at least one error message
    assert(result.errors.size >= 1) if result.value.valueName == 'Fail'

    # save the model to test output directory
    output_file_path = OpenStudio::Path.new("#{__dir__}/output/#{test_name}_output.osm")
    model.save(output_file_path, true)
  end

  def test_asm
    combos = [
      ['Assembly: Split or Packaged DX Unit with Gas Furnace', 'DEER Pre-1975', 'CEC T24-CEC1']
    ]

    combos.each do |combo|
      args = {
        'building_hvac' => combo[0],
        'template' => combo[1],
        'climate_zone' => combo[2]
      }
      test_name = "#{combo[0]}#{combo[1]}#{combo[2]}".gsub(/\W/, '')
      create_deer_prototype_test(test_name, args)
    end

    return true
  end
end
