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
require_relative '../measure.rb'
require 'fileutils'

class InjectOsmGeometryIntoAnExternalIdf_Test < MiniTest::Test
  def test_InjectOsmGeometryIntoAnExternalIdf_a
    # create an instance of the measure
    measure = InjectOsmGeometryIntoAnExternalIdf.new

    # make an empty model
    model = OpenStudio::Model::Model.new

    # forward translate OSM file to IDF file
    ft = OpenStudio::EnergyPlus::ForwardTranslator.new
    workspace = ft.translateModel(model)

    # get arguments and test that they are what we are expecting
    arguments = measure.arguments(workspace)
    assert_equal(2, arguments.size)
  end

  def test_InjectOsmGeometryIntoAnExternalIdf_b
    # create an instance of the measure
    measure = InjectOsmGeometryIntoAnExternalIdf.new

    # create an instance of a runner with OSW
    osw_path = OpenStudio::Path.new(File.dirname(__FILE__) + '/measure_test.osw')
    osw = OpenStudio::WorkflowJSON.load(osw_path).get
    runner = OpenStudio::Measure::OSRunner.new(osw)

    # load the test model
    translator = OpenStudio::OSVersion::VersionTranslator.new
    path = OpenStudio::Path.new(File.dirname(__FILE__) + '/RefBldgMediumOfficeNew2004_Chicago_AlteredGeo_b.osm')
    model = translator.loadModel(path)
    assert(!model.empty?)
    model = model.get

    # forward translate OSM file to IDF file
    ft = OpenStudio::EnergyPlus::ForwardTranslator.new
    workspace = ft.translateModel(model)

    # get arguments and test that they are what we are expecting
    arguments = measure.arguments(workspace)
    argument_map = OpenStudio::Measure::OSArgumentMap.new

    count = -1

    source_idf_path = arguments[count += 1].clone
    assert(source_idf_path.setValue(File.dirname(__FILE__) + '/RefBldgMediumOfficeNew2004_Chicago.idf'))
    argument_map['source_idf_path'] = source_idf_path

    merge_geometry_from_osm = arguments[count += 1].clone
    assert(merge_geometry_from_osm.setValue(true))
    argument_map['merge_geometry_from_osm'] = merge_geometry_from_osm

    measure.run(workspace, runner, argument_map)
    result = runner.result
    show_output(result)
    assert(result.value.valueName == 'Success')
  end

  def test_InjectOsmGeometryIntoAnExternalIdf_c_NoNewGeometry
    # create an instance of the measure
    measure = InjectOsmGeometryIntoAnExternalIdf.new

    # create an instance of a runner with OSW
    osw_path = OpenStudio::Path.new(File.dirname(__FILE__) + '/measure_test.osw')
    osw = OpenStudio::WorkflowJSON.load(osw_path).get
    runner = OpenStudio::Measure::OSRunner.new(osw)

    # load the test model
    translator = OpenStudio::OSVersion::VersionTranslator.new
    path = OpenStudio::Path.new(File.dirname(__FILE__) + '/RefBldgMediumOfficeNew2004_Chicago_AlteredGeo_b.osm')
    model = translator.loadModel(path)
    assert(!model.empty?)
    model = model.get

    # forward translate OSM file to IDF file
    ft = OpenStudio::EnergyPlus::ForwardTranslator.new
    workspace = ft.translateModel(model)

    # get arguments and test that they are what we are expecting
    arguments = measure.arguments(workspace)
    argument_map = OpenStudio::Measure::OSArgumentMap.new

    count = -1

    source_idf_path = arguments[count += 1].clone
    assert(source_idf_path.setValue(File.dirname(__FILE__) + '/RefBldgMediumOfficeNew2004_Chicago.idf'))
    argument_map['source_idf_path'] = source_idf_path

    merge_geometry_from_osm = arguments[count += 1].clone
    assert(merge_geometry_from_osm.setValue(false))
    argument_map['merge_geometry_from_osm'] = merge_geometry_from_osm

    measure.run(workspace, runner, argument_map)
    result = runner.result
    show_output(result)
    assert(result.value.valueName == 'Success')

    # save the model
    # output_file_path = OpenStudio::Path.new('C:\SVN_Utilities\OpenStudio\measures\test_Ref.idf')
    # workspace.save(output_file_path,true) #why isn't this returning the altered model
  end

  def test_InjectOsmGeometryIntoAnExternalIdf_d_Simple
    # create an instance of the measure
    measure = InjectOsmGeometryIntoAnExternalIdf.new

    # create an instance of a runner with OSW
    osw_path = OpenStudio::Path.new(File.dirname(__FILE__) + '/measure_test.osw')
    osw = OpenStudio::WorkflowJSON.load(osw_path).get
    runner = OpenStudio::Measure::OSRunner.new(osw)

    # load the test model
    translator = OpenStudio::OSVersion::VersionTranslator.new
    path = OpenStudio::Path.new(File.dirname(__FILE__) + '/4ZoneWithShading_Simple_1_AlteredGeo.osm')
    model = translator.loadModel(path)
    assert(!model.empty?)
    model = model.get

    # forward translate OSM file to IDF file
    ft = OpenStudio::EnergyPlus::ForwardTranslator.new
    workspace = ft.translateModel(model)

    # get arguments and test that they are what we are expecting
    arguments = measure.arguments(workspace)
    argument_map = OpenStudio::Measure::OSArgumentMap.new

    count = -1

    source_idf_path = arguments[count += 1].clone
    assert(source_idf_path.setValue(File.dirname(__FILE__) + '/4ZoneWithShading_Simple_1.idf'))
    argument_map['source_idf_path'] = source_idf_path

    merge_geometry_from_osm = arguments[count += 1].clone
    assert(merge_geometry_from_osm.setValue(true))
    argument_map['merge_geometry_from_osm'] = merge_geometry_from_osm

    measure.run(workspace, runner, argument_map)
    result = runner.result
    show_output(result)
    assert(result.value.valueName == 'Success')
  end

  def test_InjectOsmGeometryIntoAnExternalIdf_e_LinksToSurfaces
    # create an instance of the measure
    measure = InjectOsmGeometryIntoAnExternalIdf.new

    # create an instance of a runner with OSW
    osw_path = OpenStudio::Path.new(File.dirname(__FILE__) + '/measure_test.osw')
    osw = OpenStudio::WorkflowJSON.load(osw_path).get
    runner = OpenStudio::Measure::OSRunner.new(osw)

    # load the test model
    translator = OpenStudio::OSVersion::VersionTranslator.new
    path = OpenStudio::Path.new(File.dirname(__FILE__) + '/B10_Crawlspace_1Story_50_RibbonWindows_altered.osm')
    model = translator.loadModel(path)
    assert(!model.empty?)
    model = model.get

    # forward translate OSM file to IDF file
    ft = OpenStudio::EnergyPlus::ForwardTranslator.new
    workspace = ft.translateModel(model)

    # get arguments and test that they are what we are expecting
    arguments = measure.arguments(workspace)
    argument_map = OpenStudio::Measure::OSArgumentMap.new

    count = -1

    source_idf_path = arguments[count += 1].clone
    assert(source_idf_path.setValue(File.dirname(__FILE__) + '/B10_Crawlspace_1Story_50_RibbonWindows.idf'))
    argument_map['source_idf_path'] = source_idf_path

    merge_geometry_from_osm = arguments[count += 1].clone
    assert(merge_geometry_from_osm.setValue(true))
    argument_map['merge_geometry_from_osm'] = merge_geometry_from_osm

    measure.run(workspace, runner, argument_map)
    result = runner.result
    show_output(result)
    assert(result.value.valueName == 'Success')

    # save the model
    # output_file_path = OpenStudio::Path.new('C:\SVN_Utilities\OpenStudio\measures\test.idf')
    # workspace.save(output_file_path,true) #why isn't this returning the altered model
  end
end
