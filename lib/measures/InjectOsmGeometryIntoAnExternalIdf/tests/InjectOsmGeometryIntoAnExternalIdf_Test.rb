######################################################################
#  Copyright (c) 2008-2013, Alliance for Sustainable Energy.  
#  All rights reserved.
#  
#  This library is free software you can redistribute it and/or
#  modify it under the terms of the GNU Lesser General Public
#  License as published by the Free Software Foundation either
#  version 2.1 of the License, or (at your option) any later version.
#  
#  This library is distributed in the hope that it will be useful,
#  but WITHOUT ANY WARRANTY without even the implied warranty of
#  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
#  Lesser General Public License for more details.
#  
#  You should have received a copy of the GNU Lesser General Public
#  License along with this library if not, write to the Free Software
#  Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301  USA
######################################################################

require 'openstudio'
require 'openstudio/ruleset/ShowRunnerOutput'

require "#{File.dirname(__FILE__)}/../measure.rb"

require 'minitest/autorun'

class InjectOsmGeometryIntoAnExternalIdf_Test < MiniTest::Unit::TestCase

  def test_InjectOsmGeometryIntoAnExternalIdf_a

    # create an instance of the measure
    measure = InjectOsmGeometryIntoAnExternalIdf.new

    # create an instance of a runner with OSW
    osw_path = OpenStudio::Path.new(File.dirname(__FILE__) + "/test.osw")
    osw = OpenStudio::WorkflowJSON.load(osw_path).get
    runner = OpenStudio::Ruleset::OSRunner.new(osw)

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
    osw_path = OpenStudio::Path.new(File.dirname(__FILE__) + "/test.osw")
    osw = OpenStudio::WorkflowJSON.load(osw_path).get
    runner = OpenStudio::Ruleset::OSRunner.new(osw)

    # load the test model
    translator = OpenStudio::OSVersion::VersionTranslator.new
    path = OpenStudio::Path.new(File.dirname(__FILE__) + "/RefBldgMediumOfficeNew2004_Chicago_AlteredGeo_b.osm")
    model = translator.loadModel(path)
    assert((not model.empty?))
    model = model.get

    # forward translate OSM file to IDF file
    ft = OpenStudio::EnergyPlus::ForwardTranslator.new
    workspace = ft.translateModel(model)

    # get arguments and test that they are what we are expecting
    arguments = measure.arguments(workspace)
    argument_map = OpenStudio::Ruleset::OSArgumentMap.new

    count = -1

    source_idf_path = arguments[count += 1].clone
    assert(source_idf_path.setValue(File.dirname(__FILE__) + "/RefBldgMediumOfficeNew2004_Chicago.idf"))
    argument_map["source_idf_path"] = source_idf_path

    merge_geometry_from_osm = arguments[count += 1].clone
    assert(merge_geometry_from_osm.setValue(true))
    argument_map["merge_geometry_from_osm"] = merge_geometry_from_osm

    measure.run(workspace, runner, argument_map)
    result = runner.result
    show_output(result)
    assert(result.value.valueName == "Success")

  end

  def test_InjectOsmGeometryIntoAnExternalIdf_c_NoNewGeometry

    # create an instance of the measure
    measure = InjectOsmGeometryIntoAnExternalIdf.new

    # create an instance of a runner with OSW
    osw_path = OpenStudio::Path.new(File.dirname(__FILE__) + "/test.osw")
    osw = OpenStudio::WorkflowJSON.load(osw_path).get
    runner = OpenStudio::Ruleset::OSRunner.new(osw)

    # load the test model
    translator = OpenStudio::OSVersion::VersionTranslator.new
    path = OpenStudio::Path.new(File.dirname(__FILE__) + "/RefBldgMediumOfficeNew2004_Chicago_AlteredGeo_b.osm")
    model = translator.loadModel(path)
    assert((not model.empty?))
    model = model.get

    # forward translate OSM file to IDF file
    ft = OpenStudio::EnergyPlus::ForwardTranslator.new
    workspace = ft.translateModel(model)

    # get arguments and test that they are what we are expecting
    arguments = measure.arguments(workspace)
    argument_map = OpenStudio::Ruleset::OSArgumentMap.new

    count = -1

    source_idf_path = arguments[count += 1].clone
    assert(source_idf_path.setValue(File.dirname(__FILE__) + "/RefBldgMediumOfficeNew2004_Chicago.idf"))
    argument_map["source_idf_path"] = source_idf_path

    merge_geometry_from_osm = arguments[count += 1].clone
    assert(merge_geometry_from_osm.setValue(false))
    argument_map["merge_geometry_from_osm"] = merge_geometry_from_osm

    measure.run(workspace, runner, argument_map)
    result = runner.result
    show_output(result)
    assert(result.value.valueName == "Success")

    #save the model
    #output_file_path = OpenStudio::Path.new('C:\SVN_Utilities\OpenStudio\measures\test_Ref.idf')
    #workspace.save(output_file_path,true) #why isn't this returning the altered model

  end

  def test_InjectOsmGeometryIntoAnExternalIdf_d_Simple

    # create an instance of the measure
    measure = InjectOsmGeometryIntoAnExternalIdf.new

    # create an instance of a runner with OSW
    osw_path = OpenStudio::Path.new(File.dirname(__FILE__) + "/test.osw")
    osw = OpenStudio::WorkflowJSON.load(osw_path).get
    runner = OpenStudio::Ruleset::OSRunner.new(osw)

    # load the test model
    translator = OpenStudio::OSVersion::VersionTranslator.new
    path = OpenStudio::Path.new(File.dirname(__FILE__) + "/4ZoneWithShading_Simple_1_AlteredGeo.osm")
    model = translator.loadModel(path)
    assert((not model.empty?))
    model = model.get

    # forward translate OSM file to IDF file
    ft = OpenStudio::EnergyPlus::ForwardTranslator.new
    workspace = ft.translateModel(model)

    # get arguments and test that they are what we are expecting
    arguments = measure.arguments(workspace)
    argument_map = OpenStudio::Ruleset::OSArgumentMap.new

    count = -1

    source_idf_path = arguments[count += 1].clone
    assert(source_idf_path.setValue(File.dirname(__FILE__) + "/4ZoneWithShading_Simple_1.idf"))
    argument_map["source_idf_path"] = source_idf_path

    merge_geometry_from_osm = arguments[count += 1].clone
    assert(merge_geometry_from_osm.setValue(true))
    argument_map["merge_geometry_from_osm"] = merge_geometry_from_osm

    measure.run(workspace, runner, argument_map)
    result = runner.result
    show_output(result)
    assert(result.value.valueName == "Success")

  end

  def test_InjectOsmGeometryIntoAnExternalIdf_e_LinksToSurfaces

    # create an instance of the measure
    measure = InjectOsmGeometryIntoAnExternalIdf.new

    # create an instance of a runner with OSW
    osw_path = OpenStudio::Path.new(File.dirname(__FILE__) + "/test.osw")
    osw = OpenStudio::WorkflowJSON.load(osw_path).get
    runner = OpenStudio::Ruleset::OSRunner.new(osw)

    # load the test model
    translator = OpenStudio::OSVersion::VersionTranslator.new
    path = OpenStudio::Path.new(File.dirname(__FILE__) + "/B10_Crawlspace_1Story_50_RibbonWindows_altered.osm")
    model = translator.loadModel(path)
    assert((not model.empty?))
    model = model.get

    # forward translate OSM file to IDF file
    ft = OpenStudio::EnergyPlus::ForwardTranslator.new
    workspace = ft.translateModel(model)

    # get arguments and test that they are what we are expecting
    arguments = measure.arguments(workspace)
    argument_map = OpenStudio::Ruleset::OSArgumentMap.new

    count = -1

    source_idf_path = arguments[count += 1].clone
    assert(source_idf_path.setValue(File.dirname(__FILE__) + "/B10_Crawlspace_1Story_50_RibbonWindows.idf"))
    argument_map["source_idf_path"] = source_idf_path

    merge_geometry_from_osm = arguments[count += 1].clone
    assert(merge_geometry_from_osm.setValue(true))
    argument_map["merge_geometry_from_osm"] = merge_geometry_from_osm

    measure.run(workspace, runner, argument_map)
    result = runner.result
    show_output(result)
    assert(result.value.valueName == "Success")

    #save the model
    #output_file_path = OpenStudio::Path.new('C:\SVN_Utilities\OpenStudio\measures\test.idf')
    #workspace.save(output_file_path,true) #why isn't this returning the altered model

  end

end