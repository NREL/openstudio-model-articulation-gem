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

class RadianceMeasureTest < Minitest::Test
  # def setup
  # end

  # def teardown
  # end

  def get_test_model(shade_type)
    translator = OpenStudio::OSVersion::VersionTranslator.new
    path = OpenStudio::Path.new(File.dirname(__FILE__) + '/test_model.osm')
    model = translator.loadModel(path)
    assert(!model.empty?)

    model = model.get

    new_shade_control = nil
    if shade_type == 'Default'
      # do nothing, use model as is
    elsif shade_type == 'None'
      # remove shading controls
      model.getShadingControls.each(&:remove)
    elsif shade_type == 'Blind'
      new_shade_control = OpenStudio::Model::ShadingControl.new(OpenStudio::Model::Blind.new(model))
    elsif shade_type == 'DaylightRedirectionDevice'
      new_shade_control = OpenStudio::Model::ShadingControl.new(OpenStudio::Model::DaylightRedirectionDevice.new(model))
    elsif shade_type == 'Screen'
      new_shade_control = OpenStudio::Model::ShadingControl.new(OpenStudio::Model::Screen.new(model))
    elsif shade_type == 'Shade'
      new_shade_control = OpenStudio::Model::ShadingControl.new(OpenStudio::Model::Shade.new(model))
    end

    if new_shade_control
      # replace all existing shading controls with the new one
      model.getSubSurfaces.each do |s|
        unless s.shadingControl.empty?
          s.setShadingControl(new_shade_control)
        end
      end
    end

    return model
  end

  def run_with_test_model(shade_type, user_args = {})
    # record current directory
    current_dir = Dir.pwd

    # create an instance of the measure
    measure = RadianceMeasure.new

    # create an instance of a runner
    runner = OpenStudio::Measure::OSRunner.new(OpenStudio::WorkflowJSON.new)

    # set up runner, this will happen automatically when measure is run in PAT

    runner.setLastEpwFilePath(File.dirname(__FILE__) + '/USA_CO_Golden-NREL.724666_TMY3.epw')

    # load the test model
    model = get_test_model(shade_type)

    weather_file = runner.lastEpwFilePath.get
    epw_file = OpenStudio::EpwFile.new(weather_file)
    OpenStudio::Model::WeatherFile.setWeatherFile(model, epw_file).get

    site = model.getSite
    site.setName('Test Site')
    site.setLatitude(epw_file.latitude)
    site.setLongitude(epw_file.longitude)
    site.setTimeZone(epw_file.timeZone)

    # store the number of spaces in the seed model
    num_spaces_seed = model.getSpaces.size

    # get arguments
    arguments = measure.arguments(model)
    argument_map = OpenStudio::Measure.convertOSArgumentVectorToMap(arguments)

    # create hash of argument values.
    # If the argument has a default that you want to use, you don't need it in the hash
    args_hash = {}
    args_hash['apply_schedules'] = 'true'
    args_hash['use_cores'] = 'Max'
    args_hash['rad_settings'] = 'Testing'
    args_hash['debug_mode'] = 'false'
    args_hash['cleanup_data'] = 'true'
    args_hash.merge!(user_args)

    # populate argument with specified hash value if specified
    arguments.each do |arg|
      temp_arg_var = arg.clone
      puts arg.name
      if args_hash[arg.name]
        puts "setting #{arg.name} = #{args_hash[arg.name]}"
        assert(temp_arg_var.setValue(args_hash[arg.name]))
      end
      argument_map[arg.name] = temp_arg_var
    end

    # move to output dir
    out_dir = File.join(File.dirname(__FILE__), 'output', shade_type)
    unless File.exist?(out_dir)
      FileUtils.mkdir_p(out_dir)
    end
    Dir.chdir(out_dir)

    # check schedules
    num_rad_schedules = 0
    model.getScheduleFixedIntervals.each do |sch|
      if /Lights Schedule$/.match(sch.nameString)
        num_rad_schedules += 1
      end
    end
    assert_equal(0, num_rad_schedules)

    # run the measure
    measure.run(model, runner, argument_map)
    result = runner.result

    # check schedules
    num_rad_schedules = 0
    model.getScheduleFixedIntervals.each do |sch|
      if /Lights Schedule$/.match(sch.nameString)
        num_rad_schedules += 1
      end
    end
    if args_hash['apply_schedules'] == 'true'
      assert_equal(2, num_rad_schedules)
    else
      assert_equal(0, num_rad_schedules)
    end

    # save the model to test output directory
    output_file_path = OpenStudio::Path.new('./test_output.osm')
    model.save(output_file_path, true)
    
    # show the output
    show_output(result)
    
    runner.registerInfo(" Encoding.default_external = #{Encoding.default_external}")
    runner.registerInfo(" Encoding.default_internal = #{Encoding.default_internal}")

    # assert that it ran correctly
    assert_equal('Success', result.value.valueName.to_s)
    assert(result.warnings.empty?)

  ensure
    Dir.chdir(current_dir)
  end

  def test_number_of_arguments_and_argument_names
    # create an instance of the measure
    measure = RadianceMeasure.new

    # make an empty model
    model = OpenStudio::Model::Model.new

    # get arguments and test that they are what we are expecting
    arguments = measure.arguments(model)
    assert_equal(5, arguments.size)
    assert_equal('apply_schedules', arguments[0].name)
    assert_equal('use_cores', arguments[1].name)
    assert_equal('rad_settings', arguments[2].name)
    assert_equal('debug_mode', arguments[3].name)
    assert_equal('cleanup_data', arguments[4].name)
  end

  def test_default
    run_with_test_model('Default', {'rad_settings'=> 'Model'})
  end

  def test_none
    run_with_test_model('None', {'rad_settings'=> 'High'})
  end

  def test_blind
    run_with_test_model('Blind')
  end  

  def test_drd
    run_with_test_model('DaylightRedirectionDevice')
  end

  def test_screen
    run_with_test_model('Screen', {'apply_schedules'=> 'false'})
  end

  def test_shade
    run_with_test_model('Shade')
  end

end
