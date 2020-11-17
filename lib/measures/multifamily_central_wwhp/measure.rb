# *******************************************************************************
# OpenStudio(R), Copyright (c) 2008-2018, Alliance for Sustainable Energy, LLC.
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

# load OpenStudio measure libraries
require 'openstudio-standards'

# start the measure
class MultifamilyCentralWasteWaterHeatPump < OpenStudio::Measure::ModelMeasure
  # define the name that a user will see, this method may be deprecated as
  # the display name in _@PAT comes from the name field in measure.xml
  def name
    return 'Multifamily Central Waste Water Heat Pump'
  end

  # human readable description
  def description
    return 'This measure replaces the service water heating equipment with a waste water heat pump loop and optionally top-off water heaters.'
  end

  # human readable description of modeling approach
  def modeler_description
    return 'This measure uses 4 loops to model the waste water heat pump. The WW-Water Connections loop records the waste water temperature and flow rate with EMS controls. The Waste Water Heat Pump loop models the flow from the tank to the heat pump. The Service Preheat Water loop heats up the water to a target supply temperature. The Service Hot Water Loop connects to water use objects.'
  end

  def add_piranha_heatpump(model)
    heat_pump = OpenStudio::Model::HeatPumpWaterToWaterEquationFitHeating.new(model)
    heat_pump.setName('Piranha')
    heat_pump.setRatedHeatingCapacity(400000.0)
    heat_pump.setRatedHeatingPowerConsumption(400000.0/3.476) # COP 3.476 obtained from Nick Smith's Paper
    heat_pump.setHeatingCapacityCoefficient1(-3.50792302)
    heat_pump.setHeatingCapacityCoefficient2(-0.491629910851523)
    heat_pump.setHeatingCapacityCoefficient3(4.62356048079675)
    heat_pump.setHeatingCapacityCoefficient4(0)
    heat_pump.setHeatingCapacityCoefficient5(0)
    heat_pump.setHeatingCompressorPowerCoefficient1(-4.33286711)
    heat_pump.setHeatingCompressorPowerCoefficient2(3.89611258)
    heat_pump.setHeatingCompressorPowerCoefficient3(0.64400684)
    heat_pump.setHeatingCompressorPowerCoefficient4(0)
    heat_pump.setHeatingCompressorPowerCoefficient5(0)
    heat_pump.setSizingFactor(1)
    return heat_pump
  end

  def add_swh_tank(model,
                   name: 'tank',
                   tank_volume_m3: 4.0,
                   heater_capacity_w: 0.0,
                   setpoint_temperature_sch_c: nil,
                   ambient_temperature_sch_c: nil)
    swh_tank = OpenStudio::Model::WaterHeaterMixed.new(model)
    swh_tank.setName(name)
    swh_tank.setTankVolume(tank_volume_m3)
    swh_tank.setHeaterMaximumCapacity(heater_capacity_w)
    swh_tank.setSetpointTemperatureSchedule(setpoint_temperature_sch_c)
    swh_tank.setHeaterThermalEfficiency(1.0)
    swh_tank.setOffCycleParasiticHeatFractiontoTank(1.0)
    swh_tank.setOffCycleParasiticFuelConsumptionRate(0.0)
    swh_tank.setOffCycleParasiticFuelType('Electricity')
    swh_tank.setOnCycleParasiticFuelType('Electricity')
    swh_tank.setAmbientTemperatureIndicator('Schedule')
    swh_tank.setAmbientTemperatureSchedule(ambient_temperature_sch_c)
    swh_tank.setHeaterFuelType('Electricity')
    return swh_tank
  end

  # define the arguments that the user will input
  def arguments(model)
    args = OpenStudio::Measure::OSArgumentVector.new

    # make an argument for SWH type
    swh_options = OpenStudio::StringVector.new
    swh_options << 'HPWH with Outdoor Condenser'
    swh_options << 'Waste Water Heat Pump 140F Supply'
    swh_options << 'Waste Water Heat Pump 120F Supply and Electric Tank'
    swh_options << 'Waste Water Heat Pump 90F Supply and Electric Tank'
    swh_type = OpenStudio::Measure::OSArgument::makeChoiceArgument('swh_type', swh_options, true)
    swh_type.setDisplayName('Choose the SWH type.')
    swh_type.setDefaultValue('Waste Water Heat Pump 120F Supply and Electric Tank')
    args << swh_type

    return args
  end

  # define what happens when the measure is run
  def run(model, runner, user_arguments)
    super(model, runner, user_arguments)

    # use the built-in error checking
    if !runner.validateUserArguments(arguments(model), user_arguments)
      return false
    end

    # use openstudio-standards methods
    std = Standard.build('ZE AEDG Multifamily')

    # assign the user inputs to variables
    swh_type = runner.getStringArgumentValue('swh_type', user_arguments)

    # logic to set in-unit heat pump water heaters to outdoor condensers
    # this is stand-alone from the rest of the code
    if swh_type == 'HPWH with Outdoor Condenser'
      if model.getWaterHeaterHeatPumpWrappedCondensers.empty?
        runner.registerAsNotApplicable('The model does not contain WaterHeaterHeatPumpWrappedCondenser objects. Cannot apply outdoor compressors.')
        return true
      end

      # set condenser to outdoors
      model.getWaterHeaterHeatPumpWrappedCondensers.each do |hpwh|
        hpwh.setCompressorLocation('Outdoors')
        hpwh.setInletAirConfiguration('OutdoorAirOnly')
      end

      # update the performance curves
      model.getCoilWaterHeatingAirToWaterHeatPumpWrappeds.each do |pumpedcondenser|
        pumpedcondenser.setRatedCOP(5.25)
        pumpedcondenser.setRatedCondenserWaterTemperature(40.0)
        pumpedcondenser.setRatedEvaporatorInletAirDryBulbTemperature(20.0)
        cop_curve = pumpedcondenser.heatingCOPFunctionofTemperatureCurve
        cap_curve = pumpedcondenser.heatingCapacityFunctionofTemperatureCurve
        model.getCurveBiquadratics.each do |curve|
          if cop_curve.name.get.to_s == curve.name.get.to_s
            curve.setCoefficient1Constant(3.04808817)
            curve.setCoefficient2x(0.0537844)
            curve.setCoefficient3xPOW2(-0.0014933)
            curve.setCoefficient4y(0.01038342)
            curve.setCoefficient5yPOW2(0.00083186)
            curve.setCoefficient6xTIMESY(-0.0002918)
            curve.setMinimumValueofx(-25.0)
            curve.setMaximumValueofx(50.0)
            curve.setMinimumValueofy(24.0)
            curve.setMaximumValueofy(50.0)
          elsif cap_curve.name.get.to_s == curve.name.get.to_s
            curve.setCoefficient1Constant(1.0)
            curve.setCoefficient2x(0.0)
            curve.setCoefficient3xPOW2(0.0)
            curve.setCoefficient4y(0.0)
            curve.setCoefficient5yPOW2(0.0)
            curve.setCoefficient6xTIMESY(0.0)
            curve.setMinimumValueofx(0.0)
            curve.setMaximumValueofx(100.0)
            curve.setMinimumValueofy(0.0)
            curve.setMaximumValueofy(100.0)
          end
        end
      end

      return true
    end

    # store water equipments
    water_use_equipments = []
    model.getWaterUseEquipments.each { |water_use_equipment| water_use_equipments << water_use_equipment }

    #remove existing swh fans
    model.getFanOnOffs.each{|fan| fan.remove if  fan.endUseSubcategory.include? 'Domestic Hot Water'}

    # remove existing shw loops
    model.getPlantLoops.each { |plant_loop|  plant_loop.remove if std.plant_loop_swh_loop?(plant_loop) }

    # remove existing SWH related related EnergyManagementSystem objects
    ems_object_types = ['OS:EnergyManagementSystem:Sensor',
                        'OS:EnergyManagementSystem:Actuator',
                        'OS:EnergyManagementSystem:ProgramCallingManager',
                        'OS:EnergyManagementSystem:Program',
                        'OS:EnergyManagementSystem:Subroutine',
                        'OS:EnergyManagementSystem:GlobalVariable',
                        'OS:EnergyManagementSystem:OutputVariable',
                        'OS:EnergyManagementSystem:MeteredOutputVariable',
                        'OS:EnergyManagementSystem:TrendVariable',
                        'OS:EnergyManagementSystem:InternalVariable',
                        'OS:EnergyManagementSystem:CurveOrTableIndexVariable',
                        'OS:EnergyManagementSystem:ConstructionIndexVariable']
    model.getModelObjects.each do |obj|
      next unless ems_object_types.include? obj.iddObject.name
      if (obj.name.get.include? 'res_wh_Building') || (obj.name.get.include? 'res wh_Building') ||(obj.name.get.include? 'wastewater')
        obj.remove
      end
    end

    # create water use equipment connection and add water use equipments
    water_use_connection = OpenStudio::Model::WaterUseConnections.new(model)
    water_use_connection.setName('SHW Loop Water Use Connection')
    water_use_equipments.each do |water_use_equipment|
      water_use_connection.addWaterUseEquipment(water_use_equipment)
    end

    # create new hot water loop
    swh_loop = OpenStudio::Model::PlantLoop.new(model)
    swh_loop.setName('Service Hot Water Loop')
    swh_loop.setMaximumLoopTemperature(100.0)
    swh_loop.setMinimumLoopTemperature(10.0)
    swh_loop_sizing = swh_loop.sizingPlant
    swh_loop_sizing.setLoopType('Heating')
    swh_loop_sizing.setDesignLoopExitTemperature(60.0)

    # create and add a pump to the loop
    swh_pump = OpenStudio::Model::PumpVariableSpeed.new(model)
    swh_pump.setName('Service Water Heating Pump')
    swh_pump.setRatedPumpHead(100.0)
    swh_pump.setRatedPowerConsumption(0.0)
    swh_pump.addToNode(swh_loop.supplyInletNode)

    # create a scheduled setpoint manager
    swh_temp_sch = OpenStudio::Model::ScheduleConstant.new(model)
    swh_temp_sch.setName('SHW Loop Supply Temp Schedule')
    swh_tank_ambient_temp_sch = std.model_add_constant_schedule_ruleset(model, 22.0, name = 'Ambient Temp Schedule')
    swh_setpoint_manager = OpenStudio::Model::SetpointManagerScheduled.new(model, swh_temp_sch)
    swh_setpoint_manager.setName('SWH Loop Supply Temp Setpoint Manager')

    # create a water heater
    swh_tank = add_swh_tank(model,
                            name: 'SWH Tank',
                            setpoint_temperature_sch_c: swh_temp_sch,
                            ambient_temperature_sch_c: swh_tank_ambient_temp_sch)
    swh_loop.addSupplyBranchForComponent(swh_tank)

    # add pipes
    shw_supply_bypass_pipe = OpenStudio::Model::PipeAdiabatic.new(model)
    shw_demand_bypass_pipe = OpenStudio::Model::PipeAdiabatic.new(model)
    shw_demand_inlet_pipe = OpenStudio::Model::PipeAdiabatic.new(model)
    shw_demand_outlet_pipe = OpenStudio::Model::PipeAdiabatic.new(model)
    swh_loop.addSupplyBranchForComponent(shw_supply_bypass_pipe)
    swh_loop.addDemandBranchForComponent(shw_demand_bypass_pipe)
    shw_demand_inlet_pipe.addToNode(swh_loop.demandInletNode)
    shw_demand_outlet_pipe.addToNode(swh_loop.demandOutletNode)

    # add water connections to the loop
    swh_loop.addDemandBranchForComponent(water_use_connection)

    # Service Preheat Water loop
    dpw_loop = OpenStudio::Model::PlantLoop.new(model)
    dpw_loop.setName('Service Preheat Water Loop')
    dpw_loop.setMaximumLoopTemperature(100.0)
    dpw_loop.setMinimumLoopTemperature(0.0)
    dpw_loop_sizing = dpw_loop.sizingPlant
    dpw_loop_sizing.setLoopType('Heating')
    dpw_loop_sizing.setDesignLoopExitTemperature(60.0)
    dpw_loop_sizing.setLoopDesignTemperatureDifference(10.0)

    # add SWH tank to the loop
    dpw_loop.addDemandBranchForComponent(swh_tank)

    # create a pump
    dpw_pump = OpenStudio::Model::PumpVariableSpeed.new(model)
    dpw_pump.setName('Service Preheat Water Pump')
    dpw_pump.setRatedPumpHead(OpenStudio.convert(20.0, 'ftH_{2}O', 'Pa').get)
    dpw_pump.addToNode(dpw_loop.supplyInletNode)
    dpw_pump.setEndUseSubcategory('Waste Water Heat Pump Preheat Loop Pump')

    # create a scheduled setpoint manager
    dpw_temp_sch = OpenStudio::Model::ScheduleConstant.new(model)
    dpw_temp_sch.setName('Service Preheat Water Loop Supply Temp Schedule')
    dpw_setpoint_manager = OpenStudio::Model::SetpointManagerScheduled.new(model, dpw_temp_sch)
    dpw_setpoint_manager.setName('Service Preheat Water Water Loop Setpoint Manager')

    # create a water heater
    heat_pump = add_piranha_heatpump(model)
    dpw_loop.addSupplyBranchForComponent(heat_pump)

    # add pipes
    dpw_supply_bypass_pipe = OpenStudio::Model::PipeAdiabatic.new(model)
    dpw_demand_inlet_pipe = OpenStudio::Model::PipeAdiabatic.new(model)
    dpw_demand_outlet_pipe = OpenStudio::Model::PipeAdiabatic.new(model)
    dpw_loop.addSupplyBranchForComponent(dpw_supply_bypass_pipe)
    dpw_demand_inlet_pipe.addToNode(dpw_loop.demandInletNode)
    dpw_demand_outlet_pipe.addToNode(dpw_loop.demandOutletNode)

    runner.registerInfo("Adding a #{swh_type} waste water heat pump")
    if swh_type == 'Waste Water Heat Pump 140F Supply'
      swh_loop_sizing.setLoopDesignTemperatureDifference(10.0)
      swh_temp_sch.setValue(60.0)
      swh_temp_sch.setName("#{swh_temp_sch.name} 140F")
      dpw_temp_sch.setValue(60.0)
      dpw_temp_sch.setName("#{dpw_temp_sch.name} 140F")
    else
      if swh_type == 'Waste Water Heat Pump 120F Supply and Electric Tank'
        hpwh_setpoint_f = 120.0
      elsif swh_type == 'Waste Water Heat Pump 90F Supply and Electric Tank'
        hpwh_setpoint_f = 90.0
      end
      swh_loop_sizing.setLoopDesignTemperatureDifference(40.0)
      swh_temp_sch.setValue(60.0)
      swh_temp_sch.setName("#{swh_temp_sch.name} 140F")
      hpwh_setpoint_c = OpenStudio.convert(hpwh_setpoint_f, 'F', 'C').get
      dpw_temp_sch.setValue(hpwh_setpoint_c)
      dpw_temp_sch.setName("#{dpw_temp_sch.name} #{hpwh_setpoint_f.round(1)}F")

      # create back up electric heater
      electric_tank = add_swh_tank(model,
                                   name: 'Electric Hot Water Tank',
                                   tank_volume_m3: 4.0,
                                   heater_capacity_w: 1000000.0,
                                   setpoint_temperature_sch_c: swh_temp_sch,
                                   ambient_temperature_sch_c: swh_tank_ambient_temp_sch)
      electric_tank.addToNode(swh_loop.supplyOutletNode)
    end

    # add setpoint managers
    swh_setpoint_manager.addToNode(swh_loop.supplyOutletNode)
    dpw_setpoint_manager.addToNode(dpw_loop.supplyOutletNode)

    # add piping losses with the model_add_piping_losses_to_swh_system standards method
    # add losses to the preheat water loop
    # AEDG multifamily guide recommends pipe insulation levels rated for a higher temperature of 141-200F
    # Per 90.1-2019 Table 6.8.3-1, this means 1.5 inch insulation for tube sizes <1.5 inch
    # The method adds a nominal 0.75 inch pipe with conductivity 0.46 Btu*in/hr*ft^2*R
    # Using the method in 90.1-2019, the required thickness is:
    # T = r * {(1 + t/r)^(K/k) - 1}
    # T is new thickness in inches, r is outside radius of pipe in inches, t is required thickness in table,
    # K is new conductivity value, and k is the upper conductivity range in the table
    # T = (0.875/2) * {(1 + 1.5/(0.875/2))^(0.46/0.27) - 1} = 4.2 inches
    std.model_add_piping_losses_to_swh_system(model,
                                              dpw_loop,
                                              true,
                                              pipe_insulation_thickness: 0.106626, # 4.2 inches
                                              floor_area_served: model.getBuilding.floorArea,
                                              number_of_stories: model.getBuildingStorys.size,
                                              air_temp_surrounding_piping: 21.1111)

    ## waste water heat pump loop
    wwhp_loop = OpenStudio::Model::PlantLoop.new(model)
    wwhp_loop.setName('Waste Water Heat Pump Loop')
    wwhp_loop.setMaximumLoopTemperature(100.0)
    wwhp_loop.setMinimumLoopTemperature(0.0)
    wwhp_loop_sizing = wwhp_loop.sizingPlant
    wwhp_loop_sizing.setLoopType('Heating')
    wwhp_loop_sizing.setDesignLoopExitTemperature(30.0)
    wwhp_loop_sizing.setLoopDesignTemperatureDifference(10.0)

    # add the heat pump created earlier
    wwhp_loop.addDemandBranchForComponent(heat_pump)

    # create a pump
    wwhp_pump = OpenStudio::Model::PumpVariableSpeed.new(model)
    wwhp_pump.setName('Waste Water Heat Pump Pump')
    wwhp_pump.setRatedPumpHead(OpenStudio.convert(20.0, 'ftH_{2}O', 'Pa').get)
    wwhp_pump.addToNode(wwhp_loop.supplyInletNode)
    wwhp_pump.setEndUseSubcategory('Waste Water Heat Pump Loop Pump')

    # create a scheduled setpoint manager
    ww_tank_setpoint_temp_sch = OpenStudio::Model::ScheduleConstant.new(model)
    ww_tank_setpoint_temp_sch.setName('WW Piranha Loop Supply Temp Schedule')
    ww_tank_setpoint_temp_sch.setValue(24.0)
    ww_tank_ambient_temperature_sch = std.model_add_constant_schedule_ruleset(model, 22.0, name = 'Waste Water Tank Ambient Temp Schedule')
    ww_setpoint_manager = OpenStudio::Model::SetpointManagerScheduled.new(model, ww_tank_setpoint_temp_sch)
    ww_setpoint_manager.setName('WW Piranha Loop Setpoint Manager')
    ww_setpoint_manager.addToNode(wwhp_loop.supplyOutletNode)

    # create the waste water tank
    ww_tank = add_swh_tank(model,
                          name:'Waste Water Tank',
                          tank_volume_m3: 5.678, #1500 gallons
                          setpoint_temperature_sch_c: ww_tank_setpoint_temp_sch,
                          ambient_temperature_sch_c: ww_tank_ambient_temperature_sch)
    wwhp_loop.addSupplyBranchForComponent(ww_tank)

    # add pipes
    wwhp_demand_bypass_pipe = OpenStudio::Model::PipeAdiabatic.new(model)
    wwhp_demand_inlet_pipe = OpenStudio::Model::PipeAdiabatic.new(model)
    wwhp_demand_outlet_pipe = OpenStudio::Model::PipeAdiabatic.new(model)
    wwhp_loop.addDemandBranchForComponent(wwhp_demand_bypass_pipe)
    wwhp_demand_inlet_pipe.addToNode(wwhp_loop.demandInletNode)
    wwhp_demand_outlet_pipe.addToNode(wwhp_loop.demandOutletNode)

    ## WW-Water Connections loop
    ww_loop = OpenStudio::Model::PlantLoop.new(model)
    ww_loop.setName('WW-Water Connections Loop')
    ww_loop.setMaximumLoopTemperature(100.0)
    ww_loop.setMinimumLoopTemperature(10.0)
    ww_loop.setLoadDistributionScheme('SequentialLoad')
    ww_loop_sizing = ww_loop.sizingPlant
    ww_loop_sizing.setLoopType('Heating')
    ww_loop_sizing.setDesignLoopExitTemperature(60.0)
    ww_loop_sizing.setLoopDesignTemperatureDifference(15.0)

    # add the tank
    ww_loop.addDemandBranchForComponent(ww_tank)

    # create a pump
    ww_pump = OpenStudio::Model::PumpVariableSpeed.new(model)
    ww_pump.setName('Waste Water Pump')
    ww_pump.setRatedPumpHead(100.0)
    ww_pump.setRatedPowerConsumption(0.0)
    ww_pump.addToNode(ww_loop.supplyInletNode)

    # setpoint temperature schedule
    ww_temp_sch = OpenStudio::Model::ScheduleCompact.new(model)
    ww_temp_sch.setName('WW Water Connections Loop Supply Temp Schedule')
    ww_temp_sch.setToConstantValue(24.0)

    # add temperature source
    ww_temp_source = OpenStudio::Model::PlantComponentTemperatureSource.new(model)
    ww_temp_source.setName('Wastewater Temperature Source')
    ww_temp_source.setSourceTemperatureSchedule(ww_temp_sch)
    ww_temp_source.setTemperatureSpecificationType('Scheduled')
    ww_temp_source.addToNode(ww_loop.supplyOutletNode)
    ww_temp_source_op_scheme = OpenStudio::Model::PlantEquipmentOperationHeatingLoad.new(model)
    ww_temp_source_op_scheme.addEquipment(ww_temp_source)
    ww_loop.setPlantEquipmentOperationHeatingLoad(ww_temp_source_op_scheme)

    # create a scheduled setpoint manager
    ww_setpoint_manager = OpenStudio::Model::SetpointManagerScheduled.new(model, ww_temp_sch)
    ww_setpoint_manager.setName('WW Water Connections Loop Setpoint Manager')
    ww_setpoint_manager.addToNode(ww_loop.supplyOutletNode)

    # create a supply bypass pipe
    ww_demand_inlet_pipe = OpenStudio::Model::PipeAdiabatic.new(model)
    ww_demand_outlet_pipe = OpenStudio::Model::PipeAdiabatic.new(model)
    ww_demand_inlet_pipe.addToNode(ww_loop.demandInletNode)
    ww_demand_outlet_pipe.addToNode(ww_loop.demandOutletNode)

    # rename plant loop nodes before running EMS code
    std.rename_plant_loop_nodes(model)

    # adding EMS for temperature source and COP calculation
    wwtsource_actuator = OpenStudio::Model::EnergyManagementSystemActuator.new(ww_temp_sch, 'Schedule:Compact', 'Schedule Value')
    wwtsource_actuator.setName('wastewater_temperature_schedule')

    wastewater_massflow_actuator = OpenStudio::Model::EnergyManagementSystemActuator.new(ww_pump, 'pump', 'Pump Mass Flow Rate')
    wastewater_massflow_actuator.setName('wastewater_massflow_actuator')

    wastewater_temp_sensor = OpenStudio::Model::EnergyManagementSystemSensor.new(model, 'Water Use Connections Waste Water Temperature')
    wastewater_temp_sensor.setName('wastewater_temp_sensor')
    wastewater_temp_sensor.setKeyName('SHW Loop Water Use Connection')

    wastewater_massflow_sensor = OpenStudio::Model::EnergyManagementSystemSensor.new(model, 'Water Use Connections Drain Water Mass Flow Rate')
    wastewater_massflow_sensor.setName('wastewater_massflow_sensor')
    wastewater_massflow_sensor.setKeyName('SHW Loop Water Use Connection')

    wastewater_program = OpenStudio::Model::EnergyManagementSystemProgram.new(model)
    wastewater_program.setName('wastewater_program')
    wastewater_program.addLine("Set #{wwtsource_actuator.name} = #{wastewater_temp_sensor.name}")
    wastewater_program.addLine("Set #{wastewater_massflow_actuator.name} = #{wastewater_massflow_sensor.name}")

    p_Piranha_sensor = OpenStudio::Model::EnergyManagementSystemSensor.new(model, 'Heat Pump Electric Power')
    p_Piranha_sensor.setName('P_Piranha_sensor')
    p_Piranha_sensor.setKeyName('Piranha')

    q_cond_Piranha_sensor = OpenStudio::Model::EnergyManagementSystemSensor.new(model, 'Heat Pump Load Side Heat Transfer Rate')
    q_cond_Piranha_sensor.setName('Q_cond_Piranha_sensor')
    q_cond_Piranha_sensor.setKeyName('Piranha')

    cop_Piranha_program = OpenStudio::Model::EnergyManagementSystemProgram.new(model)
    cop_Piranha_program.setName('cop_Piranha_program')
    cop_Piranha_program.addLine("IF #{p_Piranha_sensor.name} == 0")
    cop_Piranha_program.addLine('Set cop_Piranha = 0')
    cop_Piranha_program.addLine('ELSE')
    cop_Piranha_program.addLine("Set cop_Piranha = #{q_cond_Piranha_sensor.name}/#{p_Piranha_sensor.name}")
    cop_Piranha_program.addLine('ENDIF')

    # ProgramCallingManagers
    program_calling_manager = OpenStudio::Model::EnergyManagementSystemProgramCallingManager.new(model)
    program_calling_manager.setName('wastewater_program_management')
    program_calling_manager.setCallingPoint('BeginTimestepBeforePredictor')
    program_calling_manager.addProgram(wastewater_program)
    program_calling_manager.addProgram(cop_Piranha_program)

    # output variables
    pipe_loss_output = OpenStudio::Model::OutputVariable.new('Pipe Fluid Heat Transfer Energy', model)
    pipe_loss_output.setReportingFrequency ('timestep')
    pipe_loss_output.setKeyValue('*')

    heatpump_power = OpenStudio::Model::OutputVariable.new('Heat Pump Electric Power', model)
    heatpump_power.setReportingFrequency ('timestep')
    heatpump_power.setKeyValue('*')


    heatpump_energy = OpenStudio::Model::OutputVariable.new('Heat Pump Electric Energy', model)
    heatpump_energy.setReportingFrequency ('timestep')
    heatpump_energy.setKeyValue('*')

    heatpump_load_power = OpenStudio::Model::OutputVariable.new('Heat Pump Load Side Heat Transfer Rate', model)
    heatpump_load_power.setReportingFrequency ('timestep')
    heatpump_load_power.setKeyValue('*')

    heatpump_load_energy = OpenStudio::Model::OutputVariable.new('Heat Pump Load Side Heat Transfer Energy', model)
    heatpump_load_energy.setReportingFrequency ('timestep')
    heatpump_load_energy.setKeyValue('*')

    cop_piranha_output = OpenStudio::Model::EnergyManagementSystemOutputVariable.new(model, 'COP_Piranha')
    cop_piranha_output.setName('cop_piranha_output')
    cop_piranha_output.setTypeOfDataInVariable('Averaged')
    cop_piranha_output.setUpdateFrequency('SystemTimestep')
    cop_piranha_output.setEMSProgramOrSubroutineName(cop_Piranha_program)
    cop_piranha = OpenStudio::Model::OutputVariable.new('cop_piranha_output', model)
    cop_piranha.setReportingFrequency ('timestep')

    wastewater_temp_sensor_output = OpenStudio::Model::EnergyManagementSystemOutputVariable.new(model, 'wastewater_temp_sensor')
    wastewater_temp_sensor_output.setName('wastewater_temp_sensor_output_variable')
    wastewater_temp_sensor_output.setTypeOfDataInVariable('Averaged')
    wastewater_temp_sensor_output.setUpdateFrequency('SystemTimestep')
    wastewater_temp_sensor_output.setEMSProgramOrSubroutineName(wastewater_program)
    wastewater_temp_sensor_output = OpenStudio::Model::OutputVariable.new('wastewater_temp_sensor_output_variable', model)
    wastewater_temp_sensor_output.setReportingFrequency ('timestep')

    wastewater_massflow_sensor_output = OpenStudio::Model::EnergyManagementSystemOutputVariable.new(model, 'wastewater_massflow_sensor')
    wastewater_massflow_sensor_output.setName('wastewater_massflow_sensor_output_variable')
    wastewater_massflow_sensor_output.setTypeOfDataInVariable('Averaged')
    wastewater_massflow_sensor_output.setUpdateFrequency('SystemTimestep')
    wastewater_massflow_sensor_output.setEMSProgramOrSubroutineName(wastewater_program)
    wastewater_massflow_sensor_output = OpenStudio::Model::OutputVariable.new('wastewater_massflow_sensor_output_variable', model)
    wastewater_massflow_sensor_output.setReportingFrequency ('timestep')

    return true
  end
end

# this allows the measure to be used by the application
MultifamilyCentralWasteWaterHeatPump.new.registerWithApplication
