require 'openstudio'
require 'openstudio/ruleset/ShowRunnerOutput'
require 'minitest/autorun'
require 'json'
require_relative '../measure.rb'
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
