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
require 'minitest/autorun'
require_relative '../measure.rb'
require 'fileutils'

class CreateBarFromBuildingTypeRatios_Test < Minitest::Test
  # method to apply arguments, run measure, and assert results (only populate args hash with non-default argument values)
  def apply_measure_to_model(test_name, args, model_name = nil, result_value = 'Success', warnings_count = 0, info_count = nil)
    # create an instance of the measure
    measure = CreateBarFromBuildingTypeRatios.new

    # create an instance of a runner
    runner = OpenStudio::Measure::OSRunner.new(OpenStudio::WorkflowJSON.new)

    if model_name.nil?
      # make an empty model
      model = OpenStudio::Model::Model.new
    else
      # load the test model
      translator = OpenStudio::OSVersion::VersionTranslator.new
      path = OpenStudio::Path.new(File.dirname(__FILE__) + '/' + model_name)
      model = translator.loadModel(path)
      assert(!model.empty?)
      model = model.get
    end

    # get arguments
    arguments = measure.arguments(model)
    argument_map = OpenStudio::Measure.convertOSArgumentVectorToMap(arguments)

    # populate argument with specified hash value if specified
    arguments.each do |arg|
      temp_arg_var = arg.clone
      if args.key?(arg.name)
        assert(temp_arg_var.setValue(args[arg.name]), "could not set #{arg.name} to #{args[arg.name]}.")
      end
      argument_map[arg.name] = temp_arg_var
    end

    # run the measure
    measure.run(model, runner, argument_map)
    result = runner.result

    # show the output
    puts "measure results for #{test_name}"
    show_output(result)

    # save the model to test output directory
    output_file_path = OpenStudio::Path.new(File.dirname(__FILE__) + "/output/#{test_name}_test_output.osm")
    model.save(output_file_path, true)

    # assert that it ran correctly
    if result_value.nil? then result_value = 'Success' end
    assert_equal(result_value, result.value.valueName)

    # check count of warning and info messages
    unless info_count.nil? then assert(result.info.size == info_count) end
    unless warnings_count.nil? then assert(result.warnings.size == warnings_count, "warning count (#{result.warnings.size}) did not match expectation (#{warnings_count})") end

    # if 'Fail' passed in make sure at least one error message (while not typical there may be more than one message)
    if result_value == 'Fail' then assert(result.errors.size >= 1) end
  end

  def test_good_argument_values
    args = {}
    args['total_bldg_floor_area'] = 10000.0

    apply_measure_to_model(__method__.to_s.gsub('test_', ''), args, 'example_model.osm')
  end

  def test_no_multiplier
    args = {}
    args['total_bldg_floor_area'] = 50000.0
    args['num_stories_above_grade'] = 5
    args['story_multiplier'] = 'None'

    apply_measure_to_model(__method__.to_s.gsub('test_', ''), args, 'example_model.osm')
  end

  def test_smart_defaults
    args = {}
    args['total_bldg_floor_area'] = 10000.0
    args['ns_to_ew_ratio'] = 0.0
    args['floor_height'] = 0.0
    args['wwr'] = 0.0

    apply_measure_to_model(__method__.to_s.gsub('test_', ''), args)
  end

  def test_bad_fraction
    args = {}
    args['total_bldg_floor_area'] = 10000.0
    args['bldg_type_b_fract_bldg_area'] = 2.0

    apply_measure_to_model(__method__.to_s.gsub('test_', ''), args, nil, 'Fail')
  end

  def test_bad_positive
    args = {}
    args['total_bldg_floor_area'] = 10000.0
    args['num_stories_above_grade'] = -2

    apply_measure_to_model(__method__.to_s.gsub('test_', ''), args, nil, 'Fail')
  end

  def test_bad_non_neg
    args = {}
    args['total_bldg_floor_area'] = 10000.0
    args['floor_height'] = -1.0

    apply_measure_to_model(__method__.to_s.gsub('test_', ''), args, nil, 'Fail')
  end

  def test_bad_building_type_fractions
    args = {}
    args['total_bldg_floor_area'] = 10000.0
    args['bldg_type_b_fract_bldg_area'] = 0.4
    args['bldg_type_c_fract_bldg_area'] = 0.4
    args['bldg_type_d_fract_bldg_area'] = 0.4
    # using defaults values from measure.rb for other arguments

    apply_measure_to_model(__method__.to_s.gsub('test_', ''), args, nil, 'Fail')
  end

  def test_non_zero_rotation_primary_school
    args = {}
    args['total_bldg_floor_area'] = 100000.0
    args['num_stories_above_grade'] = 3
    args['bldg_type_a'] = 'PrimarySchool'
    args['building_rotation'] = -90
    args['party_wall_stories_east'] = 2
    args['double_loaded_corridor'] = 'Primary Space Type'
    args['make_mid_story_surfaces_adiabatic'] = false
    args['bar_division_method'] = 'Multiple Space Types - Individual Stories Sliced'
    # intersection errors only on this test
    # add diagnostic_intersect flag to use more detailed but slower intersection
    # Initial area of surface 'Surface 66' 57.6057 does not equal post intersection area 115.211
    # Initial area of other surface 'Surface 365' 535.72 does not equal post intersection area 593.326
    # should still fail with check of ground exposed floor or outdoor exposed roof

    apply_measure_to_model(__method__.to_s.gsub('test_', ''), args, nil, nil, 1)
  end

  def test_non_zero_rotation_primary_school_adiabatic # to test intersection of just walls but not floors
    args = {}
    args['total_bldg_floor_area'] = 100000.0
    args['num_stories_above_grade'] = 3
    args['bldg_type_a'] = 'PrimarySchool'
    args['building_rotation'] = -90
    args['party_wall_stories_east'] = 2
    args['double_loaded_corridor'] = 'Primary Space Type'
    args['make_mid_story_surfaces_adiabatic'] = true
    args['bar_division_method'] = 'Multiple Space Types - Individual Stories Sliced'

    apply_measure_to_model(__method__.to_s.gsub('test_', ''), args, nil, nil, 1)
  end

  def test_large_hotel_restaurant
    args = {}
    args['total_bldg_floor_area'] = 100000.0
    args['num_stories_above_grade'] = 3
    args['bldg_type_a'] = 'LargeHotel'
    args['bldg_type_b'] = 'FullServiceRestaurant'
    args['bldg_type_b_fract_bldg_area'] = 0.1
    # args['space_type_sort_logic'] = "Building Type > Size"

    apply_measure_to_model(__method__.to_s.gsub('test_', ''), args)
  end

  def test_large_hotel_restaurant_multiplier
    args = {}
    args['total_bldg_floor_area'] = 100000.0
    args['num_stories_above_grade'] = 8
    args['bldg_type_a'] = 'LargeHotel'
    args['bldg_type_b'] = 'FullServiceRestaurant'
    args['bldg_type_b_fract_bldg_area'] = 0.1

    apply_measure_to_model(__method__.to_s.gsub('test_', ''), args)
  end

  def test_large_hotel_restaurant_multiplier_simple_slice
    args = {}
    args['total_bldg_floor_area'] = 100000.0
    args['num_stories_above_grade'] = 8
    args['bldg_type_a'] = 'LargeHotel'
    args['bldg_type_b'] = 'FullServiceRestaurant'
    args['bldg_type_b_fract_bldg_area'] = 0.1
    args['bar_division_method'] = 'Multiple Space Types - Simple Sliced'

    apply_measure_to_model(__method__.to_s.gsub('test_', ''), args)
  end

  def test_large_hotel_restaurant_multiplier_party_wall
    args = {}
    args['total_bldg_floor_area'] = 100000.0
    args['num_stories_above_grade'] = 8
    args['bldg_type_a'] = 'LargeHotel'
    args['bldg_type_b'] = 'FullServiceRestaurant'
    args['bldg_type_b_fract_bldg_area'] = 0.1
    args['party_wall_fraction'] = 0.25
    args['ns_to_ew_ratio'] = 2.15

    apply_measure_to_model(__method__.to_s.gsub('test_', ''), args)
  end

  def test_large_hotel_restaurant_multiplier_party_big
    args = {}
    args['total_bldg_floor_area'] = 100000.0
    args['num_stories_below_grade'] = 1
    args['num_stories_above_grade'] = 11
    args['bldg_type_a'] = 'LargeHotel'
    args['bldg_type_b'] = 'FullServiceRestaurant'
    args['bldg_type_b_fract_bldg_area'] = 0.1
    args['party_wall_fraction'] = 0.5
    args['ns_to_ew_ratio'] = 2.15

    apply_measure_to_model(__method__.to_s.gsub('test_', ''), args)
  end

  def test_two_and_half_stories
    skip # intersect issue

    args = {}
    args['total_bldg_floor_area'] = 50000.0
    args['bldg_type_a'] = 'SmallOffice'
    args['num_stories_above_grade'] = 5.5
    args['bar_division_method'] = 'Single Space Type - Core and Perimeter'

    apply_measure_to_model(__method__.to_s.gsub('test_', ''), args)
  end

  def test_two_and_half_stories_simple_sliced
    args = {}
    args['total_bldg_floor_area'] = 40000.0
    args['bldg_type_a'] = 'MidriseApartment'
    args['num_stories_above_grade'] = 5.5
    args['bar_division_method'] = 'Multiple Space Types - Simple Sliced'

    # 1 warning because to small for core and perimeter zoning
    apply_measure_to_model(__method__.to_s.gsub('test_', ''), args, nil, nil, 1)
  end

  def test_two_and_half_stories_individual_sliced
    args = {}
    args['total_bldg_floor_area'] = 40000.0
    args['bldg_type_a'] = 'LargeHotel'
    args['num_stories_above_grade'] = 5.5
    args['bar_division_method'] = 'Multiple Space Types - Individual Stories Sliced'

    # 1 warning because to small for core and perimeter zoning
    apply_measure_to_model(__method__.to_s.gsub('test_', ''), args, nil, nil, 1)
  end

  def test_party_wall_stories_test_a
    args = {}
    args['total_bldg_floor_area'] = 40000.0
    args['bldg_type_a'] = 'MediumOffice'
    args['num_stories_below_grade'] = 1
    args['num_stories_above_grade'] = 6
    args['bar_division_method'] = 'Single Space Type - Core and Perimeter'
    args['party_wall_stories_north'] = 4
    args['party_wall_stories_south'] = 6

    apply_measure_to_model(__method__.to_s.gsub('test_', ''), args)
  end

  # this test is failing intermittently due to unexpected warning
  # Office WholeBuilding - Md Office doesn't have the expected floor area (actual 41,419 ft^2, target 40,000 ft^2) 40,709, 40,000
  # footprint size is always fine, intersect is probably creating issue with extra surfaces on top of each other adding the extra area
  # haven't seen this on other partial story models
  #   Error:  Surface 138
  #   This planar surface shares the same SketchUp face as Surface 143.
  #       This error cannot be automatically fixed.  The surface will not be drawn.
  #
  #       Error:  Surface 91
  #   This planar surface shares the same SketchUp face as Surface 141.
  #       This error cannot be automatically fixed.  The surface will not be drawn.
  #
  #       Error:  Surface 125
  #   This planar surface shares the same SketchUp face as Surface 143.
  #       This error cannot be automatically fixed.  The surface will not be drawn.
  def test_mid_story_model
    skip 'For some reason this specific test locks up testing framework but passes in raw ruby test.'

    args = {}
    args['total_bldg_floor_area'] = 40000.0
    args['bldg_type_a'] = 'MediumOffice'
    args['num_stories_above_grade'] = 4.5
    args['bar_division_method'] = 'Single Space Type - Core and Perimeter'
    args['bottom_story_ground_exposed_floor'] = false
    args['top_story_exterior_exposed_roof'] = false

    apply_measure_to_model(__method__.to_s.gsub('test_', ''), args)
  end

  def test_mid_story_model_no_intersect
    args = {}
    args['total_bldg_floor_area'] = 40000.0
    args['bldg_type_a'] = 'MediumOffice'
    args['num_stories_above_grade'] = 4.5
    args['bar_division_method'] = 'Single Space Type - Core and Perimeter'
    args['bottom_story_ground_exposed_floor'] = false
    args['top_story_exterior_exposed_roof'] = false
    args['make_mid_story_surfaces_adiabatic'] = true

    apply_measure_to_model(__method__.to_s.gsub('test_', ''), args)
  end

  def test_same_bar_both_ends
    args = {}
    args['bldg_type_a'] = 'PrimarySchool'
    args['total_bldg_floor_area'] = 10000.0
    args['ns_to_ew_ratio'] = 1.5
    args['num_stories_above_grade'] = 2
    # args["bar_division_method"] = 'Multiple Space Types - Simple Sliced'

    apply_measure_to_model(__method__.to_s.gsub('test_', ''), args, nil, nil, 8)
  end

  def test_rotation_45_party_wall_fraction
    skip # intersect issue

    args = {}
    args['total_bldg_floor_area'] = 100000.0
    args['num_stories_below_grade'] = 1
    args['num_stories_above_grade'] = 3.5
    args['bldg_type_a'] = 'SecondarySchool'
    args['building_rotation'] = 45.0
    args['party_wall_fraction'] = 0.65
    args['ns_to_ew_ratio'] = 3.0
    args['bar_division_method'] = 'Single Space Type - Core and Perimeter'
    args['custom_height_bar'] = false

    # 11 warning messages because using single space type division method with multi-space type building type
    apply_measure_to_model(__method__.to_s.gsub('test_', ''), args, nil, nil, 13)
  end

  def test_fixed_single_floor_area
    args = {}
    args['total_bldg_floor_area'] = 100000.0
    args['single_floor_area'] = 2000.0
    args['ns_to_ew_ratio'] = 1.5
    args['num_stories_above_grade'] = 5.0

    apply_measure_to_model(__method__.to_s.gsub('test_', ''), args, nil, nil, nil)
  end

  def test_warehouse
    args = {}
    args['total_bldg_floor_area'] = 100000.0
    args['bldg_type_a'] = 'Warehouse'
    # args['custom_height_bar'] = false

    apply_measure_to_model(__method__.to_s.gsub('test_', ''), args, nil, nil, nil)
  end

  # DEER prototypes
  def test_asm
    args = {}
    args['template'] = 'DEER Pre-1975'
    args['total_bldg_floor_area'] = 34003
    args['bldg_type_a'] = 'Asm'
    args['num_stories_above_grade'] = 1
    args['bar_division_method'] = 'Multiple Space Types - Simple Sliced'

    apply_measure_to_model(__method__.to_s.gsub('test_', ''), args, nil, nil, nil)
  end

  def test_ecc
    args = {}
    args['template'] = 'DEER Pre-1975'
    args['total_bldg_floor_area'] = 150078
    args['bldg_type_a'] = 'ECC'
    args['num_stories_above_grade'] = 5
    args['bar_division_method'] = 'Multiple Space Types - Simple Sliced'

    apply_measure_to_model(__method__.to_s.gsub('test_', ''), args, nil, nil, nil)
  end

  def test_epr
    args = {}
    args['template'] = 'DEER Pre-1975'
    args['total_bldg_floor_area'] = 24998
    args['bldg_type_a'] = 'EPr'
    args['num_stories_above_grade'] = 2
    args['bar_division_method'] = 'Multiple Space Types - Simple Sliced'

    apply_measure_to_model(__method__.to_s.gsub('test_', ''), args, nil, nil, nil)
  end

  def test_erc
    args = {}
    args['template'] = 'DEER Pre-1975'
    args['total_bldg_floor_area'] = 1922
    args['bldg_type_a'] = 'ERC'
    args['num_stories_above_grade'] = 1
    args['bar_division_method'] = 'Multiple Space Types - Simple Sliced'

    apply_measure_to_model(__method__.to_s.gsub('test_', ''), args, nil, nil, nil)
  end

  def test_ese
    args = {}
    args['template'] = 'DEER Pre-1975'
    args['total_bldg_floor_area'] = 54455
    args['bldg_type_a'] = 'ESe'
    args['num_stories_above_grade'] = 5
    args['bar_division_method'] = 'Multiple Space Types - Simple Sliced'

    apply_measure_to_model(__method__.to_s.gsub('test_', ''), args, nil, nil, nil)
  end

  def test_eun
    args = {}
    args['template'] = 'DEER Pre-1975'
    args['total_bldg_floor_area'] = 499872
    args['bldg_type_a'] = 'EUn'
    args['num_stories_above_grade'] = 9
    args['bar_division_method'] = 'Multiple Space Types - Simple Sliced'

    apply_measure_to_model(__method__.to_s.gsub('test_', ''), args, nil, nil, nil)
  end

  def test_gro
    args = {}
    args['template'] = 'DEER Pre-1975'
    args['total_bldg_floor_area'] = 49997
    args['bldg_type_a'] = 'Gro'
    args['num_stories_above_grade'] = 1
    args['bar_division_method'] = 'Multiple Space Types - Simple Sliced'

    apply_measure_to_model(__method__.to_s.gsub('test_', ''), args, nil, nil, nil)
  end

  def test_hsp
    args = {}
    args['template'] = 'DEER Pre-1975'
    args['total_bldg_floor_area'] = 249985
    args['bldg_type_a'] = 'Hsp'
    args['num_stories_above_grade'] = 4
    args['bar_division_method'] = 'Multiple Space Types - Simple Sliced'

    apply_measure_to_model(__method__.to_s.gsub('test_', ''), args, nil, nil, nil)
  end

  def test_htl
    args = {}
    args['template'] = 'DEER Pre-1975'
    args['total_bldg_floor_area'] = 200081
    args['bldg_type_a'] = 'Htl'
    args['num_stories_above_grade'] = 6
    args['bar_division_method'] = 'Multiple Space Types - Simple Sliced'

    apply_measure_to_model(__method__.to_s.gsub('test_', ''), args, nil, nil, nil)
  end

  def test_dual_bar_1
    args = {}
    args['total_bldg_floor_area'] = 100000.0
    args['bldg_type_a'] = 'SecondarySchool'
    args['num_stories_above_grade'] = 2
    args['bar_division_method'] = 'Multiple Space Types - Individual Stories Sliced'
    args['ns_to_ew_ratio'] = 3.0
    args['perim_mult'] = 1.0
    args['custom_height_bar'] = false

    apply_measure_to_model(__method__.to_s.gsub('test_', ''), args, nil, nil, nil)
  end

  def test_dual_bar_smart
    args = {}
    args['total_bldg_floor_area'] = 210887.0
    args['bldg_type_a'] = 'SecondarySchool'
    args['num_stories_above_grade'] = 2
    args['bar_division_method'] = 'Multiple Space Types - Individual Stories Sliced'
    args['ns_to_ew_ratio'] = 0
    args['perim_mult'] = 0
    args['custom_height_bar'] = true
    args['bar_sep_dist_mult'] = 3
    # Making the mid story surfaces adiabatic fixes the failure on Linux. Note though, that this is just
    # a hack and by setting this false should expose the surface matching issue that needs to get addressed.
    args['make_mid_story_surfaces_adiabatic'] = true

    apply_measure_to_model(__method__.to_s.gsub('test_', ''), args, nil, nil, nil)
  end

  def test_mbt
    args = {}
    args['template'] = 'DEER Pre-1975'
    args['total_bldg_floor_area'] = 199975
    args['bldg_type_a'] = 'MBT'
    args['num_stories_above_grade'] = 1
    args['bar_division_method'] = 'Multiple Space Types - Simple Sliced'

    apply_measure_to_model(__method__.to_s.gsub('test_', ''), args, nil, nil, nil)
  end

  def test_mfm
    args = {}
    args['template'] = 'DEER Pre-1975'
    args['total_bldg_floor_area'] = 21727
    args['bldg_type_a'] = 'MFm'
    args['num_stories_above_grade'] = 2
    args['bar_division_method'] = 'Multiple Space Types - Simple Sliced'

    apply_measure_to_model(__method__.to_s.gsub('test_', ''), args, nil, nil, nil)
  end

  def test_mli
    args = {}
    args['template'] = 'DEER Pre-1975'
    args['total_bldg_floor_area'] = 100014
    args['bldg_type_a'] = 'MLI'
    args['num_stories_above_grade'] = 1
    args['bar_division_method'] = 'Multiple Space Types - Simple Sliced'

    apply_measure_to_model(__method__.to_s.gsub('test_', ''), args, nil, nil, nil)
  end

  # TODO: - add in check that won't make second bar unless it is 5' wide
  # puts similar check on non-adiabatic (switch back to adiabatic then?)
  def test_dual_bar_101
    args = {}
    args['total_bldg_floor_area'] = 100000.0
    args['bldg_type_a'] = 'SecondarySchool'
    args['num_stories_above_grade'] = 2
    args['bar_division_method'] = 'Multiple Space Types - Individual Stories Sliced'
    args['ns_to_ew_ratio'] = 3.0
    args['perim_mult'] = 1.01
    args['custom_height_bar'] = false

    apply_measure_to_model(__method__.to_s.gsub('test_', ''), args, nil, nil, nil)
  end

  def test_mtl
    args = {}
    args['template'] = 'DEER Pre-1975'
    args['total_bldg_floor_area'] = 29986
    args['bldg_type_a'] = 'Mtl'
    args['num_stories_above_grade'] = 2
    args['bar_division_method'] = 'Multiple Space Types - Simple Sliced'

    apply_measure_to_model(__method__.to_s.gsub('test_', ''), args, nil, nil, nil)
  end

  def test_nrs
    args = {}
    args['template'] = 'DEER Pre-1975'
    args['total_bldg_floor_area'] = 59981
    args['bldg_type_a'] = 'Nrs'
    args['num_stories_above_grade'] = 4
    args['bar_division_method'] = 'Multiple Space Types - Simple Sliced'

    apply_measure_to_model(__method__.to_s.gsub('test_', ''), args, nil, nil, nil)
  end

  def test_ofl
    args = {}
    args['template'] = 'DEER Pre-1975'
    args['total_bldg_floor_area'] = 174960
    args['bldg_type_a'] = 'OfL'
    args['num_stories_above_grade'] = 3
    args['bar_division_method'] = 'Multiple Space Types - Simple Sliced'

    apply_measure_to_model(__method__.to_s.gsub('test_', ''), args, nil, nil, nil)
  end

  def test_dual_bar_11a
    skip # intersect issue

    args = {}
    args['total_bldg_floor_area'] = 100000.0
    args['bldg_type_a'] = 'SecondarySchool'
    args['num_stories_above_grade'] = 2
    args['bar_division_method'] = 'Multiple Space Types - Individual Stories Sliced'
    args['ns_to_ew_ratio'] = 3.0
    args['perim_mult'] = 1.1
    args['custom_height_bar'] = false

    apply_measure_to_model(__method__.to_s.gsub('test_', ''), args, nil, nil, nil)
  end

  def test_ofs
    args = {}
    args['template'] = 'DEER Pre-1975'
    args['total_bldg_floor_area'] = 10002
    args['bldg_type_a'] = 'OfS'
    args['num_stories_above_grade'] = 2
    args['bar_division_method'] = 'Multiple Space Types - Simple Sliced'

    apply_measure_to_model(__method__.to_s.gsub('test_', ''), args, nil, nil, nil)
  end

  def test_rff
    args = {}
    args['template'] = 'DEER Pre-1975'
    args['total_bldg_floor_area'] = 1998
    args['bldg_type_a'] = 'RFF'
    args['num_stories_above_grade'] = 1
    args['bar_division_method'] = 'Multiple Space Types - Simple Sliced'

    apply_measure_to_model(__method__.to_s.gsub('test_', ''), args, nil, nil, nil)
  end

  def test_dual_bar_11b
    args = {}
    args['total_bldg_floor_area'] = 100000.0
    args['bldg_type_a'] = 'SecondarySchool'
    args['num_stories_above_grade'] = 2
    args['bar_division_method'] = 'Multiple Space Types - Individual Stories Sliced'
    args['ns_to_ew_ratio'] = 1.0
    args['perim_mult'] = 1.1
    args['custom_height_bar'] = false

    apply_measure_to_model(__method__.to_s.gsub('test_', ''), args, nil, nil, nil)
  end

  def test_rsd
    args = {}
    args['template'] = 'DEER Pre-1975'
    args['total_bldg_floor_area'] = 5603
    args['bldg_type_a'] = 'RSD'
    args['num_stories_above_grade'] = 1
    args['bar_division_method'] = 'Multiple Space Types - Simple Sliced'

    apply_measure_to_model(__method__.to_s.gsub('test_', ''), args, nil, nil, nil)
  end

  def test_rt3
    args = {}
    args['template'] = 'DEER Pre-1975'
    args['total_bldg_floor_area'] = 120000
    args['bldg_type_a'] = 'Rt3'
    args['num_stories_above_grade'] = 3
    args['bar_division_method'] = 'Multiple Space Types - Simple Sliced'

    apply_measure_to_model(__method__.to_s.gsub('test_', ''), args, nil, nil, nil)
  end

  def test_rtl
    args = {}
    args['template'] = 'DEER Pre-1975'
    args['total_bldg_floor_area'] = 130502
    args['bldg_type_a'] = 'RtL'
    args['num_stories_above_grade'] = 1
    args['bar_division_method'] = 'Multiple Space Types - Simple Sliced'

    apply_measure_to_model(__method__.to_s.gsub('test_', ''), args, nil, nil, nil)
  end

  def test_dual_bar_15
    skip # intersect issue

    # TODO: - check calcs, error on this seem to almost exactly 1 ft error in where stretched bar is placed
    args = {}
    args['total_bldg_floor_area'] = 100000.0
    args['bldg_type_a'] = 'SecondarySchool'
    args['num_stories_above_grade'] = 2
    args['bar_division_method'] = 'Multiple Space Types - Individual Stories Sliced'
    args['ns_to_ew_ratio'] = 3.0
    args['perim_mult'] = 1.5
    args['custom_height_bar'] = false
    args['double_loaded_corridor'] = 'Primary Space Type'
    args['building_rotation'] = 0
    args['make_mid_story_surfaces_adiabatic'] = false

    apply_measure_to_model(__method__.to_s.gsub('test_', ''), args, nil, nil, nil)
  end

  def test_rts
    args = {}
    args['template'] = 'DEER Pre-1975'
    args['total_bldg_floor_area'] = 8001
    args['bldg_type_a'] = 'RtS'
    args['num_stories_above_grade'] = 1
    args['bar_division_method'] = 'Multiple Space Types - Simple Sliced'

    apply_measure_to_model(__method__.to_s.gsub('test_', ''), args, nil, nil, nil)
  end

  def test_dual_bar_15b
    # TODO: - check calcs, error on this seem to almost exactly 1 ft error in where stretched bar is placed
    args = {}
    args['total_bldg_floor_area'] = 100000.0
    args['bldg_type_a'] = 'SecondarySchool'
    args['num_stories_above_grade'] = 2
    args['bar_division_method'] = 'Multiple Space Types - Individual Stories Sliced'
    args['ns_to_ew_ratio'] = 3.0
    args['perim_mult'] = 1.5
    args['building_rotation'] = -90.0

    apply_measure_to_model(__method__.to_s.gsub('test_', ''), args, nil, nil, nil)
  end

  def test_scn
    args = {}
    args['template'] = 'DEER Pre-1975'
    args['total_bldg_floor_area'] = 499991
    args['bldg_type_a'] = 'SCn'
    args['num_stories_above_grade'] = 1
    args['bar_division_method'] = 'Multiple Space Types - Simple Sliced'

    apply_measure_to_model(__method__.to_s.gsub('test_', ''), args, nil, nil, nil)
  end

  def test_dual_bar_3
    args = {}
    args['total_bldg_floor_area'] = 100000.0
    args['bldg_type_a'] = 'SecondarySchool'
    args['num_stories_above_grade'] = 2
    args['bar_division_method'] = 'Multiple Space Types - Individual Stories Sliced'
    args['ns_to_ew_ratio'] = 1.0
    args['perim_mult'] = 3.0

    apply_measure_to_model(__method__.to_s.gsub('test_', ''), args, nil, nil, nil)
  end

  def test_sun
    args = {}
    args['template'] = 'DEER Pre-1975'
    args['total_bldg_floor_area'] = 499991
    args['bldg_type_a'] = 'SUn'
    args['num_stories_above_grade'] = 1
    args['bar_division_method'] = 'Multiple Space Types - Simple Sliced'

    apply_measure_to_model(__method__.to_s.gsub('test_', ''), args, nil, nil, nil)
  end

  def test_dual_bar_split_low
    args = {}
    args['total_bldg_floor_area'] = 100000.0
    args['bldg_type_a'] = 'SecondarySchool'
    args['num_stories_above_grade'] = 5.2
    args['bar_division_method'] = 'Multiple Space Types - Individual Stories Sliced'
    args['ns_to_ew_ratio'] = 3.0
    args['perim_mult'] = 3.0
    args['custom_height_bar'] = false

    apply_measure_to_model(__method__.to_s.gsub('test_', ''), args, nil, nil, nil)
  end

  def test_wrf
    args = {}
    args['template'] = 'DEER Pre-1975'
    args['total_bldg_floor_area'] = 100000
    args['bldg_type_a'] = 'WRf'
    args['num_stories_above_grade'] = 1
    args['bar_division_method'] = 'Multiple Space Types - Simple Sliced'

    apply_measure_to_model(__method__.to_s.gsub('test_', ''), args, nil, nil, nil)
  end

  def test_dual_bar_split_high
    args = {}
    args['total_bldg_floor_area'] = 100000.0
    args['bldg_type_a'] = 'SecondarySchool'
    args['num_stories_above_grade'] = 5.9
    args['bar_division_method'] = 'Multiple Space Types - Individual Stories Sliced'
    args['ns_to_ew_ratio'] = 3.0
    args['perim_mult'] = 3.0
    args['custom_height_bar'] = false

    apply_measure_to_model(__method__.to_s.gsub('test_', ''), args, nil, nil, nil)
  end

  def test_aspect_ratio_1a
    args = {}
    args['total_bldg_floor_area'] = 100000.0
    args['bldg_type_a'] = 'SecondarySchool'
    args['num_stories_above_grade'] = 6.0
    args['bar_division_method'] = 'Multiple Space Types - Individual Stories Sliced'
    args['ns_to_ew_ratio'] = 1.0
    args['perim_mult'] = 1.0

    apply_measure_to_model(__method__.to_s.gsub('test_', ''), args, nil, nil, nil)
  end

  def test_aspect_ratio_1b
    args = {}
    args['total_bldg_floor_area'] = 100000.0
    args['bldg_type_a'] = 'SecondarySchool'
    args['num_stories_above_grade'] = 6.0
    args['bar_division_method'] = 'Multiple Space Types - Individual Stories Sliced'
    args['ns_to_ew_ratio'] = 1.0
    args['perim_mult'] = 1.5
    args['custom_height_bar'] = false

    apply_measure_to_model(__method__.to_s.gsub('test_', ''), args, nil, nil, nil)
  end

  def test_aspect_ratio_low_a
    args = {}
    args['total_bldg_floor_area'] = 100000.0
    args['bldg_type_a'] = 'SecondarySchool'
    args['num_stories_above_grade'] = 6.0
    args['bar_division_method'] = 'Multiple Space Types - Individual Stories Sliced'
    args['ns_to_ew_ratio'] = 0.2
    args['perim_mult'] = 1.0

    apply_measure_to_model(__method__.to_s.gsub('test_', ''), args, nil, nil, nil)
  end

  def test_aspect_ratio_low_b
    args = {}
    args['total_bldg_floor_area'] = 100000.0
    args['bldg_type_a'] = 'SecondarySchool'
    args['num_stories_above_grade'] = 6.0
    args['bar_division_method'] = 'Multiple Space Types - Individual Stories Sliced'
    args['ns_to_ew_ratio'] = 0.2
    args['perim_mult'] = 1.5
    args['custom_height_bar'] = false

    apply_measure_to_model(__method__.to_s.gsub('test_', ''), args, nil, nil, nil)
  end

  def test_aspect_ratio_low_b2
    args = {}
    args['total_bldg_floor_area'] = 100000.0
    args['bldg_type_a'] = 'SecondarySchool'
    args['num_stories_above_grade'] = 6.0
    args['bar_division_method'] = 'Multiple Space Types - Individual Stories Sliced'
    args['ns_to_ew_ratio'] = 5.0
    args['perim_mult'] = 1.5
    args['building_rotation'] = -90.0

    apply_measure_to_model(__method__.to_s.gsub('test_', ''), args, nil, nil, nil)
  end

  def test_aspect_ratio_low_c
    args = {}
    args['total_bldg_floor_area'] = 100000.0
    args['bldg_type_a'] = 'SecondarySchool'
    args['num_stories_above_grade'] = 6.0
    args['bar_division_method'] = 'Multiple Space Types - Individual Stories Sliced'
    args['ns_to_ew_ratio'] = 0.2
    args['perim_mult'] = 1.1
    args['custom_height_bar'] = false

    apply_measure_to_model(__method__.to_s.gsub('test_', ''), args, nil, nil, nil)
  end

  def test_multi_rot_a
    args = {}
    args['total_bldg_floor_area'] = 100000.0
    args['bldg_type_a'] = 'SecondarySchool'
    args['num_stories_above_grade'] = 5.9
    args['bar_division_method'] = 'Multiple Space Types - Individual Stories Sliced'
    args['ns_to_ew_ratio'] = 2
    args['perim_mult'] = 1.1
    args['custom_height_bar'] = false
    args['double_loaded_corridor'] = 'None'

    apply_measure_to_model(__method__.to_s.gsub('test_', ''), args, nil, nil, nil)
  end

  def test_multi_rot_b
    skip # intersect issue

    args = {}
    args['total_bldg_floor_area'] = 100000.0
    args['bldg_type_a'] = 'SecondarySchool'
    args['num_stories_above_grade'] = 5.9
    args['bar_division_method'] = 'Multiple Space Types - Individual Stories Sliced'
    args['ns_to_ew_ratio'] = 2
    args['perim_mult'] = 1.5

    apply_measure_to_model(__method__.to_s.gsub('test_', ''), args, nil, nil, nil)
  end

  def test_multi_rot_c
    args = {}
    args['total_bldg_floor_area'] = 100000.0
    args['bldg_type_a'] = 'SecondarySchool'
    args['num_stories_above_grade'] = 5.9
    args['bar_division_method'] = 'Multiple Space Types - Individual Stories Sliced'
    args['ns_to_ew_ratio'] = 0.5
    args['perim_mult'] = 1.5
    args['custom_height_bar'] = false

    apply_measure_to_model(__method__.to_s.gsub('test_', ''), args, nil, nil, nil)
  end

  def test_smart_perm_mult_primary
    args = {}
    args['total_bldg_floor_area'] = 73958.0
    args['num_stories_above_grade'] = 1
    args['bldg_type_a'] = 'PrimarySchool'
    args['ns_to_ew_ratio'] = 0.0
    args['perim_mult'] = 0.0

    apply_measure_to_model(__method__.to_s.gsub('test_', ''), args, nil, nil, nil)
  end

  def test_smart_perm_mult_primary_size
    args = {}
    args['total_bldg_floor_area'] = 73958.0
    args['num_stories_above_grade'] = 1
    args['bldg_type_a'] = 'PrimarySchool'
    args['ns_to_ew_ratio'] = 0.0
    args['perim_mult'] = 0.0
    args['space_type_sort_logic'] = 'Size'

    apply_measure_to_model(__method__.to_s.gsub('test_', ''), args, nil, nil, nil)
  end

  def test_smart_perm_mult_secondary
    args = {}
    args['total_bldg_floor_area'] = 210887.0
    args['num_stories_above_grade'] = 2
    args['bldg_type_a'] = 'SecondarySchool'
    args['ns_to_ew_ratio'] = 0.0
    args['perim_mult'] = 0.0
    args['custom_height_bar'] = false
    args['double_loaded_corridor'] = 'None'

    apply_measure_to_model(__method__.to_s.gsub('test_', ''), args)
  end

  def test_smart_perm_mult_outpatient
    args = {}
    args['total_bldg_floor_area'] = 40946.0
    args['num_stories_above_grade'] = 3
    args['bldg_type_a'] = 'Outpatient'
    args['ns_to_ew_ratio'] = 0.0
    args['perim_mult'] = 0.0

    apply_measure_to_model(__method__.to_s.gsub('test_', ''), args, nil, nil, 8)
  end

  def test_smart_perm_mult_sm_off
    args = {}
    args['total_bldg_floor_area'] = 100000.0
    args['num_stories_above_grade'] = 3
    args['bldg_type_a'] = 'SmallOffice'
    args['ns_to_ew_ratio'] = 0.0
    args['perim_mult'] = 0.0

    apply_measure_to_model(__method__.to_s.gsub('test_', ''), args)
  end

  def test_multi_width_a
    args = {}
    args['total_bldg_floor_area'] = 96000.0
    args['num_stories_above_grade'] = 4
    args['bldg_type_a'] = 'MidriseApartment'
    args['ns_to_ew_ratio'] = 1.0
    args['bar_width'] = 60.0
    args['bldg_type_b'] = 'RetailStandalone'
    args['bldg_type_b_fract_bldg_area'] = 0.25
    args['space_type_sort_logic'] = 'Building Type > Size'

    apply_measure_to_model(__method__.to_s.gsub('test_', ''), args, nil, nil, nil)
  end

  def test_multi_width_b
    args = {}
    args['total_bldg_floor_area'] = 96000.0
    args['num_stories_above_grade'] = 4
    args['bldg_type_a'] = 'MidriseApartment'
    args['ns_to_ew_ratio'] = 0.3
    args['bar_width'] = 60.0
    args['bldg_type_b'] = 'RetailStandalone'
    args['bldg_type_b_fract_bldg_area'] = 0.25
    args['space_type_sort_logic'] = 'Building Type > Size'

    apply_measure_to_model(__method__.to_s.gsub('test_', ''), args, nil, nil, nil)
  end

  def test_multi_width_c
    args = {}
    args['total_bldg_floor_area'] = 96000.0
    args['num_stories_above_grade'] = 4
    args['bldg_type_a'] = 'MidriseApartment'
    args['ns_to_ew_ratio'] = 0.25
    args['bar_width'] = 60.0
    args['bldg_type_b'] = 'RetailStandalone'
    args['bldg_type_b_fract_bldg_area'] = 0.25
    args['double_loaded_corridor'] = 'None'

    apply_measure_to_model(__method__.to_s.gsub('test_', ''), args, nil, nil, nil)
  end

  def test_multi_width_d
    args = {}
    args['total_bldg_floor_area'] = 96000.0
    args['num_stories_above_grade'] = 4
    args['bldg_type_a'] = 'MidriseApartment'
    args['ns_to_ew_ratio'] = 2.0
    args['bar_width'] = 60.0
    args['bldg_type_b'] = 'RetailStandalone'
    args['bldg_type_b_fract_bldg_area'] = 0.25

    apply_measure_to_model(__method__.to_s.gsub('test_', ''), args, nil, nil, nil)
  end

  def test_multi_width_e
    args = {}
    args['total_bldg_floor_area'] = 96000.0
    args['num_stories_above_grade'] = 4
    args['bldg_type_a'] = 'MidriseApartment'
    args['ns_to_ew_ratio'] = 10.0
    args['bar_width'] = 60.0
    args['bldg_type_b'] = 'RetailStandalone'
    args['bldg_type_b_fract_bldg_area'] = 0.25
    args['custom_height_bar'] = true

    apply_measure_to_model(__method__.to_s.gsub('test_', ''), args, nil, nil, nil)
  end

  def test_custom_offset
    args = {}
    args['total_bldg_floor_area'] = 100000.0
    args['bldg_type_a'] = 'SecondarySchool'
    args['num_stories_above_grade'] = 4
    args['bar_division_method'] = 'Multiple Space Types - Individual Stories Sliced'
    args['ns_to_ew_ratio'] = 2
    args['perim_mult'] = 1
    args['custom_height_bar'] = true
    args['double_loaded_corridor'] = 'None'
    args['building_rotation'] = 0
    args['make_mid_story_surfaces_adiabatic'] = true
    args['bar_sep_dist_mult'] = 3
    args['story_multiplier'] = 'None'
    args['num_stories_below_grade'] = 0
    args['bar_width'] = 60.0

    apply_measure_to_model(__method__.to_s.gsub('test_', ''), args, nil, nil, nil)
  end

  def test_custom_offset_alt
    args = {}
    args['total_bldg_floor_area'] = 50000.0
    args['bldg_type_a'] = 'SmallHotel'
    args['bldg_type_b'] = 'RetailStandalone'
    args['bldg_type_b_fract_bldg_area'] = 0.25
    args['num_stories_above_grade'] = 4
    args['bar_division_method'] = 'Multiple Space Types - Individual Stories Sliced'
    args['ns_to_ew_ratio'] = 3
    args['perim_mult'] = 1
    args['custom_height_bar'] = true
    args['double_loaded_corridor'] = 'Primary Space Type'
    args['building_rotation'] = 0
    args['make_mid_story_surfaces_adiabatic'] = true
    args['bar_sep_dist_mult'] = 3
    # args['story_multiplier'] = 'None'
    # args['num_stories_below_grade'] = 1
    # args['party_wall_stories_south'] = 1
    # args['party_wall_stories_east'] = 2
    args['space_type_sort_logic'] = 'Size'

    apply_measure_to_model(__method__.to_s.gsub('test_', ''), args, nil, nil, nil)
  end

  def test_custom_offset_alt2
    args = {}
    args['total_bldg_floor_area'] = 50000.0
    args['bldg_type_a'] = 'SmallHotel'
    args['bldg_type_b'] = 'FullServiceRestaurant'
    args['bldg_type_b_fract_bldg_area'] = 0.25
    args['num_stories_above_grade'] = 4
    args['bar_division_method'] = 'Multiple Space Types - Individual Stories Sliced'
    args['ns_to_ew_ratio'] = 3
    args['perim_mult'] = 1
    args['custom_height_bar'] = true
    args['double_loaded_corridor'] = 'Primary Space Type'
    args['building_rotation'] = 0
    args['make_mid_story_surfaces_adiabatic'] = true
    args['bar_sep_dist_mult'] = 3
    # args['story_multiplier'] = 'None'
    # args['num_stories_below_grade'] = 1
    # args['party_wall_stories_south'] = 1
    # args['party_wall_stories_east'] = 2
    args['space_type_sort_logic'] = 'Size'
    # args['story_multiplier'] = "None"

    apply_measure_to_model(__method__.to_s.gsub('test_', ''), args, nil, nil, nil)
  end
end
