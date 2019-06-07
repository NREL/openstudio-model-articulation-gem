#see the URL below for information on how to write OpenStudio measures
# http://openstudio.nrel.gov/openstudio-measure-writing-guide

#see the URL below for information on using life cycle cost objects in OpenStudio
# http://openstudio.nrel.gov/openstudio-life-cycle-examples

#see the URL below for access to C++ documentation on model objects (click on "model" in the main window to view model objects)
# http://openstudio.nrel.gov/sites/openstudio.nrel.gov/files/nv_data/cpp_documentation_it/model/html/namespaces.html

#load OpenStudio measure libraries
#require "#{File.dirname(__FILE__)}/resources/OsLib_AedgMeasures"
require "#{File.dirname(__FILE__)}/resources/OsLib_HelperMethods"
require "#{File.dirname(__FILE__)}/resources/OsLib_HVAC"
require "#{File.dirname(__FILE__)}/resources/OsLib_Schedules"

#start the measure
class ReplaceHVACWithGSHPAndDOAS < OpenStudio::Ruleset::ModelUserScript

  #define the name that a user will see, this method may be deprecated as
  #the display name in PAT comes from the name field in measure.xml
  def name
    return "Replace HVAC with GSHP and DOAS"
  end

  #define the arguments that the user will input
  def arguments(model)
    args = OpenStudio::Ruleset::OSArgumentVector.new

    # Create a list of the names and handles of space types
    # used in the building.
    used_space_type_handles = OpenStudio::StringVector.new
    used_space_type_names = OpenStudio::StringVector.new
    model.getSpaceTypes.sort.each do |space_type|
      if space_type.spaces.size > 0 # only show space types used in the building
        used_space_type_handles << space_type.handle.to_s
        used_space_type_names << space_type.name.to_s
      end
    end
	
    # Make an argument for plenum space type
    ceiling_return_plenum_space_type = OpenStudio::Ruleset::OSArgument::makeChoiceArgument("ceiling_return_plenum_space_type", used_space_type_handles, used_space_type_names,false)
    ceiling_return_plenum_space_type.setDisplayName("This space type should be part of a ceiling return air plenum.")
    args << ceiling_return_plenum_space_type
	
    # Make a bool argument to edit/not edit each space type
		model.getSpaceTypes.sort.each do |space_type|
			if space_type.spaces.size > 0 # only show space types used in the building
				space_type_to_edit = OpenStudio::Ruleset::OSArgument::makeBoolArgument(space_type.name.get.to_s,false)
				# Make a bool argument for this space type
				space_type_to_edit.setDisplayName("Add #{space_type.name.get} space type to GSHP system?")
				space_type_to_edit.setDefaultValue(false)		
				args << space_type_to_edit
			end
		end
	  
		# Heating COP of GSHP
		gshp_htg_cop = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("gshp_htg_cop",false)
		gshp_htg_cop.setDisplayName("GSHP DX Heating Coil Heating COP")
		gshp_htg_cop.setDefaultValue(4.0)
		args << gshp_htg_cop
		
		# Cooling EER of GSHP
		gshp_clg_eer = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("gshp_clg_eer",false)
		gshp_clg_eer.setDisplayName("GSHP DX Cooling Coil Cooling EER")
		gshp_clg_eer.setDefaultValue(14)
		args << gshp_clg_eer
		
		# GSHP Fan Type PSC or ECM
		fan_choices = OpenStudio::StringVector.new
		fan_choices << "PSC"
		fan_choices << "ECM"
		gshp_fan_type =  OpenStudio::Ruleset::OSArgument::makeChoiceArgument("gshp_fan_type",fan_choices,true) # note ECM fan type may correspond to different set of heat pump performance curves
		gshp_fan_type.setDisplayName("GSHP Fan Type: PSC or ECM?")
		gshp_fan_type.setDefaultValue("PSC")
    args << gshp_fan_type
		
		# Condenser Loop Cooling Temperature
		# condLoopCoolingTemp = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("condLoopCoolingTemp",false)
		# condLoopCoolingTemp.setDisplayName("Condenser Loop Cooling Temperature (F)")
		# condLoopCoolingTemp.setDefaultValue(90)
		# args << condLoopCoolingTemp
		
		# Condenser Loop Heating Temperature
		# condLoopHeatingTemp = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("condLoopHeatingTemp",false)
		# condLoopHeatingTemp.setDisplayName("Condenser Loop Heating Temperature (F)")
		# condLoopHeatingTemp.setDefaultValue(60)	
		# args << condLoopHeatingTemp
		
		# Vertical Bore HX
		building_area = model.getBuilding.floorArea 
		building_cool_ton = building_area*10.7639/500		# 500sf/ton estimated
		bore_hole_no = OpenStudio::Ruleset::OSArgument::makeIntegerArgument("bore_hole_no",false)
		bore_hole_no.setDisplayName("Number of Bore Holes")
		bore_hole_no.setDefaultValue(building_cool_ton.to_i) 
		args << bore_hole_no

		
		bore_hole_length = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("bore_hole_length",false)
		bore_hole_length.setDisplayName("Bore Hole Length (ft)")
		bore_hole_length.setDefaultValue(200)
		args << bore_hole_length

		bore_hole_radius = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("bore_hole_radius",false)
		bore_hole_radius.setDisplayName("Bore Hole Radius (inch)")
		bore_hole_radius.setDefaultValue(6.0)
		args << bore_hole_radius
		
		ground_k_value = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("ground_k_value",false)
		ground_k_value.setDisplayName("Ground Conductivity (Btu/hr.F.R")
		ground_k_value.setDefaultValue(0.75)
		args << ground_k_value
		
		grout_k_value = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("grout_k_value",false)
		grout_k_value.setDisplayName("Grout Conductivity (Btu/hr.F.R")
		grout_k_value.setDefaultValue(0.75)
		args << grout_k_value
		
		chs = OpenStudio::StringVector.new
		chs << "Yes"
		chs << "No"
		supplemental_boiler = OpenStudio::Ruleset::OSArgument::makeChoiceArgument("supplemental_boiler",chs, true)
		supplemental_boiler.setDisplayName("Supplemental Heating Boiler?")
		supplemental_boiler.setDefaultValue("No")
		args << supplemental_boiler
		
		# Boiler Capacity
		boiler_cap = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("boiler_cap",false)
		boiler_cap.setDisplayName("boiler normal capacity (MBtuh)")
		boiler_cap.setDefaultValue(500.0)
		args << boiler_cap
				
		# Boiler Efficiency
		boiler_eff = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("boiler_eff",false)
		boiler_eff.setDisplayName("Boiler Thermal Efficiency")
		boiler_eff.setDefaultValue(0.9)
		args << boiler_eff
		
		# Boiler fuel Type
		fuel_choices = OpenStudio::StringVector.new
		fuel_choices << "NaturalGas"
		fuel_choices << "PropaneGas"
		fuel_choices << "FuelOil#1"
		fuel_choices << "FuelOil#2"
		fuel_choices << "Electricity"
		boiler_fuel_type =  OpenStudio::Ruleset::OSArgument::makeChoiceArgument("boiler_fuel_type",fuel_choices,false) 
		boiler_fuel_type.setDisplayName("Boiler Fuel Type")
		boiler_fuel_type.setDefaultValue("NaturalGas")
		args << boiler_fuel_type
		
		# boiler Hot water supply temperature
		boiler_hw_st = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("boiler_hw_st",false)
		boiler_hw_st.setDisplayName("Boiler Design Heating Water Outlet Temperature (F)")
		boiler_hw_st.setDefaultValue(120)	
		args << boiler_hw_st
		
		# DOAS Fan Type
		doas_fan_choices = OpenStudio::StringVector.new
		doas_fan_choices << "Constant"
		doas_fan_choices << "Variable"
		doas_fan_type = OpenStudio::Ruleset::OSArgument::makeChoiceArgument("doas_fan_type",doas_fan_choices,true)
		doas_fan_type.setDisplayName("DOAS Fan Flow Control - Variable means DCV controls")
		doas_fan_type.setDefaultValue("Variable")
		args << doas_fan_type
		
		# DOAS Energy Recovery
		erv_choices = OpenStudio::StringVector.new
		erv_choices << "plate w/o economizer lockout"
		erv_choices << "plate w/ economizer lockout"
		erv_choices << "rotary wheel w/o economizer lockout"
		erv_choices << "rotary wheel w/ economizer lockout"
		erv_choices << "none"
		doas_erv = OpenStudio::Ruleset::OSArgument::makeChoiceArgument("doas_erv",erv_choices,true)
		doas_erv.setDisplayName("DOAS Energy Recovery?")
		doas_erv.setDefaultValue("none")
		args << doas_erv
		
		# DOAS Evaporative Cooling
		evap_choices = OpenStudio::StringVector.new
		evap_choices << "Direct Evaporative Cooler"
		evap_choices << "none"
		doas_evap = OpenStudio::Ruleset::OSArgument::makeChoiceArgument("doas_evap",evap_choices,true)
		doas_evap.setDisplayName("DOAS Direct Evaporative Cooling?")
		doas_evap.setDefaultValue("none")
		args << doas_evap
		
		# DOAS DX Cooling
		doas_dx_eer = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("doas_dx_eer",false)
		doas_dx_eer.setDisplayName("DOAS DX Cooling EER")
		doas_dx_eer.setDefaultValue(10.0)
		args << doas_dx_eer
	
    # make an argument for material and installation cost
    # todo - I would like to split the costing out to the air loops weighted by area of building served vs. just sticking it on the building
    cost_total_hvac_system = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("cost_total_hvac_system",true)
    cost_total_hvac_system.setDisplayName("Total Cost for HVAC System ($).")
    cost_total_hvac_system.setDefaultValue(0.0)
    args << cost_total_hvac_system
    
    #make an argument to remove existing costs
    remake_schedules = OpenStudio::Ruleset::OSArgument::makeBoolArgument("remake_schedules",true)
    remake_schedules.setDisplayName("Apply recommended availability and ventilation schedules for air handlers?")
    remake_schedules.setDefaultValue(true)
    args << remake_schedules

    return args
  end #end the arguments method

  #define what happens when the measure is run
  def run(model, runner, user_arguments)
    super(model, runner, user_arguments)

    # Use the built-in error checking 
    if not runner.validateUserArguments(arguments(model), user_arguments)
      return false
    end
	
		# Assign the user inputs to variables
		space_type_to_edits_hash = {}
		model.getSpaceTypes.each do |space_type|
			if space_type.spaces.size > 0
				space_type_to_edit = runner.getBoolArgumentValue(space_type.name.get.to_s,user_arguments)
				space_type_to_edits_hash[space_type] = space_type_to_edit 
			end		
		end

		bore_hole_no = runner.getIntegerArgumentValue("bore_hole_no",user_arguments)
		bore_hole_length = runner.getDoubleArgumentValue("bore_hole_length",user_arguments)
		bore_hole_radius = runner.getDoubleArgumentValue("bore_hole_radius",user_arguments)
		ground_k_value = runner.getDoubleArgumentValue("ground_k_value",user_arguments)
		grout_k_value = runner.getDoubleArgumentValue("grout_k_value",user_arguments)
		supplemental_boiler = runner.getStringArgumentValue("supplemental_boiler",user_arguments)	
		
		gshp_htg_cop = runner.getDoubleArgumentValue("gshp_htg_cop",user_arguments)
		gshp_clg_eer = runner.getDoubleArgumentValue("gshp_clg_eer",user_arguments)
		gshp_fan_type = runner.getStringArgumentValue("gshp_fan_type",user_arguments)
		# condLoopCoolingTemp = runner.getDoubleArgumentValue("condLoopCoolingTemp",user_arguments)
		# condLoopHeatingTemp = runner.getDoubleArgumentValue("condLoopHeatingTemp",user_arguments)
		# coolingTowerWB = runner.getDoubleArgumentValue("coolingTowerWB",user_arguments)
		# coolingTowerApproach= runner.getDoubleArgumentValue("coolingTowerApproach",user_arguments)
		# coolingTowerDeltaT= runner.getDoubleArgumentValue("coolingTowerDeltaT",user_arguments)
		boiler_cap = runner.getDoubleArgumentValue("boiler_cap",user_arguments)
		boiler_eff= runner.getDoubleArgumentValue("boiler_eff",user_arguments)
		boiler_fuel_type = runner.getStringArgumentValue("boiler_fuel_type",user_arguments)
		boiler_hw_st= runner.getDoubleArgumentValue("boiler_hw_st",user_arguments)
		doas_fan_type = runner.getStringArgumentValue("doas_fan_type",user_arguments)
		doas_erv = runner.getStringArgumentValue("doas_erv",user_arguments)
		doas_evap = runner.getStringArgumentValue("doas_evap",user_arguments)
		doas_dx_eer= runner.getDoubleArgumentValue("doas_dx_eer",user_arguments)
	
    ### START INPUTS
    #assign the user inputs to variables
    ceiling_return_plenum_space_type = runner.getOptionalWorkspaceObjectChoiceValue("ceiling_return_plenum_space_type",user_arguments,model)
    cost_total_hvac_system = runner.getDoubleArgumentValue("cost_total_hvac_system",user_arguments)
    remake_schedules = runner.getBoolArgumentValue("remake_schedules",user_arguments)
    # check that space_type was chosen and exists in model
    ceiling_return_plenum_space_typeCheck = OsLib_HelperMethods.checkOptionalChoiceArgFromModelObjects(ceiling_return_plenum_space_type, "ceiling_return_plenum_space_type","to_SpaceType", runner, user_arguments)
    if ceiling_return_plenum_space_typeCheck == false then return false else ceiling_return_plenum_space_type = ceiling_return_plenum_space_typeCheck["modelObject"] end
    # default building/ secondary space types
    standardBuildingTypeTest = [] #ML Not used yet
		#secondarySpaceTypeTest = ["Cafeteria", "Kitchen", "Gym", "Auditorium"]
    standardBuildingTypeTest = ["Office"] #ML Not used yet
    secondarySpaceTypeTest = [] # empty for office
    primarySpaceType = "Office"
		if doas_fan_type == "Variable"
			primaryHVAC = {"doas" => true, "fan" => "Variable", "heat" => "Gas", "cool" => "SingleDX"} 
		else
			primaryHVAC = {"doas" => true, "fan" => "Constant", "heat" => "Gas", "cool" => "SingleDX"}
		end
    secondaryHVAC = {"fan" => "None", "heat" => "None", "cool" => "None"} #ML not used for office; leave or empty?
    zoneHVAC = "GSHP"
    chillerType = "None" #set to none if chiller not used
    radiantChillerType = "None" #set to none if not radiant system
    allHVAC = {"primary" => primaryHVAC,"secondary" => secondaryHVAC,"zone" => zoneHVAC}

		
    ### END INPUTS
		
		# create a hash incorporating all user inputs on GSHP
		parameters = {"gshpCoolingEER" => gshp_clg_eer, 
									"gshpHeatingCOP" => gshp_htg_cop, 
									"gshpFanType" => gshp_fan_type,
									"groundKValue" => ground_k_value,
									"groutKValue" => grout_k_value,
									"boreHoleNo" => bore_hole_no,
									"boreHoleLength" => bore_hole_length,
									"boreHoleRadius" => bore_hole_radius,
									"supplementalBoiler" => supplemental_boiler,
									"boilerCap" => boiler_cap,
									"boilerEff" => boiler_eff,
									"boilerFuelType" => boiler_fuel_type,
									"boilerHWST" => boiler_hw_st,
									"doasFanType" => doas_fan_type,
									"doasDXEER" => doas_dx_eer,
									"doasERV" => doas_erv,
									"doasEvap" => doas_evap}

    ### START SORT ZONES
    options = {"standardBuildingTypeTest" => standardBuildingTypeTest, #ML Not used yet
               "secondarySpaceTypeTest" => secondarySpaceTypeTest,
               "ceiling_return_plenum_space_type" => ceiling_return_plenum_space_type}
    zonesSorted = OsLib_HVAC.sortZones(model, runner, options, space_type_to_edits_hash)
    zonesPrimary = zonesSorted["zonesPrimary"]
    zonesSecondary = zonesSorted["zonesSecondary"]
    zonesPlenum = zonesSorted["zonesPlenum"]
    zonesUnconditioned = zonesSorted["zonesUnconditioned"]
    ### END SORT ZONES
    
    ### START REPORT INITIAL CONDITIONS
    OsLib_HVAC.reportConditions(model, runner, "initial")
    ### END REPORT INITIAL CONDITIONS

    ### START ASSIGN HVAC SCHEDULES
    options = {"primarySpaceType" => primarySpaceType,
               "allHVAC" => allHVAC,
               "remake_schedules" => remake_schedules}
    schedulesHVAC = OsLib_HVAC.assignHVACSchedules(model, runner, options)
    # assign schedules
    primary_SAT_schedule = schedulesHVAC["primary_sat"]
    building_HVAC_schedule = schedulesHVAC["hvac"]
    building_ventilation_schedule = schedulesHVAC["ventilation"]
    make_hot_water_plant = false
    unless schedulesHVAC["hot_water"].nil?
      hot_water_setpoint_schedule = schedulesHVAC["hot_water"]
      make_hot_water_plant = true
    end
    make_chilled_water_plant = false
    unless schedulesHVAC["chilled_water"].nil?
      chilled_water_setpoint_schedule = schedulesHVAC["chilled_water"]
      make_chilled_water_plant = true
    end
    make_radiant_hot_water_plant = false
    unless schedulesHVAC["radiant_hot_water"].nil?
      radiant_hot_water_setpoint_schedule = schedulesHVAC["radiant_hot_water"]
      make_radiant_hot_water_plant = true
    end
    make_radiant_chilled_water_plant = false
    unless schedulesHVAC["radiant_chilled_water"].nil?
      radiant_chilled_water_setpoint_schedule = schedulesHVAC["radiant_chilled_water"]
      make_radiant_chilled_water_plant = true
    end
    unless schedulesHVAC["hp_loop"].nil?
      heat_pump_loop_setpoint_schedule = schedulesHVAC["hp_loop"]
    end
    unless schedulesHVAC["hp_loop_cooling"].nil?
      heat_pump_loop_cooling_setpoint_schedule = schedulesHVAC["hp_loop_cooling"]
    end
    unless schedulesHVAC["hp_loop_heating"].nil?
      heat_pump_loop_heating_setpoint_schedule = schedulesHVAC["hp_loop_heating"]
    end
    unless schedulesHVAC["mean_radiant_heating"].nil?
      mean_radiant_heating_setpoint_schedule = schedulesHVAC["mean_radiant_heating"]
    end
    unless schedulesHVAC["mean_radiant_cooling"].nil?
      mean_radiant_cooling_setpoint_schedule = schedulesHVAC["mean_radiant_cooling"]
    end
    ### END ASSIGN HVAC SCHEDULES
    runner.registerInfo("number of bore holes are #{model.getBuilding.floorArea} m2")
    # START REMOVE EQUIPMENT
		options = {}
		options["zonesPrimary"] = zonesPrimary
		if options["zonesPrimary"].empty?
			runner.registerInfo("User did not pick any zones to be added to GSHP system, no changes to the model were made.")
		else
			OsLib_HVAC.removeEquipment(model, runner, options)
		end
    ### END REMOVE EQUIPMENT
    
    ### START CREATE NEW PLANTS
    # create new plants
    # hot water plant
    if make_hot_water_plant
      hot_water_plant = OsLib_HVAC.createHotWaterPlant(model, runner, hot_water_setpoint_schedule, "Hot Water", parameters)
    end
    # chilled water plant
    if make_chilled_water_plant
      chilled_water_plant = OsLib_HVAC.createChilledWaterPlant(model, runner, chilled_water_setpoint_schedule, "Chilled Water", chillerType)
    end
    # radiant hot water plant
    if make_radiant_hot_water_plant
      radiant_hot_water_plant = OsLib_HVAC.createHotWaterPlant(model, runner, radiant_hot_water_setpoint_schedule, "Radiant Hot Water")
    end
    # chilled water plant
    if make_radiant_chilled_water_plant
      radiant_chilled_water_plant = OsLib_HVAC.createChilledWaterPlant(model, runner, radiant_chilled_water_setpoint_schedule, "Radiant Chilled Water", radiantChillerType)
    end
    # condenser loop
    # need condenser loop if there is a water-cooled chiller or if there is a water source heat pump loop
    options = {}
		options["zonesPrimary"] = zonesPrimary
    options["zoneHVAC"] = zoneHVAC
    if zoneHVAC.include? "SHP"
      options["loop_setpoint_schedule"] = heat_pump_loop_setpoint_schedule
      options["cooling_setpoint_schedule"] = heat_pump_loop_cooling_setpoint_schedule
      options["heating_setpoint_schedule"] = heat_pump_loop_heating_setpoint_schedule
    end  
		if options["zonesPrimary"].empty?
		  # runner.registerWarning("User did not pick any space types to be added to the WSHP system, no changes to the model were made")
			condenserLoops = {}
			# condenserLoops["condenser_loop"] ={}
		else
			condenserLoops = OsLib_HVAC.createCondenserLoop(model, runner, options, parameters)
		end
    unless condenserLoops["condenser_loop"].nil?
      condenser_loop = condenserLoops["condenser_loop"]
    end
    unless condenserLoops["heat_pump_loop"].nil?
      heat_pump_loop = condenserLoops["heat_pump_loop"]
    end
    ### END CREATE NEW PLANTS
    
    ### START CREATE PRIMARY AIRLOOPS
    # populate inputs hash for create primary airloops method
    options = {}
    options["zonesPrimary"] = zonesPrimary
    options["primaryHVAC"] = primaryHVAC
    options["zoneHVAC"] = zoneHVAC
    if primaryHVAC["doas"]
      options["hvac_schedule"] = building_ventilation_schedule
      options["ventilation_schedule"] = building_ventilation_schedule
    else
      # primary HVAC is multizone VAV
      unless zoneHVAC == "DualDuct"
        # primary system is multizone VAV that cools and ventilates
        options["hvac_schedule"] = building_HVAC_schedule
        options["ventilation_schedule"] = building_ventilation_schedule
      else
        # primary system is a multizone VAV that cools only (primary system ventilation schedule is set to always off; hvac set to always on)
        options["hvac_schedule"] = model.alwaysOnDiscreteSchedule()
      end
    end
    options["primary_sat_schedule"] = primary_SAT_schedule
    if make_hot_water_plant
      options["hot_water_plant"] = hot_water_plant
    end
    if make_chilled_water_plant
      options["chilled_water_plant"] = chilled_water_plant
    end
    primary_airloops = OsLib_HVAC.createPrimaryAirLoops(model, runner, options, parameters)
    ### END CREATE PRIMARY AIRLOOPS
    
    ### START CREATE SECONDARY AIRLOOPS
    # populate inputs hash for create primary airloops method
    options = {}
    options["zonesSecondary"] = zonesSecondary
    options["secondaryHVAC"] = secondaryHVAC
    options["hvac_schedule"] = building_HVAC_schedule
    options["ventilation_schedule"] = building_ventilation_schedule
    if make_hot_water_plant
      options["hot_water_plant"] = hot_water_plant
    end
    if make_chilled_water_plant
      options["chilled_water_plant"] = chilled_water_plant
    end
    secondary_airloops = OsLib_HVAC.createSecondaryAirLoops(model, runner, options)
    ### END CREATE SECONDARY AIRLOOPS
    
    ### START ASSIGN PLENUMS
    options = {"zonesPrimary" => zonesPrimary,"zonesPlenum" => zonesPlenum}
    zone_plenum_hash = OsLib_HVAC.validateAndAddPlenumZonesToSystem(model, runner, options)
    ### END ASSIGN PLENUMS
    
    ### START CREATE PRIMARY ZONE EQUIPMENT
    options = {}
    options["zonesPrimary"] = zonesPrimary
    options["zoneHVAC"] = zoneHVAC
    if make_hot_water_plant
      options["hot_water_plant"] = hot_water_plant
    end
    if make_chilled_water_plant
      options["chilled_water_plant"] = chilled_water_plant
    end
    if zoneHVAC.include? "SHP"
      options["heat_pump_loop"] = heat_pump_loop
    end
    if zoneHVAC == "DualDuct"
      options["ventilation_schedule"] = building_ventilation_schedule
    end
    if zoneHVAC == "Radiant"
      options["radiant_hot_water_plant"] = radiant_hot_water_plant
      options["radiant_chilled_water_plant"] = radiant_chilled_water_plant
      options["mean_radiant_heating_setpoint_schedule"] = mean_radiant_heating_setpoint_schedule
      options["mean_radiant_cooling_setpoint_schedule"] = mean_radiant_cooling_setpoint_schedule
    end
    OsLib_HVAC.createPrimaryZoneEquipment(model, runner, options, parameters)
    ### END CREATE PRIMARY ZONE EQUIPMENT
    
    # START ADD DCV
    options = {}
    unless zoneHVAC == "DualDuct"
      options["primary_airloops"] = primary_airloops
    end
    options["secondary_airloops"] = secondary_airloops
    options["allHVAC"] = allHVAC
    OsLib_HVAC.addDCV(model, runner, options)
    # END ADD DCV
       
    # Add in lifecycle costs
    expected_life = 25
    years_until_costs_start = 0
    costHVAC = cost_total_hvac_system
    lcc_mat = OpenStudio::Model::LifeCycleCost.createLifeCycleCost("HVAC System", model.getBuilding, costHVAC, "CostPerEach", "Construction", expected_life, years_until_costs_start).get

    ### START REPORT FINAL CONDITIONS
    OsLib_HVAC.reportConditions(model, runner, "final")
    ### END REPORT FINAL CONDITIONS

    return true

  end #end the run method

end #end the measure

#this allows the measure to be used by the application
ReplaceHVACWithGSHPAndDOAS.new.registerWithApplication