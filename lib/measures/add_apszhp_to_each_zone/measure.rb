# Author: Julien Marrec
# email: julien.marrec@gmail.com

# start the measure
class AddAPSZHPToEachZone < OpenStudio::Ruleset::ModelUserScript
  
  #define the name that a user will see, this method may be deprecated as
  #the display name in PAT comes from the name field in measure.xml
  def name
    return "Add a PSZ-HP to each zone"
  end
  
  def description
  
    return "This will add a Rooftop Packaged Single Zone Heat Pump (RTU with DX cooling and DX heating coils) to each zone of the model."
  
  end

  def modeler_description

    return "Add a System 4 - PSZ-HP - unit for each zone. This is a single zone system.
Parameters:
- Double: COP cooling and COP heating (Double)
- Boolean: supplementary electric heating coil (Boolean)
- Pressure rise (Optional Double)
- Deletion of existing HVAC equipment (Boolean)
- DCV enabled or not (Boolean)
- Fan type: Variable Volume Fan (VFD) or not (Constant Volume) (Choice)
- Filter for the zone name (String): only zones that contains the string you input in filter will receive this system."

  end
  
  # define the arguments that the user will input
  def arguments(model)
    args = OpenStudio::Ruleset::OSArgumentVector.new

    delete_existing = OpenStudio::Ruleset::OSArgument::makeBoolArgument('delete_existing', true)
    delete_existing.setDisplayName('Delete any existing HVAC equipment?')
    args << delete_existing
    
    cop_cooling = OpenStudio::Ruleset::OSArgument::makeDoubleArgument('cop_cooling', true)
    cop_cooling.setDisplayName('COP Cooling (SI)')
    cop_cooling.setDefaultValue(3.1)
    args << cop_cooling

    cop_heating = OpenStudio::Ruleset::OSArgument::makeDoubleArgument('cop_heating',  true)
    cop_heating.setDisplayName('COP Heating (SI)')
    cop_heating.setDefaultValue(3.1)
    args << cop_heating
	
    has_electric_coil = OpenStudio::Ruleset::OSArgument::makeBoolArgument('has_electric_coil', false)
    has_electric_coil.setDisplayName('Include supplementary electric heating coils?')
    has_electric_coil.setDefaultValue(true)
    args << has_electric_coil
    
    has_dcv = OpenStudio::Ruleset::OSArgument::makeBoolArgument('has_dcv', false)
    has_dcv.setDisplayName('Enable Demand Controlled Ventilation?')
    has_dcv.setDefaultValue(false)
    args << has_dcv
    
    chs = OpenStudio::StringVector.new
    chs << "Constant Volume (default)"
    chs << "Variable Volume (VFD)"
    fan_type = OpenStudio::Ruleset::OSArgument::makeChoiceArgument('fan_type', chs, true)
    fan_type.setDisplayName("Select fan type:")
    args << fan_type
      
    fan_pressure_rise = OpenStudio::Ruleset::OSArgument::makeDoubleArgument('fan_pressure_rise', false)
    fan_pressure_rise.setDisplayName('Fan Pressure Rise (Pa)')
    fan_pressure_rise.setDescription('Leave blank for default value')
    #fan_pressure_rise.setDefaultValue(0)
    args << fan_pressure_rise


    chs = OpenStudio::StringVector.new
    chs << "By Space Type"
    chs << "By Space Type's 'Standards Space Type'"
    chs << "By Zone Filter"
    filter_type = OpenStudio::Ruleset::OSArgument::makeChoiceArgument('filter_type', chs, true)
    filter_type.setDisplayName("How do you want to choose the affected zones?")
    args << filter_type

    # create an argument for a space type to be used in the model. Only return those that are used
    spaceTypes = model.getSpaceTypes
    usedSpaceTypes_handle = OpenStudio::StringVector.new
    usedSpaceTypes_displayName = OpenStudio::StringVector.new

    # Should normally be an OpenStudio::StringVector.new but it doesn't have a uniq! method and it works with a regular hash..
    standardsSpaceType = []

    spaceTypes.each do |spaceType|
      if spaceType.spaces.size > 0 # only show space types used in the building
        usedSpaceTypes_handle << spaceType.handle.to_s
        usedSpaceTypes_displayName << spaceType.name.to_s

        if not spaceType.standardsSpaceType.empty?
          standardsSpaceType << spaceType.standardsSpaceType.get
        end
      end
  end

  # make an argument for space type
  space_type = OpenStudio::Ruleset::OSArgument::makeChoiceArgument("space_type", usedSpaceTypes_handle, usedSpaceTypes_displayName,false)
  space_type.setDisplayName("a. Which Space Type?")
    args << space_type



    # Argument for Standards Space Type

    # First, make it unique
    standardsSpaceType.uniq!
    standards_space_type = OpenStudio::Ruleset::OSArgument::makeChoiceArgument('standards_space_type', standardsSpaceType, false)
    standards_space_type.setDisplayName("b. Which Standards Space Type")
    args << standards_space_type

    zone_filter = OpenStudio::Ruleset::OSArgument::makeStringArgument('zone_filter', false)
    zone_filter.setDisplayName("c. Only Apply to Zones that contain the following string")
    zone_filter.setDescription("Case insensitive. For example, type 'retail' to apply to zones that have the word 'retail' or 'REtaiL' in their name. Leave blank to apply to all zones")
    args << zone_filter
    
    return args
  end # end the arguments method

  # define what happens when the measure is run
  def run(model, runner, user_arguments)
    super(model, runner, user_arguments)
    
    # use the built-in error checking 
    if not runner.validateUserArguments(arguments(model), user_arguments)
      return false
    end

    # Retrieve arguments' values
    delete_existing = runner.getBoolArgumentValue('delete_existing', user_arguments)
    cop_cooling = runner.getDoubleArgumentValue('cop_cooling', user_arguments)
    cop_heating = runner.getDoubleArgumentValue('cop_heating', user_arguments)
    has_electric_coil = runner.getBoolArgumentValue('has_electric_coil', user_arguments)
    has_dcv = runner.getBoolArgumentValue('has_dcv', user_arguments)

    # Get fan_pressure_rise: this is an OptionalDouble - we'll use '.get' later
    fan_pressure_rise = runner.getOptionalDoubleArgumentValue('fan_pressure_rise', user_arguments)
    
    # FanType
    fan_type = runner.getStringArgumentValue('fan_type', user_arguments)
    runner.registerInfo("Fan type: #{fan_type}")

    if fan_type == 'Variable Volume (VFD)'
      has_vfd = true
    else
      has_vfd = false
    end

    filter_type = runner.getStringArgumentValue("filter_type",user_arguments)

    if filter_type == "By Space Type"
      space_type = runner.getOptionalWorkspaceObjectChoiceValue("space_type",user_arguments,model)
      if not space_type.empty?
        space_type = space_type.get
        if not space_type.to_SpaceType.empty?
          space_type = space_type.to_SpaceType.get
          zones = []
          space_type.spaces.each do |space|
            if not space.thermalZone.empty?
              z = space.thermalZone.get
              zones << z
            end
          end
        end
      end

    elsif filter_type == "By Space Type's 'Standards Space Type'"

      standards_space_type = runner.getOptionalStringArgumentValue("standards_space_type", user_arguments)
      puts standards_space_type.class

      if not standards_space_type.empty?
        standards_space_type = standards_space_type.get
        puts standards_space_type
        space_types = model.getSpaceTypes

        zones = []

        space_types.each do |space_type|
          if space_type.standardsSpaceType.to_s.upcase == standards_space_type.upcase
            space_type.spaces.each do |space|
              if not space.thermalZone.empty?
                z = space.thermalZone.get
                # We MUST check if zone isn't in there yet (or at the end do zones.uniq!) because several spaces can refer to the same thermal zone!
                if not zones.include?(z)
                  zones << z
                end
              end
            end
          end
        end
      end

    else
      # Zone filter
      zone_filter = runner.getOptionalStringArgumentValue('zone_filter', user_arguments)

      # Get all thermal zones
      all_zones = model.getThermalZones

      # Array to store the zones that match the filter
      zones = []
      all_zones.each do |z|
        # Skip zone if name doesn't include zone_filter
        # Putting everything in Upper Case to make it case insensitive
        if !zone_filter.empty?
          if z.name.to_s.upcase.include? zone_filter.to_s.upcase
            zones << z
          end
        end
      end

      if zones.empty?
        runner.registerError("Your zone filter #{zone_filter} did not match anything")
        return false
      end

    end # End of if filter_type


    # Output zone names to console
    puts "\n\n================ ZONES THAT MATCHED THE FILTER ================\n"
    zones.each do |z|
      puts z.name
    end

    #info for initial condition
    initial_num_air_loops_demand_control = 0
    final_num_air_loops_demand_control = 0
    initial_num_fan_VFD = 0
    final_num_fan_VFD = 0
    delete_existing_air_loops = 0
    delete_existing_chiller_loops = 0
    delete_existing_condenser_loops = 0
    affected_loops = 0


    # If we need to delete existing HVAC loops, we'll store the PRE-EXISTING Loops in the following variables,
    # They will be used for clean up at the end
    if delete_existing
      air_loops = model.getAirLoopHVACs
      runner.registerInfo("Number of initial AirLoopHVACs: #{air_loops.size}")
      plant_loops = model.getPlantLoops
      runner.registerInfo("Number of initial PlantLoops: #{plant_loops.size}")
    end



    # For each thermal zones (zones is initialized above, depending on which filter you chose)
    zones.each do |z|
      
      # Create a system 4 (PSZ-HP)
      air_handler = OpenStudio::Model::addSystemType4(model).to_AirLoopHVAC.get
      
      # Set name of Air Loop to be thermal_zone + 'Airloop'
      # Local variable name convention for a non-constant (dynamic) value is 'snake_case'
      base_name = z.name.to_s
      air_handler.setName(base_name + ' AirLoop')
      
      
      # Get existing fan, created with System 4, constant volume by default
      old_fan = air_handler.supplyComponents(OpenStudio::Model::FanConstantVolume::iddObjectType).first
      old_fan = old_fan.to_FanConstantVolume.get
      
      #If you want a VFD, we replace it with a Variable Volume one
      if has_vfd
        
        # Get the outlet node after the existing fan on the loop     
        next_node = old_fan.outletModelObject.get.to_Node.get
        
        #Create the new Variable speed fan
        fan = OpenStudio::Model::FanVariableVolume.new(model)
        
        #Add the new fan to the oulet node of the existing fan
        #before deleting the existing one
        fan.addToNode(next_node)
        
        # Remove the existing fan.  When this happens, either the pump's
        # inlet or outlet node will be deleted and the other will remain
        old_fan.remove
        
        # Rename the fan clearly 
        fan.setName(base_name + ' Variable Volume Fan')
        
        # If fan_pressure_rise has a non zero null value, assign it.
        if !fan_pressure_rise.empty?
          #We need the .get because this is an OptionalDouble. the .get will return a Double (float)
          fan.setPressureRise(fan_pressure_rise.get)
          runner.registerInfo("Fan '#{fan.name}' was assigned pressure rise of '#{fan_pressure_rise.get}' Pa")
        end
        
        final_num_fan_VFD += 1
        
      else
        # If VFD isn't wanted, we just rename the constant volume fan
        old_fan.setName(base_name + ' Constant Volume Fan')
        
        # If fan_pressure_rise has a non zero null value, assign it.
        if !fan_pressure_rise.empty?
          #We need the .get because this is an OptionalDouble. the .get will return a Double (float)
          old_fan.setPressureRise(fan_pressure_rise.get)
          puts "Fan '#{old_fan.name}' was assigned pressure rise of '#{fan_pressure_rise.get}' Pa"
        end

        
      end
      
      # The Cooling coil expects an OptionalDouble
      coil = air_handler.supplyComponents(OpenStudio::Model::CoilCoolingDXSingleSpeed::iddObjectType).first
      coil = coil.to_CoilCoolingDXSingleSpeed.get
      # Set CoolingCoil COP
      coil.setRatedCOP(OpenStudio::OptionalDouble.new(cop_cooling))
      # Set CoolingCoil Name
      coil.setName(base_name + " Coil Cooling DX Single Speed")
      
      
      # The Heating coil expects a Double
      coilheating = air_handler.supplyComponents(OpenStudio::Model::CoilHeatingDXSingleSpeed::iddObjectType).first
      coilheating = coilheating.to_CoilHeatingDXSingleSpeed.get
      # Set HeatingCoil COP
      coilheating.setRatedCOP(cop_heating)
      # Set HeatingCoil Name
      coilheating.setName(base_name + " Coil Heating DX Single Speed")
      
      # Delete the electric heating coil if unwanted
      if !has_electric_coil
        coilheatingelec = air_handler.supplyComponents(OpenStudio::Model::CoilHeatingElectric::iddObjectType).first
        coilheatingelec.remove
      end
      
      #Enable DCV (dunno if working)
      if has_dcv
      
        #get air_handler supply components
        supply_components = air_handler.supplyComponents

        #find AirLoopHVACOutdoorAirSystem on loop
        supply_components.each do |supply_component|
          hVACComponent = supply_component.to_AirLoopHVACOutdoorAirSystem
          if not hVACComponent.empty?
            hVACComponent = hVACComponent.get

            #get ControllerOutdoorAir
            controller_oa = hVACComponent.getControllerOutdoorAir
            controller_oa.setName(base_name + ' Controller Outdoor Air')

            #get ControllerMechanicalVentilation
            controller_mv = controller_oa.controllerMechanicalVentilation

            #check if demand control is enabled, if not, then enable it
            if controller_mv.demandControlledVentilation == true
              initial_num_air_loops_demand_control += 1
            else
              controller_mv.setDemandControlledVentilation(true)
              puts "Enabling demand control ventilation for #{air_handler.name}"
            end #End of if 
            final_num_air_loops_demand_control += 1
            
          end #End of HVACComponent.empty?
        
        end #end of supply component do loop
        
      end #End of has_dcv loop
      
      # Add a branch for the zone in question
      air_handler.addBranchForZone(z)
      
      #Counter
      affected_loops +=1 
      
    end #end of do loop on each thermal zone


    #CLEAN-UP SECTION
    # Idea: loop on PRE-EXISTING AirLoops, delete all that don't have any zones anymore
    # Then loop on chiller loop, delete all that don't have a coil connected to an air loop
    # then loop on condenser water, delette all that don't have a chiller anymore

    #If we need to delete existing HVAC loops, we'll loop on the PRE-EXISTING Loops we stored earlier
    if delete_existing


      # Arrays to store the affected loops
      chiller_plant_loops = []
      boiler_plant_loops = []
      condenser_plant_loops = []


      # Display separator for clarity
      runner.registerInfo("")
      runner.registerInfo("========================== CLEAN-UP: AIR LOOPS ==========================")

      # Loop on the pre-existing air loops (not the ones that were created above)
      air_loops.each do |air_loop|

        # Check if it's got a thermal zone attached left or not..
        # We assume we'll delete it unless...
        delete_flag = true

        air_loop.demandComponents.each do |comp|
          # If there is at least a single zone left, we can't delete it
          if comp.to_ThermalZone.is_initialized
            delete_flag = false
          end #end of if
        end #end of do loop on comp

        # If deletion is warranted
        if delete_flag
          #before deletion, let's get the potential associated plant loop.
          if air_loop.supplyComponents(OpenStudio::Model::CoilCoolingWater::iddObjectType).empty?
            puts "Air loop '#{air_loop.name}' DOES NOT HAVE a CoilHeatingWater"
          else
            cooling_coil = air_loop.supplyComponents(OpenStudio::Model::CoilCoolingWater::iddObjectType).first.to_CoilCoolingWater.get
            chiller_plant_loop = cooling_coil.plantLoop.get
            # Store handle in array
            chiller_plant_loops << chiller_plant_loop
            runner.registerInfo("Air loop '#{air_loop.name}' has a CoilCoolingWater, connected to CHILLER plant loop '#{chiller_plant_loop.name }'")
          end
          if air_loop.supplyComponents(OpenStudio::Model::CoilHeatingWater::iddObjectType).empty?
            puts "Air loop '#{air_loop.name}' DOES NOT HAVE a CoilHeatingWater"
          else
            heating_coil = air_loop.supplyComponents(OpenStudio::Model::CoilCoolingWater::iddObjectType).first.to_CoilCoolingWater.get
            boiler_plant_loop = heating_coil.plantLoop.get
            # Store handle in array
            boiler_plant_loops << boiler_plant_loop
            runner.registerInfo("Air loop '#{air_loop.name}' has a CoilHeatinggWater, connected to BOILER plant loop '#{boiler_plant_loop.name }'")
          end

          # Now we can delete and report.
          air_loop.remove
          runner.registerInfo("DELETED: Air loop '#{air_loop.name}' doesn't have Thermal zones attached and was removed")
          delete_existing_air_loops += 1
        else
          runner.registerInfo("Air Loop '#{air_loop.name}' has thermal zones and was not deleted")
        end #end if delete_flag
      end #end air_loops.each do



      # Display separator for clarity
      runner.registerInfo("")
      runner.registerInfo("====================== CLEAN-UP: CHILLER PLANT LOOPS ======================")

      #First pass on plant loops: chilled water loops.
      chiller_plant_loops.each do |chiller_plant_loop|

        puts "Chiller plant loop name: #{chiller_plant_loop.name}"

        # Check if the chiller plant loop has remaining demand components

        # Delete flag: first assumption is that yes... unless!
        delete_flag = true

        if chiller_plant_loop.demandComponents(OpenStudio::Model::CoilCoolingWater::iddObjectType).empty?
          puts "Chiller Plant loop '#{chiller_plant_loop.name}' DOES NOT HAVE a CoilCoolingWater"
        else
          puts "Chiller Plant loop '#{chiller_plant_loop.name}' has a CoilCoolingWater"
          cooling_coil = chiller_plant_loop.demandComponents(OpenStudio::Model::CoilCoolingWater::iddObjectType).first.to_CoilCoolingWater.get
          if cooling_coil.airLoopHVAC.empty?
            puts "But Cooling coil '#{cooling_coil.name}' is not connected to any airloopHVAC"
          else
            runner.registerInfo("And Cooling coil '#{cooling_coil.name}' is connected to airloopHVAC '#{cooling_coil.airLoopHVAC.get.name}' and therefore can't be deleted")
            # In this case, we can't delete the chiller plant loop
            delete_flag = false
          end #end cooling_coil.airLoopHVAC.empty?

        end #end of chiller_plant_loop.demandComponents CoilCoolingWater

        # We know it's a chiller plant so this is likely unnecessary, but better safe than sorry
        if chiller_plant_loop.demandComponents(OpenStudio::Model::WaterUseConnections::iddObjectType).empty?
          puts "Chiller Plant loop '#{chiller_plant_loop.name}' DOES NOT HAVE WaterUseConnections"
        else
          runner.registerInfo("Chiller Plant loop '#{chiller_plant_loop.name}' has WaterUseConnections and therefore can't be deleted")
          delete_flag = false
        end


        # If deletion is warranted
        if delete_flag

          #This section below is actually optional (but it's nice to only delete affected ones
          #before deletion, let's get the potential associated condenser water plant loop.
          if chiller_plant_loop.supplyComponents(OpenStudio::Model::ChillerElectricEIR::iddObjectType).empty?
           puts "Chiller Plant loop '#{chiller_plant_loop.name}' DOES NOT HAVE an electric chiller"
          else
            chiller = chiller_plant_loop.supplyComponents(OpenStudio::Model::ChillerElectricEIR::iddObjectType).first.to_ChillerElectricEIR.get
            puts "Chiller Plant loop '#{chiller_plant_loop.name}' has an electric chiller '#{chiller.name}' with condenser type '#{chiller.condenserType}'"
            # Check directly if chiller has a secondaryPlantLoop (no need to check if chiller.condenserType == 'WaterCooled' first)
            if chiller.secondaryPlantLoop.is_initialized
              # Chiller is WaterCooled therefore should be connected to a condenser water loop
              condenser_plant_loop = chiller.secondaryPlantLoop.get
              condenser_plant_loops << condenser_plant_loop
              runner.registerInfo("Chiller PlantLoop '#{chiller_plant_loop.name}' has a Water Cooled chiller connected to Condenser Plant Loop '#{condenser_plant_loop.name }'")
            end
          end

          # Now we can delete and report.
          chiller_plant_loop.remove
          delete_existing_chiller_loops += 1
          #Should I delete the chiller as well? It remains...

          runner.registerInfo("DELETED: Chiller PlantLoop '#{chiller_plant_loop.name}' wasn't connected to any AirLoopHVAC nor WaterUseConnections and therefore was removed")

        end #end of delete_flag

      end #end of chiller_plant_loops.each do

      # Display separator for clarity
      runner.registerInfo("")
      runner.registerInfo("===================== CLEAN-UP: CONDENSER PLANT LOOPS ====================")
      #Second pass on plant loops: condenser water loops.
      condenser_plant_loops.each do |condenser_plant_loop|

        delete_flag = true

        # If it has got a chiller as a demand component, it could still be empty
        if not condenser_plant_loop.demandComponents(OpenStudio::Model::ChillerElectricEIR::iddObjectType).empty?

          chiller = condenser_plant_loop.demandComponents(OpenStudio::Model::ChillerElectricEIR::iddObjectType).first.to_ChillerElectricEIR.get

          # If chiller is actually connected to a chilled water node, then we shall not delete it
          if not chiller.chilledWaterInletNodeName.empty?
            runner.registerInfo("On Condenser PlantLoop '#{condenser_plant_loop.name}, there is a demand component of type Chiller '#{chiller.name}'" +
                                    " that is connected to a chilled water loop and therefore cannot be deleted")
            delete_flag = false
          else
            puts "Plant loop '#{condenser_plant_loop.name}, Chiller '#{chiller.name}' isn't connected to a chilled water loop"
          end #end of if chiller.chilledWaterInletNodeName
        end #end of plant_loop.demandComponents

        # if deletion is warranted
        if delete_flag
          condenser_plant_loop.remove
          delete_existing_condenser_loops += 1
          runner.registerInfo("DELETED: Plant loop '#{condenser_plant_loop.name}' isn't connected to any chilled water loop")
        end


      end

      runner.registerInfo("")
      runner.registerInfo("For more information, go to 'Advanced Output'")

      # This is the generic way of looping on all loops, checking if it's a condenser plant loop, and to delete it unless it's got a chiller that is connected to chilled water plant loop
