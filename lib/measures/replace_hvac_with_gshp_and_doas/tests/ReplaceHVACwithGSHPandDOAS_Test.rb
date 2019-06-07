require 'openstudio'

require 'openstudio/ruleset/ShowRunnerOutput'

require "#{File.dirname(__FILE__)}/../measure.rb"

require 'test/unit'

class ReplaceHVACWithGSHPAndDOAS_Test < Test::Unit::TestCase

  
  def test_yes_plenums_doas_on_classrooms_and_cafeteria
     
    # create an instance of the measure
    measure = ReplaceHVACWithGSHPAndDOAS.new
    
    # create an instance of a runner
    runner = OpenStudio::Ruleset::OSRunner.new

    # load the test model
    translator = OpenStudio::OSVersion::VersionTranslator.new
    path = OpenStudio::Path.new(File.dirname(__FILE__) + "/AEDG_HVAC_GenericTestModel_0225_a.osm")
    model = translator.loadModel(path)
    assert((not model.empty?))
    model = model.get
    
    # get arguments and test that they are what we are expecting
    arguments = measure.arguments(model)
    assert_equal(25, arguments.size)
       
    # set argument values to good values and run the measure on model with spaces
    argument_map = OpenStudio::Ruleset::OSArgumentMap.new

    count = -1        
    
    ceiling_return_plenum_space_type = arguments[count += 1].clone
    assert(ceiling_return_plenum_space_type.setValue("Plenum"))
    argument_map["ceiling_return_plenum_space_type"] = ceiling_return_plenum_space_type
    
    # ASHRAE 189.1-2009 ClimateZone 4-8 SecondarySchool Classroom
    space_type = arguments[count += 1].clone
    assert(space_type.setValue(true))
    argument_map["ASHRAE 189.1-2009 ClimateZone 4-8 SecondarySchool Classroom"] = space_type
    
    # ASHRAE 90.1-2004 SecondarySchool Cafeteria
    space_type = arguments[count += 1].clone
    assert(space_type.setValue(true))
    argument_map["ASHRAE 90.1-2004 SecondarySchool Cafeteria"] = space_type
    
    # ASHRAE 90.1-2004 SecondarySchool Gym
    space_type = arguments[count += 1].clone
    assert(space_type.setValue(false))
    argument_map["ASHRAE 90.1-2004 SecondarySchool Gym"] = space_type
    
    # ASHRAE 90.1-2004 SecondarySchool Office
    space_type = arguments[count += 1].clone
    assert(space_type.setValue(false))
    argument_map["ASHRAE 90.1-2004 SecondarySchool Office"] = space_type

    # Plenum
    space_type = arguments[count += 1].clone
    assert(space_type.setValue(false))
    argument_map["Plenum"] = space_type
     
    gshp_htg_cop = arguments[count += 1].clone
    assert(gshp_htg_cop.setValue(4.5))
    argument_map["gshp_htg_cop"] = gshp_htg_cop  

    gshp_clg_eer = arguments[count += 1].clone
    assert(gshp_clg_eer.setValue(15.0))
    argument_map["gshp_clg_eer"] = gshp_clg_eer  

    gshp_fan_type = arguments[count += 1].clone
    assert(gshp_fan_type.setValue("ECM"))
    argument_map["gshp_fan_type"] = gshp_fan_type  

    bore_hole_no = arguments[count += 1].clone
    assert(bore_hole_no.setValue(160))
    argument_map["bore_hole_no"] = bore_hole_no  

    bore_hole_length = arguments[count += 1].clone
    assert(bore_hole_length.setValue(150))
    argument_map["bore_hole_length"] = bore_hole_length  

    bore_hole_radius = arguments[count += 1].clone
    assert(bore_hole_radius.setValue(7))
    argument_map["bore_hole_radius"] = bore_hole_radius  

    ground_k_value = arguments[count += 1].clone
    assert(ground_k_value.setValue(0.70))
    argument_map["ground_k_value"] = ground_k_value  

    grout_k_value = arguments[count += 1].clone
    assert(grout_k_value.setValue(0.80))
    argument_map["grout_k_value"] = grout_k_value  

    supplemental_boiler = arguments[count += 1].clone
    assert(supplemental_boiler.setValue("Yes"))
    argument_map["supplemental_boiler"] = supplemental_boiler  

    boiler_cap = arguments[count += 1].clone
    assert(boiler_cap.setValue(600))
    argument_map["boiler_cap"] = boiler_cap  

    boiler_eff = arguments[count += 1].clone
    assert(boiler_eff.setValue(0.85))
    argument_map["boiler_eff"] = boiler_eff     
    
    boiler_fuel_type = arguments[count += 1].clone
    assert(boiler_fuel_type.setValue("Electricity"))
    argument_map["boiler_fuel_type"] = boiler_fuel_type      

    boiler_hw_st = arguments[count += 1].clone
    assert(boiler_hw_st.setValue(125))
    argument_map["boiler_hw_st"] = boiler_hw_st 
    
    doas_fan_type = arguments[count += 1].clone
    assert(doas_fan_type.setValue("Constant"))
    argument_map["doas_fan_type"] = doas_fan_type 

    doas_erv = arguments[count += 1].clone
    assert(doas_erv.setValue("rotary wheel w/ economizer lockout"))
    argument_map["doas_erv"] = doas_erv 

    doas_evap = arguments[count += 1].clone
    assert(doas_evap.setValue("Direct Evaporative Cooler"))
    argument_map["doas_evap"] = doas_evap 

    doas_dx_eer = arguments[count += 1].clone
    assert(doas_dx_eer.setValue(11.0))
    argument_map["doas_dx_eer"] = doas_dx_eer 
    
    cost_total_hvac_system = arguments[count += 1].clone
    assert(cost_total_hvac_system.setValue(15000.0))
    argument_map["cost_total_hvac_system"] = cost_total_hvac_system

    remake_schedules = arguments[count += 1].clone
    assert(remake_schedules.setValue(true))
    argument_map["remake_schedules"] = remake_schedules

    # Run the measure
    measure.run(model, runner, argument_map)
    result = runner.result
    show_output(result)
    assert(result.value.valueName == "Success")

    # Save the model for testing purposes
    output_file_path = OpenStudio::Path.new(File.dirname(__FILE__) + "/test_yes_plenums_doas_on_classrooms_and_cafeteria.osm")
    model.save(output_file_path,true)
    
    # Each thermal zone that contains a space of space types
    # ASHRAE 189.1-2009 ClimateZone 4-8 SecondarySchool Classroom or
    # ASHRAE 90.1-2004 SecondarySchool Cafeteria
    # should be connected to an airloop and contain 
    # All other thermal zones should not be connected to an airloop.
    model.getThermalZones.each do |zone|
      zone.spaces.each do |space|
        space_type = space.spaceType
        if space_type.is_initialized
          space_type = space_type.get
          if space_type.name.get == "ASHRAE 189.1-2009 ClimateZone 4-8 SecondarySchool Classroom" || space_type.name.get == "ASHRAE 90.1-2004 SecondarySchool Cafeteria"
            assert(zone.airLoopHVAC.is_initialized)
            assert_equal(zone.equipment.size, 2)
            assert(zone.equipment[0].to_AirTerminalSingleDuctUncontrolled.is_initialized)
            assert(zone.equipment[1].to_ZoneHVACWaterToAirHeatPump.is_initialized)
          else
            assert(zone.airLoopHVAC.empty?)
            assert_equal(zone.equipment.size, 0)
          end
        end
      end
    end
 
  end  

end
