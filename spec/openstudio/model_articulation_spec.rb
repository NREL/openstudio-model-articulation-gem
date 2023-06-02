# *******************************************************************************
# OpenStudio(R), Copyright (c) Alliance for Sustainable Energy, LLC.
# See also https://openstudio.net/license
# *******************************************************************************

require_relative '../spec_helper'

def run_osw(test_name, in_osw_filename)
  instance = OpenStudio::ModelArticulation::Extension.new
  runner = OpenStudio::Extension::Runner.new(instance.root_dir)

  in_osw_path = File.join(File.dirname(__FILE__), "../files/#{in_osw_filename}")
  expect(File.exist?(in_osw_path)).to be true

  run_dir = File.join(File.dirname(__FILE__), "../test/#{test_name}/")
  run_osw_path = File.join(run_dir, 'in.osw')
  out_osw_path = File.join(run_dir, 'out.osw')
  failed_job_path = File.join(run_dir, 'failed.job')

  if File.exist?(run_dir)
    FileUtils.rm_rf(run_dir)
  end
  expect(File.exist?(run_dir)).to be false
  expect(File.exist?(run_osw_path)).to be false
  expect(File.exist?(failed_job_path)).to be false

  FileUtils.mkdir_p(run_dir)
  expect(File.exist?(run_dir)).to be true

  result = runner.run_osw(in_osw_path, run_dir)
  expect(result).to be true

  expect(File.exist?(run_osw_path)).to be true
  expect(File.exist?(out_osw_path)).to be true

  if File.exist?(failed_job_path)
    # should make reason for failure more visible
    print(File.read(failed_job_path).split)
  else
    # print(File.read(out_osw_path).split)
  end
  expect(File.exist?(failed_job_path)).to be false
end

RSpec.describe OpenStudio::ModelArticulation do
  it 'has a version number' do
    expect(OpenStudio::ModelArticulation::VERSION).not_to be nil
  end

  it 'has a measures directory' do
    instance = OpenStudio::ModelArticulation::Extension.new
    expect(File.exist?(File.join(instance.measures_dir, 'BarAspectRatioStudy/'))).to be true
  end

  # it 'can run create_bar_from_building_type_ratios.osw' do
  #   run_osw('create_bar_from_building_type_ratios', 'create_bar_from_building_type_ratios.osw')
  # end
end