=begin
      plant_loops.each do |plant_loop|
        # Skip the chiller_plant_loops
        #next if chiller_plant_loops.include? plant_loop
        if chiller_plant_loops.include? plant_loop
          runner.registerInfo("Skipping Plant loop '#{plant_loop.name}' because it is a chiller plant")
          next
        end
        runner.registerInfo("Plant loop '#{plant_loop.name}'")

        # Until we know that it is a condenser loop for sure, we assume we can't delete it
        delete_flag = false

        # If it has got a chiller as a demand component, it's a condenser water loop
        if not plant_loop.demandComponents(OpenStudio::Model::ChillerElectricEIR::iddObjectType).empty?
          # Now, we assume we'll delete the loop unless it's actually connected and therefore usefull
          delete_flag = true
          chiller = plant_loop.demandComponents(OpenStudio::Model::ChillerElectricEIR::iddObjectType).first.to_ChillerElectricEIR.get
          # If chiller is actually connected to a chilled water node, then we shall not delete it
          if not chiller.chilledWaterInletNodeName.empty?
            runner.registerInfo("On Condenser PlantLoop '#{plant_loop.name}, there is a demand component of type Chiller '#{chiller.name}'" +
                                  " that is connected to a chilled water loop and therefore cannot be deleted")
            delete_flag = false
          else
            runner.registerInfo("Plant loop '#{plant_loop.name}, Chiller '#{chiller.name}' isn't connected to a chilled water loop")
          end #end of if chiller.chilledWaterInletNodeName
        end #end of plant_loop.demandComponents

        # if deletion is warranted
        if delete_flag
          plant_loop.remove
          delete_existing_condenser_loops += 1
          runner.registerInfo("DELETED: Plant loop '#{plant_loop.name}'")
        end

      end #end of plant_loops.each do
