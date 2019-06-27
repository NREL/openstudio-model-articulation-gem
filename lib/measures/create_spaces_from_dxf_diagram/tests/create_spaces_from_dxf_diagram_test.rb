# *******************************************************************************
# OpenStudio(R), Copyright (c) 2008-2019, Alliance for Sustainable Energy, LLC.
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
require 'openstudio/ruleset/ShowRunnerOutput'
require 'minitest/autorun'

require_relative '../measure.rb'

require 'fileutils'

class CreateSpacesFromDXFDiagramTest < MiniTest::Unit::TestCase
  def test_acad360
    # create an instance of the measure
    measure = CreateSpacesFromDXFDiagram.new

    # create an instance of a runner
    runner = OpenStudio::Ruleset::OSRunner.new

    # make an empty model
    model = OpenStudio::Model::Model.new

    # check that there are no spaces
    assert_equal(0, model.getSpaces.size)

    # get arguments
    arguments = measure.arguments(model)
    argument_map = OpenStudio::Ruleset.convertOSArgumentVectorToMap(arguments)

    # set argument values to good values
    dxf_path = arguments[0].clone
    assert(dxf_path.setValue(File.dirname(__FILE__) + '/autocad360_polygon_cw.dxf'))
    argument_map['dxf_path'] = dxf_path

    floor_to_floor_height = arguments[1].clone
    assert(floor_to_floor_height.setValue(10.0))
    argument_map['floor_to_floor_height'] = floor_to_floor_height

    num_floors = arguments[2].clone
    assert(num_floors.setValue(3))
    argument_map['num_floors'] = num_floors

    base_height = arguments[3].clone
    assert(base_height.setValue(20))
    argument_map['base_height'] = base_height

    # run the measure
    measure.run(model, runner, argument_map)
    result = runner.result
    show_output(result)
    assert_equal('Success', result.value.valueName)

    # save the model
    # output_file_path = OpenStudio::Path.new(File.dirname(__FILE__) + "output/test_acad360.osm")
    # model.save(output_file_path,true)
  end

  def test_inkscape
    # create an instance of the measure
    measure = CreateSpacesFromDXFDiagram.new

    # create an instance of a runner
    runner = OpenStudio::Ruleset::OSRunner.new

    # make an empty model
    model = OpenStudio::Model::Model.new

    # check that there are no spaces
    assert_equal(0, model.getSpaces.size)

    # get arguments
    arguments = measure.arguments(model)
    argument_map = OpenStudio::Ruleset.convertOSArgumentVectorToMap(arguments)

    # set argument values to good values
    dxf_path = arguments[0].clone
    # assert(dxf_path.setValue(File.dirname(__FILE__) + "/inkscape_test.dxf"))
    # assert(dxf_path.setValue(File.dirname(__FILE__) + "/inkscape_test2a.dxf"))
    # assert(dxf_path.setValue(File.dirname(__FILE__) + "/inkscape_test2b.dxf"))
    assert(dxf_path.setValue(File.dirname(__FILE__) + '/inkscape_test3.dxf'))
    argument_map['dxf_path'] = dxf_path

    floor_to_floor_height = arguments[1].clone
    assert(floor_to_floor_height.setValue(10.0))
    argument_map['floor_to_floor_height'] = floor_to_floor_height

    num_floors = arguments[2].clone
    assert(num_floors.setValue(3))
    argument_map['num_floors'] = num_floors

    base_height = arguments[3].clone
    assert(base_height.setValue(20))
    argument_map['base_height'] = base_height

    # run the measure
    measure.run(model, runner, argument_map)
    result = runner.result
    show_output(result)
    assert_equal('Success', result.value.valueName)

    # save the model
    output_file_path = OpenStudio::Path.new(File.dirname(__FILE__) + '/output/test_inkscape.osm')
    model.save(output_file_path, true)
  end
end
