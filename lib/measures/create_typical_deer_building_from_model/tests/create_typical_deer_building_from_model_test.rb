# *******************************************************************************
# OpenStudio(R), Copyright (c) Alliance for Sustainable Energy, LLC.
# See also https://openstudio.net/license
# *******************************************************************************

require 'openstudio'
require 'openstudio/measure/ShowRunnerOutput'
require 'minitest/autorun'
require_relative '../measure'
require 'fileutils'

class CreateTypicalDEERBuildingFromModel_Test < Minitest::Test
  def run_dir(test_name)
    # will make directory if it doesn't exist
    output_dir = File.expand_path('output', File.dirname(__FILE__))
    FileUtils.mkdir output_dir unless Dir.exist? output_dir

    # always generate test output in specially named 'output' directory so result files are not made part of the measure
    "#{File.dirname(__FILE__)}/output/#{test_name}"
  end

  # TODO: - remove excess test files
  # todo - consider minimal testing if combined measuers has full test set

  # method to apply arguments, run measure, and assert results (only populate args hash with non-default argument values)
  def apply_measure_to_model(test_name, args, model_name = nil, result_value = 'Success', warnings_count = 0, info_count = nil)
    # create an instance of the measure
    measure = CreateTypicalDEERBuildingFromModel.new

    # create an instance of a runner with OSW
    osw_path = OpenStudio::Path.new("#{File.dirname(__FILE__)}/measure_test.osw")
    osw = OpenStudio::WorkflowJSON.load(osw_path).get
    runner = OpenStudio::Measure::OSRunner.new(osw)

    if model_name.nil?
      # make an empty model
      model = OpenStudio::Model::Model.new
    else
      # load the test model
      translator = OpenStudio::OSVersion::VersionTranslator.new
      path = OpenStudio::Path.new("#{File.dirname(__FILE__)}/#{model_name}")
      model = translator.loadModel(path)
      assert(!model.empty?)
      model = model.get
    end

    # set the weather file for the test model
    epw_file = OpenStudio::EpwFile.new("#{__dir__}/USA_TX_Houston-Bush.Intercontinental.AP.722430_TMY3.epw")
    OpenStudio::Model::WeatherFile.setWeatherFile(model, epw_file).get

    # Set the day of week for start day
    model.getYearDescription.setDayofWeekforStartDay('Thursday')

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

    # temporarily change directory to the run directory and run the measure (because of sizing run)
    start_dir = Dir.pwd
    begin
      unless Dir.exist?(run_dir(test_name))
        Dir.mkdir(run_dir(test_name))
      end
      Dir.chdir(run_dir(test_name))

      # run the measure
      reset_log
      measure.run(model, runner, argument_map)
      result = runner.result
      log_file_path = "#{Dir.pwd}/openstudio-standards.log"
      log_messages_to_file(log_file_path, false)
    ensure
      Dir.chdir(start_dir)

      # delete sizing run dir
      # FileUtils.rm_rf(run_dir(test_name))
    end

    # show the output
    puts "measure results for #{test_name}"
    show_output(result)

    # assert that it ran correctly
    if result_value.nil? then result_value = 'Success' end
    assert_equal(result_value, result.value.valueName)

    # check count of warning and info messages
    unless info_count.nil? then assert(result.info.size == info_count) end
    unless warnings_count.nil? then assert(result.warnings.size == warnings_count) end

    # if 'Fail' passed in make sure at least one error message (while not typical there may be more than one message)
    if result_value == 'Fail' then assert(result.errors.size >= 1) end

    # save the model to test output directory
    output_file_path = OpenStudio::Path.new(File.dirname(__FILE__) + "/output/#{test_name}_test_output.osm")
    model.save(output_file_path, true)

    # standard = Standard.build('90.1-2004')
    # success = standard.model_run_simulation_and_log_errors(model, File.dirname(__FILE__) + "/output/#{test_name}")
    # assert(success, "")
  end

  def test_asm
    args = {}
    args['template'] = 'DEER Pre-1975'
    args['use_upstream_args'] = false
    apply_measure_to_model(__method__.to_s.gsub('test_', ''), args, 'asm.osm', nil, nil)
  end
end
