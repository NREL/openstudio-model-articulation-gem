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

require_relative '../spec_helper'

require 'openstudio/common_measures'

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

  it 'can run create_bar_from_building_type_ratios.osw' do
    run_osw('create_bar_from_building_type_ratios', 'create_bar_from_building_type_ratios.osw')
  end
end
