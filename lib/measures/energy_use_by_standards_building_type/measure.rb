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

# start the measure
class EnergyUseByStandardsBuildingType < OpenStudio::Measure::ReportingMeasure
  # human readable name
  def name
    return 'Energy Use By Standards Building Type'
  end

  # human readable description
  def description
    return 'This measure reports the energy use of different parts of the building by standards building type.'
  end

  # human readable description of modeling approach
  def modeler_description
    return 'This reporting measure may take a while to run to collect all zone variables, especially on larger models.  Energy use for HVAC equipment is attributed to standards building type by zone equipment.'
  end

  # define the arguments that the user will input
  def arguments(model = nil)
    args = OpenStudio::Measure::OSArgumentVector.new

    return args
  end

  # return a vector of IdfObject's to request EnergyPlus objects needed by the run method
  def energyPlusOutputRequests(runner, user_arguments)
    super(runner, user_arguments)

    # use the built-in error checking
    if !runner.validateUserArguments(arguments, user_arguments)
      return false
    end

    result = OpenStudio::IdfObjectVector.new

    # # get the last model and sql file
    # model = runner.lastOpenStudioModel
    # if model.empty?
    #   runner.registerError('Cannot find last model.')
    #   return false
    # end
    # model = model.get

    # request zone lights and equipment energy
    result << OpenStudio::IdfObject.load('Output:Variable,*,Zone Lights Electric Energy,annual;').get # J
    result << OpenStudio::IdfObject.load('Output:Variable,*,Zone Electric Equipment Electric Energy,annual;').get # J
    result << OpenStudio::IdfObject.load('Output:Variable,*,Zone Gas Equipment Gas Energy,annual;').get # J

    # request exterior lights and equipment energy
    result << OpenStudio::IdfObject.load('Output:Variable,*,Exterior Lights Electric Energy,annual;').get # J
    result << OpenStudio::IdfObject.load('Output:Variable,*,Exterior Equipment Electric Energy,annual;').get # J
    result << OpenStudio::IdfObject.load('Output:Variable,*,Exterior Equipment Gas Energy,annual;').get # J

    # request service water heating use
    result << OpenStudio::IdfObject.load('Output:Variable,*,Water Use Connections Hot Water Volume,annual;').get
    result << OpenStudio::IdfObject.load('Output:Variable,*,Water Use Connections Hot Water Temperature,annual;').get
    result << OpenStudio::IdfObject.load('Output:Variable,*,Water to Water Heat Pump Electric Energy,annual;').get
    result << OpenStudio::IdfObject.load('Output:Variable,*,Water to Water Heat Pump Load Side Heat Transfer Energy,annual;').get

    # request pipe heat loss
    result << OpenStudio::IdfObject.load('Output:Variable,*,Pipe Fluid Heat Transfer Energy,annual;').get

    # request coil and fan energy use for HVAC equipment
    result << OpenStudio::IdfObject.load('Output:Variable,*,Fan Electric Energy,annual;').get # J
    result << OpenStudio::IdfObject.load('Output:Variable,*,Heating Coil Electric Energy,annual;').get # J
    result << OpenStudio::IdfObject.load('Output:Variable,*,Heating Coil Gas Energy,annual;').get # J
    result << OpenStudio::IdfObject.load('Output:Variable,*,Cooling Coil Electric Energy,annual;').get # J
    result << OpenStudio::IdfObject.load('Output:Variable,*,Heating Coil Heating Energy,annual;').get # J
    result << OpenStudio::IdfObject.load('Output:Variable,*,Coil Cooling Total Cooling Energy,annual;').get # J
    result << OpenStudio::IdfObject.load('Output:Variable,*,Humidifier Electric Energy,annual;').get # J
    result << OpenStudio::IdfObject.load('Output:Variable,*,Evaporative Cooler Electric Energy,annual;').get # J
    result << OpenStudio::IdfObject.load('Output:Variable,*,Baseboard Hot Water Energy,annual;').get # J
    result << OpenStudio::IdfObject.load('Output:Variable,*,Baseboard Electric Energy,annual;').get # J

    return result
  end

  # define what happens when the measure is run
  def run(runner, user_arguments)
    super(runner, user_arguments)

    # use the built-in error checking
    if !runner.validateUserArguments(arguments, user_arguments)
      return false
    end

    # get the last model and sql file
    model = runner.lastOpenStudioModel
    if model.empty?
      runner.registerError('Cannot find last model.')
      return false
    end
    model = model.get

    sql = runner.lastEnergyPlusSqlFile
    if sql.empty?
      runner.registerError('Cannot find last sql file.')
      return false
    end
    sql = sql.get
    model.setSqlFile(sql)

    # Get the weather file run period (as opposed to design day run period)
    ann_env_pd = nil
    sql.availableEnvPeriods.each do |env_pd|
      env_type = sql.environmentType(env_pd)
      if env_type.is_initialized
        if env_type.get == OpenStudio::EnvironmentType.new('WeatherRunPeriod')
          ann_env_pd = env_pd
        end
      end
    end

    if ann_env_pd == false
      runner.registerError('Cannot find a weather runperiod. Make sure you ran an annual simulation, not just the design days.')
      return false
    end

    # get openstudio-standards building type
    stds_bldg_types = []
    model.getSpaces.sort.each do |space|
      unless space.spaceType.empty?
        unless space.spaceType.get.standardsBuildingType.empty?
          stds_bldg_type = space.spaceType.get.standardsBuildingType.get
          stds_bldg_types << stds_bldg_type unless stds_bldg_types.include? stds_bldg_type
        end
      end
    end

    if stds_bldg_types.empty?
      runner.registerError('Cannot find standards building types in the model.')
      return false
    end

    if stds_bldg_types.size == 1
      runner.registerAsNotApplicable('The model only has one standards building type. Energy use cannot be split out.')
      return false
    end

    runner.registerInitialCondition("The model has #{stds_bldg_types.size} standards building types")

    # initialize results array
    # energy results in joules
    mixed_building_results = {}
    stds_bldg_types.each do |bldg_type|
      mixed_building_results[bldg_type] = {}
      mixed_building_results[bldg_type][:heating] = 0
      mixed_building_results[bldg_type][:cooling] = 0
      mixed_building_results[bldg_type][:interior_lighting] = 0
      mixed_building_results[bldg_type][:exterior_lighting] = 0
      mixed_building_results[bldg_type][:interior_equipment] = 0
      mixed_building_results[bldg_type][:exterior_equipment] = 0
      mixed_building_results[bldg_type][:fans] = 0
      mixed_building_results[bldg_type][:pumps] = 0
      mixed_building_results[bldg_type][:heat_rejection] = 0
      mixed_building_results[bldg_type][:humidification] = 0
      mixed_building_results[bldg_type][:heat_recovery] = 0
      mixed_building_results[bldg_type][:water_systems] = 0
      mixed_building_results[bldg_type][:refrigeration] = 0
      mixed_building_results[bldg_type][:total_end_uses] = 0
      mixed_building_results[bldg_type][:floor_area] = 0
      mixed_building_results[bldg_type][:hot_water_volume] = 0
    end

    # get zone information
    model.getThermalZones.sort.each do |zone|
      # check standards building type
      zone_std_bldg_types = {}
      zone.spaces.each do |space|
        # skip spaces with no standards space type
        next if space.spaceType.empty?
        next if space.spaceType.get.standardsBuildingType.empty?
        zone_std_bldg_type = space.spaceType.get.standardsBuildingType.get
        if zone_std_bldg_types[zone_std_bldg_type].nil?
          zone_std_bldg_types[zone_std_bldg_type] = space.floorArea
        else
          zone_std_bldg_types[zone_std_bldg_type] += space.floorArea
        end
      end

      # check that there is at least one standards building type
      if zone_std_bldg_types.empty?
        runner.registerInfo("Zone #{zone.name} does not have spaces with a standards building type defined.")
        next
      end

      # sort by floor area
      zone_std_bldg_types = zone_std_bldg_types.sort_by { |type, area| area }

      # set the zones standards building type by largest floor area and warn if multiple
      if zone_std_bldg_types.size > 1
        runner.registerWarning("Zone #{zone.name} contains spaces with different standards building types. Using largest zone by floor area.")
        zone_std_bldg_type = zone_std_bldg_types[-1][0]
      else
        zone_std_bldg_type = zone_std_bldg_types[0][0]
      end

      # log floor area
      mixed_building_results[zone_std_bldg_type][:floor_area] += zone.floorArea

      # get zone lighting
      var_data_id_query = "SELECT ReportVariableDataDictionaryIndex FROM ReportVariableDataDictionary WHERE VariableName = 'Zone Lights Electric Energy' AND ReportingFrequency = 'Annual' AND KeyValue = '#{zone.name.get.to_s.upcase}'"
      var_data_id = sql.execAndReturnFirstDouble(var_data_id_query)
      if var_data_id.is_initialized
        var_val_query = "SELECT VariableValue FROM ReportVariableData WHERE ReportVariableDataDictionaryIndex = '#{var_data_id.get}'"
        val = sql.execAndReturnFirstDouble(var_val_query)
        if val.is_initialized
          mixed_building_results[zone_std_bldg_type][:interior_lighting] += val.get
        else
          runner.registerWarning("'Zone Lights Electric Energy' not available for zone '#{zone.name}' with standards building type #{zone_std_bldg_type}.")
        end
      else
        runner.registerWarning("'Zone Lights Electric Energy' not available for zone '#{zone.name}' with standards building type #{zone_std_bldg_type}.")
      end

      # get zone electric equipment
      var_data_id_query = "SELECT ReportVariableDataDictionaryIndex FROM ReportVariableDataDictionary WHERE VariableName = 'Zone Electric Equipment Electric Energy' AND ReportingFrequency = 'Annual' AND KeyValue = '#{zone.name.get.to_s.upcase}'"
      var_data_id = sql.execAndReturnFirstDouble(var_data_id_query)
      if var_data_id.is_initialized
        var_val_query = "SELECT VariableValue FROM ReportVariableData WHERE ReportVariableDataDictionaryIndex = '#{var_data_id.get}'"
        val = sql.execAndReturnFirstDouble(var_val_query)
        if val.is_initialized
          mixed_building_results[zone_std_bldg_type][:interior_equipment] += val.get
        else
          runner.registerWarning("'Zone Electric Equipment Electric Energy' not available for zone '#{zone.name}' with standards building type #{zone_std_bldg_type}.")
        end
      else
        runner.registerWarning("'Zone Electric Equipment Electric Energy' not available for zone '#{zone.name}' with standards building type #{zone_std_bldg_type}.")
      end

      # get zone gas equipment
      var_data_id_query = "SELECT ReportVariableDataDictionaryIndex FROM ReportVariableDataDictionary WHERE VariableName = 'Zone Gas Equipment Gas Energy' AND ReportingFrequency = 'Annual' AND KeyValue = '#{zone.name.get.to_s.upcase}'"
      var_data_id = sql.execAndReturnFirstDouble(var_data_id_query)
      if var_data_id.is_initialized
        var_val_query = "SELECT VariableValue FROM ReportVariableData WHERE ReportVariableDataDictionaryIndex = '#{var_data_id.get}'"
        val = sql.execAndReturnFirstDouble(var_val_query)
        if val.is_initialized
        mixed_building_results[zone_std_bldg_type][:interior_equipment] += val.get
        else
          runner.registerWarning("'Zone Gas Equipment Gas Energy' not available for zone '#{zone.name}' with standards building type #{zone_std_bldg_type}.")
        end
      else
        runner.registerWarning("'Zone Gas Equipment Gas Energy' not available for zone '#{zone.name}' with standards building type #{zone_std_bldg_type}.")
      end

      # water use equipment
      zone_hot_water_volume_m3 = 0
      zone.spaces.each do |space|
        water_use_equipments = space.waterUseEquipment
        water_use_equipments.each do |water_use_equipment|
          water_use_connection = water_use_equipment.waterUseConnections
          if water_use_connection.is_initialized
            water_use_connection = water_use_connection.get
            var_data_id_query = "SELECT ReportVariableDataDictionaryIndex FROM ReportVariableDataDictionary WHERE VariableName = 'Water Use Connections Hot Water Volume' AND ReportingFrequency = 'Annual' AND KeyValue = '#{water_use_connection.name.get.to_s.upcase}'"
            var_data_id = sql.execAndReturnFirstDouble(var_data_id_query)
            if var_data_id.is_initialized
              var_val_query = "SELECT VariableValue FROM ReportVariableData WHERE ReportVariableDataDictionaryIndex = '#{var_data_id.get}'"
              zone_hot_water_volume_m3 += sql.execAndReturnFirstDouble(var_val_query).get
            else
              runner.registerWarning("'Water Use Connections Hot Water Volume' not available for water use connection #{water_use_connection.name} in zone '#{zone.name}' with standards building type #{zone_std_bldg_type}.")
            end
          end
        end
      end
      mixed_building_results[zone_std_bldg_type][:hot_water_volume] = zone_hot_water_volume_m3
    end

    # water to to water heat pump equipment
    sum_wwhp_energy_j = 0.0
    sum_wwhp_load_j = 0.0
    wwhp_cop = 0.0
    model.getHeatPumpWaterToWaterEquationFitHeatings.each do |wwhp|
      var_data_id_query = "SELECT ReportVariableDataDictionaryIndex FROM ReportVariableDataDictionary WHERE VariableName = 'Water to Water Heat Pump Electric Energy' AND ReportingFrequency = 'Annual' AND KeyValue = '#{wwhp.name.get.to_s.upcase}'"
      var_data_id = sql.execAndReturnFirstDouble(var_data_id_query)
      if var_data_id.is_initialized
        var_val_query = "SELECT VariableValue FROM ReportVariableData WHERE ReportVariableDataDictionaryIndex = '#{var_data_id.get}'"
        val = sql.execAndReturnFirstDouble(var_val_query)
        if val.is_initialized
          wwhp_energy_j = sql.execAndReturnFirstDouble(var_val_query).get
          sum_wwhp_energy_j += wwhp_energy_j
        else
          runner.registerWarning("'Water to Water Heat Pump Electric Energy' not available for water to water heat pump #{wwhp.name}.")
        end
      else
        runner.registerWarning("'Water to Water Heat Pump Electric Energy' not available for water to water heat pump #{wwhp.name}.")
      end

      var_data_id_query = "SELECT ReportVariableDataDictionaryIndex FROM ReportVariableDataDictionary WHERE VariableName = 'Water to Water Heat Pump Load Side Heat Transfer Energy' AND ReportingFrequency = 'Annual' AND KeyValue = '#{wwhp.name.get.to_s.upcase}'"
      var_data_id = sql.execAndReturnFirstDouble(var_data_id_query)
      if var_data_id.is_initialized
        var_val_query = "SELECT VariableValue FROM ReportVariableData WHERE ReportVariableDataDictionaryIndex = '#{var_data_id.get}'"
        val = sql.execAndReturnFirstDouble(var_val_query)
        if val.is_initialized
          wwhp_load_energy_j = sql.execAndReturnFirstDouble(var_val_query).get
          sum_wwhp_load_j += wwhp_load_energy_j
        else
          runner.registerWarning("'Water to Water Heat Pump Load Side Heat Transfer Energy' not available for water to water heat pump #{wwhp.name}.")
        end
      else
        runner.registerWarning("'Water to Water Heat Pump Load Side Heat Transfer Energy' not available for water to water heat pump #{wwhp.name}.")
      end

      if (sum_wwhp_energy_j > 0) && (sum_wwhp_load_j > 0)
        wwhp_cop = sum_wwhp_load_j / sum_wwhp_energy_j
      else
        runner.registerWarning("Not able to calculate annual cop for water to water heat pump #{wwhp.name}.")
      end
    end
    if sum_wwhp_energy_j > 0
      runner.registerValue('water_to_water_heat_pump_electric_energy_gj', sum_wwhp_energy_j/1e9, 'GJ')
    end
    if sum_wwhp_load_j > 0
      runner.registerValue('water_to_water_heat_pump_load_energy_gj', sum_wwhp_load_j/1e9, 'GJ')
    end
    if wwhp_cop > 0
      runner.registerValue('water_to_water_heat_pump_annual_cop', wwhp_cop)
    end

    # pipe heat loss
    sum_pipe_loss_energy_j = 0.0
    model.getPipeIndoors.each do |pipe|
      var_data_id_query = "SELECT ReportVariableDataDictionaryIndex FROM ReportVariableDataDictionary WHERE VariableName = 'Pipe Fluid Heat Transfer Energy' AND ReportingFrequency = 'Annual' AND KeyValue = '#{pipe.name.get.to_s.upcase}'"
      var_data_id = sql.execAndReturnFirstDouble(var_data_id_query)
      if var_data_id.is_initialized
        var_val_query = "SELECT VariableValue FROM ReportVariableData WHERE ReportVariableDataDictionaryIndex = '#{var_data_id.get}'"
        val = sql.execAndReturnFirstDouble(var_val_query)
        if val.is_initialized
          pipe_loss_energy_j = sql.execAndReturnFirstDouble(var_val_query).get
          sum_pipe_loss_energy_j += pipe_loss_energy_j
        else
          runner.registerWarning("'Pipe Fluid Heat Transfer Energy' not available for water to water heat pump #{pipe.name}.")
        end
      else
        runner.registerWarning("'Pipe Fluid Heat Transfer Energy' not available for water to water heat pump #{pipe.name}.")
      end
    end
    runner.registerValue('pipe_heat_loss_gj', sum_pipe_loss_energy_j/1e9, 'GJ')

    # elevator energy use
    var_val_query = "SELECT Value FROM TabularDataWithStrings WHERE ReportName = 'EnergyMeters' AND RowName = 'Elevators:InteriorEquipment:Electricity' AND ColumnName = 'Electricity Annual Value' AND Units = 'GJ'"
    val = sql.execAndReturnFirstDouble(var_val_query)
    if val.is_initialized
      elevator_energy_use_gj = sql.execAndReturnFirstDouble(var_val_query).get
      runner.registerValue('elevator_energy_use_gj', elevator_energy_use_gj, 'GJ')
    else
      runner.registerWarning("Annual elevator energy use not available.")
    end

    # close the sql file
    sql.close

    # report out logged parameters as register values
    stds_bldg_types.each do |bldg_type|
      # report out floor area and end uses
      mixed_building_results[bldg_type].keys.each do |key|
        if mixed_building_results[bldg_type][key] > 0
          key_name = "#{bldg_type.downcase}_#{key}".gsub(':','').gsub(' ','')
          if key == :floor_area
            key_name += '_m2'
            runner.registerValue(key_name, mixed_building_results[bldg_type][key], 'm2')
          elsif key == :hot_water_volume
            key_name += '_m3'
            runner.registerValue(key_name, mixed_building_results[bldg_type][key], 'm3')
          else
            key_name += '_gj'
            mixed_building_results[bldg_type][:total_end_uses] += mixed_building_results[bldg_type][key]
            runner.registerValue(key_name, mixed_building_results[bldg_type][key]/1e9, 'GJ')
          end
        end
      end

      # report out total end uses
      key_name = "#{bldg_type.downcase}_#{:total_end_uses}_gj".gsub(':','').gsub(' ','')
      total_end_uses_gj = mixed_building_results[bldg_type][:total_end_uses]/1e9
      runner.registerValue(key_name, total_end_uses_gj, 'GJ')

      # report out total EUI
      floor_area_m2 = mixed_building_results[bldg_type][:floor_area]
      floor_area_ft2 = OpenStudio.convert(floor_area_m2, 'm^2', 'ft^2').get
      total_end_uses_kbtu = OpenStudio.convert(total_end_uses_gj, 'GJ', 'kBtu').get
      total_eui_kbtu_sf = total_end_uses_kbtu / floor_area_ft2
      key_name = "#{bldg_type.downcase}_total_eui_kbtu_per_ft2".gsub(' ','')
      runner.registerValue(key_name, total_eui_kbtu_sf, 'kBtu/ft^2')
    end

    return true
  end
end

# register the measure to be used by the application
EnergyUseByStandardsBuildingType.new.registerWithApplication