=end

      #Third pass on plant loops: boiler water loops.
      # TO WRITE


    end #end of if delete_existing

    #Report Initial Condition
    if delete_existing
      air_loop_str = "\n #{delete_existing_air_loops} existing AirLoopHVACs have been deleted"
      chiller_plant_loop_str = "\n #{delete_existing_chiller_loops} existing Chiller PlantLoops have been deleted"
      condenser_plant_loop_str = "\n #{delete_existing_condenser_loops} existing Condenser PlantLoops have been deleted"
    else
      air_loop_str = ""
      chiller_plant_loop_str = ""
      condenser_plant_loop_str = ""
    end #end of delete_existing

    runner.registerInitialCondition("Initially #{initial_num_air_loops_demand_control} air loops had demand controlled ventilation enabled" +
                                          air_loop_str + chiller_plant_loop_str + condenser_plant_loop_str + "\n")

    
    
    # Report final condition
    base_str = "There are #{OpenStudio::toNeatString(affected_loops, 0, true)} zones for which a PSZ-HP system was " +
        "created with a Cooling COP (SI) of #{OpenStudio::toNeatString(cop_cooling, 2, true)} " +
        "and a Heating COP (SI) of #{OpenStudio::toNeatString(cop_heating, 2, true)}."
    
    if has_electric_coil
      elec_str = "Supplementary electric heating coils were added."
    else
      elec_str = "Supplementary electrical heating coils were NOT included."
    end # end of has_electric_coil
    
    if has_vfd
      fan_str = "Fan type was changed to be Variable Volume (VFD) for #{final_num_fan_VFD} fans."
    else
      fan_str = "Fan type was chosen to be Constant Volume."
    end # end of has_vfd
    
    if final_num_air_loops_demand_control == 0
      dcv_str = "Demand Controlled Ventilation wasn't enabled for the new air loops"
    else
      dcv_str = "#{final_num_air_loops_demand_control} air loops now have demand controlled ventilation enabled"
    end
    
    runner.registerFinalCondition(base_str + "\n" + elec_str + "\n" + fan_str + "\n" + dcv_str + "\n \n")
    
    return true
    
    
  end # end the run method

end # end the measure

# this allows the measure to be used by the application
AddAPSZHPToEachZone.new.registerWithApplication
