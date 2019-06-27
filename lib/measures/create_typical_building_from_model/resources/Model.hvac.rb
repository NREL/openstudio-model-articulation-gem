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

class OpenStudio::Model::Model
  # Adds the HVAC system as derived from the combinations of
  # CBECS 2012 MAINHT and MAINCL fields.
  # Mapping between combinations and HVAC systems per
  # http://www.nrel.gov/docs/fy08osti/41956.pdf
  # Table C-31
  def add_cbecs_hvac_system(standard, system_type, zones)
    # the 'zones' argument includes zones that have heating, cooling, or both
    # if the HVAC system type serves a single zone, handle zones with only heating separately by adding unit heaters
    # applies to system types PTAC, PTHP, PSZ-AC, and Window AC
    heated_and_cooled_zones = zones.select { |zone| standard.thermal_zone_heated?(zone) && standard.thermal_zone_cooled?(zone) }
    heated_zones = zones.select { |zone| standard.thermal_zone_heated?(zone) }
    cooled_zones = zones.select { |zone| standard.thermal_zone_cooled?(zone) }
    cooled_only_zones = zones.select { |zone| !standard.thermal_zone_heated?(zone) && standard.thermal_zone_cooled?(zone) }
    heated_only_zones = zones.select { |zone| standard.thermal_zone_heated?(zone) && !standard.thermal_zone_cooled?(zone) }
    system_zones = heated_and_cooled_zones + cooled_only_zones

    case system_type
    when 'PTAC with hot water heat'
      standard.model_add_hvac_system(self, 'PTAC', ht = 'NaturalGas', znht = nil, cl = 'Electricity', system_zones)
      # use 'Baseboard hot water heat' for heated only zones
      standard.model_add_hvac_system(self, 'Baseboards', ht = 'NaturalGas', znht = nil, cl = nil, heated_only_zones)

    when 'PTAC with gas coil heat'
      standard.model_add_hvac_system(self, 'PTAC', ht = nil, znht = 'NaturalGas', cl = 'Electricity', system_zones)
      # use 'Baseboard electric heat' for heated only zones
      standard.model_add_hvac_system(self, 'Baseboards', ht = 'Electricity', znht = nil, cl = nil, heated_only_zones)

    when 'PTAC with electric baseboard heat'
      standard.model_add_hvac_system(self, 'PTAC', ht = nil, znht = nil, cl = 'Electricity', system_zones)
      standard.model_add_hvac_system(self, 'Baseboards', ht = 'Electricity', znht = nil, cl = nil, heated_zones)

    when 'PTAC with no heat'
      standard.model_add_hvac_system(self, 'PTAC', ht = nil, znht = nil, cl = 'Electricity', system_zones)

    when 'PTAC with district hot water heat'
      standard.model_add_hvac_system(self, 'PTAC', ht = 'DistrictHeating', znht = nil, cl = 'Electricity', system_zones)
      # use 'Baseboard district hot water heat' for heated only zones
      standard.model_add_hvac_system(self, 'Baseboards', ht = 'DistrictHeating', znht = nil, cl = nil, heated_only_zones)

    when 'PTHP'
      standard.model_add_hvac_system(self, 'PTHP', ht = 'Electricity', znht = nil, cl = 'Electricity', system_zones)
      # use 'Baseboard electric heat' for heated only zones
      standard.model_add_hvac_system(self, 'Baseboards', ht = 'Electricity', znht = nil, cl = nil, heated_only_zones)

    when 'PSZ-AC with gas coil heat'
      standard.model_add_hvac_system(self, 'PSZ-AC', ht = 'NaturalGas', znht = nil, cl = 'Electricity', system_zones)
      # use 'Baseboard electric heat' for heated only zones
      standard.model_add_hvac_system(self, 'Baseboards', ht = 'Electricity', znht = nil, cl = nil, heated_only_zones)

    when 'PSZ-AC with electric baseboard heat'
      standard.model_add_hvac_system(self, 'PSZ-AC', ht = nil, znht = nil, cl = 'Electricity', system_zones)
      standard.model_add_hvac_system(self, 'Baseboards', ht = 'Electricity', znht = nil, cl = nil, heated_zones)

    when 'PSZ-AC with no heat'
      standard.model_add_hvac_system(self, 'PSZ-AC', ht = nil, znht = nil, cl = 'Electricity', cooled_zones)

    when 'PSZ-AC with district hot water heat'
      standard.model_add_hvac_system(self, 'PSZ-AC', ht = 'DistrictHeating', znht = nil, cl = 'Electricity', system_zones)
      # use 'Baseboard district hot water heat' for heated only zones
      standard.model_add_hvac_system(self, 'Baseboards', ht = 'DistrictHeating', znht = nil, cl = nil, heated_only_zones)

    when 'PSZ-HP'
      standard.model_add_hvac_system(self, 'PSZ-HP', ht = 'Electricity', znht = nil, cl = 'Electricity', system_zones)
      # use 'Baseboard electric heat' for heated only zones
      standard.model_add_hvac_system(self, 'Baseboards', ht = 'Electricity', znht = nil, cl = nil, heated_only_zones)

    when 'Fan coil district chilled water with no heat'
      standard.model_add_hvac_system(self, 'Fan Coil', ht = nil, znht = nil, cl = 'DistrictCooling', zones)

    when 'Fan coil district chilled water and boiler'
      standard.model_add_hvac_system(self, 'Fan Coil', ht = 'NaturalGas', znht = nil, cl = 'DistrictCooling', zones)

    when 'Fan coil district chilled water unit heaters'
      standard.model_add_hvac_system(self, 'Fan Coil', ht = nil, znht = nil, cl = 'DistrictCooling', zones)
      standard.model_add_hvac_system(self, 'Unit Heaters', ht = 'NaturalGas', znht = nil, cl = nil, heated_zones)

    when 'Fan coil district chilled water electric baseboard heat'
      standard.model_add_hvac_system(self, 'Fan Coil', ht = nil, znht = nil, cl = 'DistrictCooling', zones)
      standard.model_add_hvac_system(self, 'Baseboards', ht = 'Electricity', znht = nil, cl = nil, heated_zones)

    when 'Fan coil district hot and chilled water'
      standard.model_add_hvac_system(self, 'Fan Coil', ht = 'DistrictHeating', znht = nil, cl = 'DistrictCooling', zones)

    when 'Fan coil district hot water and chiller'
      standard.model_add_hvac_system(self, 'Fan Coil', ht = 'DistrictHeating', znht = nil, cl = 'Electricity', zones)

    when 'Fan coil chiller with no heat'
      standard.model_add_hvac_system(self, 'Fan Coil', ht = nil, znht = nil, cl = 'Electricity', zones)

    when 'Baseboard district hot water heat'
      standard.model_add_hvac_system(self, 'Baseboards', ht = 'DistrictHeating', znht = nil, cl = nil, heated_zones)

    when 'Baseboard district hot water heat with direct evap coolers'
      standard.model_add_hvac_system(self, 'Baseboards', ht = 'DistrictHeating', znht = nil, cl = nil, heated_zones)
      standard.model_add_hvac_system(self, 'Evaporative Cooler', ht = nil, znht = nil, cl = 'Electricity', cooled_zones)

    when 'Baseboard electric heat'
      standard.model_add_hvac_system(self, 'Baseboards', ht = 'Electricity', znht = nil, cl = nil, heated_zones)

    when 'Baseboard electric heat with direct evap coolers'
      standard.model_add_hvac_system(self, 'Baseboards', ht = 'Electricity', znht = nil, cl = nil, heated_zones)
      standard.model_add_hvac_system(self, 'Evaporative Cooler', ht = nil, znht = nil, cl = 'Electricity', cooled_zones)

    when 'Baseboard hot water heat'
      standard.model_add_hvac_system(self, 'Baseboards', ht = 'NaturalGas', znht = nil, cl = nil, heated_zones)

    when 'Baseboard hot water heat with direct evap coolers'
      standard.model_add_hvac_system(self, 'Baseboards', ht = 'NaturalGas', znht = nil, cl = nil, heated_zones)
      standard.model_add_hvac_system(self, 'Evaporative Cooler', ht = nil, znht = nil, cl = 'Electricity', cooled_zones)

    when 'Window AC with no heat'
      standard.model_add_hvac_system(self, 'Window AC', ht = nil, znht = nil, cl = 'Electricity', cooled_zones)

    when 'Window AC with forced air furnace'
      standard.model_add_hvac_system(self, 'Window AC', ht = nil, znht = nil, cl = 'Electricity', cooled_zones)
      standard.model_add_hvac_system(self, 'Forced Air Furnace', ht = 'NaturalGas', znht = nil, cl = nil, heated_zones)

    when 'Window AC with district hot water baseboard heat'
      standard.model_add_hvac_system(self, 'Window AC', ht = nil, znht = nil, cl = 'Electricity', cooled_zones)
      standard.model_add_hvac_system(self, 'Baseboards', ht = 'DistrictHeating', znht = nil, cl = nil, heated_zones)

    when 'Window AC with hot water baseboard heat'
      standard.model_add_hvac_system(self, 'Window AC', ht = nil, znht = nil, cl = 'Electricity', cooled_zones)
      standard.model_add_hvac_system(self, 'Baseboards', ht = 'NaturalGas', znht = nil, cl = nil, heated_zones)

    when 'Window AC with electric baseboard heat'
      standard.model_add_hvac_system(self, 'Window AC', ht = nil, znht = nil, cl = 'Electricity', cooled_zones)
      standard.model_add_hvac_system(self, 'Baseboards', ht = 'Electricity', znht = nil, cl = nil, heated_zones)

    when 'Window AC with unit heaters'
      standard.model_add_hvac_system(self, 'Window AC', ht = nil, znht = nil, cl = 'Electricity', cooled_zones)
      standard.model_add_hvac_system(self, 'Unit Heaters', ht = 'NaturalGas', znht = nil, cl = nil, heated_zones)

    when 'Direct evap coolers'
      standard.model_add_hvac_system(self, 'Evaporative Cooler', ht = nil, znht = nil, cl = 'Electricity', cooled_zones)

    when 'Direct evap coolers with unit heaters'
      standard.model_add_hvac_system(self, 'Unit Heaters', ht = 'NaturalGas', znht = nil, cl = nil, heated_zones)
      standard.model_add_hvac_system(self, 'Evaporative Cooler', ht = nil, znht = nil, cl = 'Electricity', cooled_zones)

    when 'Unit heaters'
      standard.model_add_hvac_system(self, 'Unit Heaters', ht = 'NaturalGas', znht = nil, cl = nil, heated_zones)

    when 'Heat pump heat with no cooling'
      standard.model_add_hvac_system(self, 'Residential Air Source Heat Pump', ht = nil, znht = nil, cl = 'Electricity', heated_zones)

    when 'Heat pump heat with direct evap cooler'
      standard.model_add_hvac_system(self, 'Evaporative Cooler', ht = nil, znht = nil, cl = 'Electricity', cooled_zones)
      # standard.model_add_hvac_system(self, 'Residential Air Source Heat Pump', ht=nil, znht=nil, cl='Electricity', zones)
      # Using PTHP to represent zone heat pump for this configuration
      # because only one airloop may be connected to each thermal zone.
      standard.model_add_hvac_system(self, 'PTHP', ht = 'Electricity', znht = nil, cl = 'Electricity', system_zones)
      # disable the cooling coils in all the PTHPs
      getZoneHVACPackagedTerminalHeatPumps.each do |pthp|
        clg_coil = pthp.heatingCoil.to_CoilHeatingDXSingleSpeed.get
        clg_coil.setAvailabilitySchedule(alwaysOffDiscreteSchedule)
      end
      # use 'Baseboard electric heat' for heated only zones
      standard.model_add_hvac_system(self, 'Baseboards', ht = 'Electricity', znht = nil, cl = nil, heated_only_zones)

    when 'VAV with reheat'
      standard.model_add_hvac_system(self, 'VAV Reheat', ht = 'NaturalGas', znht = 'NaturalGas', cl = 'Electricity', zones)

    when 'VAV with PFP boxes'
      standard.model_add_hvac_system(self, 'VAV PFP Boxes', ht = 'NaturalGas', znht = 'NaturalGas', cl = 'Electricity', zones)

    when 'VAV with gas reheat'
      standard.model_add_hvac_system(self, 'VAV Gas Reheat', ht = 'NaturalGas', ht = 'NaturalGas', cl = 'Electricity', zones)

    when 'VAV with zone unit heaters'
      standard.model_add_hvac_system(self, 'VAV No Reheat', ht = 'NaturalGas', znht = nil, cl = 'Electricity', zones)
      standard.model_add_hvac_system(self, 'Unit Heaters', ht = 'NaturalGas', znht = nil, cl = nil, heated_zones)

    when 'VAV with electric baseboard heat'
      standard.model_add_hvac_system(self, 'VAV No Reheat', ht = 'NaturalGas', znht = nil, cl = 'Electricity', zones)
      standard.model_add_hvac_system(self, 'Baseboards', ht = 'Electricity', znht = nil, cl = nil, heated_zones)

    when 'VAV cool with zone heat pump heat'
      standard.model_add_hvac_system(self, 'VAV No Reheat', ht = 'NaturalGas', znht = nil, cl = 'Electricity', zones)
      # standard.model_add_hvac_system(self, 'Residential Air Source Heat Pump', ht=nil, znht=nil, cl='Electricity', zones)
      # Using PTHP to represent zone heat pump for this configuration
      # because only one airloop may be connected to each thermal zone.
      standard.model_add_hvac_system(self, 'PTHP', ht = 'Electricity', znht = nil, cl = 'Electricity', zones)
      # disable the cooling coils in all the PTHPs
      getZoneHVACPackagedTerminalHeatPumps.each do |pthp|
        clg_coil = pthp.heatingCoil.to_CoilHeatingDXSingleSpeed.get
        clg_coil.setAvailabilitySchedule(alwaysOffDiscreteSchedule)
      end

    when 'PVAV with reheat', 'Packaged VAV Air Loop with Boiler' # second enumeration for backwards compatibility with Tenant Star project
      standard.model_add_hvac_system(self, 'PVAV Reheat', ht = 'NaturalGas', znht = 'NaturalGas', cl = 'Electricity', zones)

    when 'PVAV with PFP boxes'
      standard.model_add_hvac_system(self, 'PVAV PFP Boxes', ht = 'Electricity', znht = 'Electricity', cl = 'Electricity', zones)

    when 'Residential forced air'
      standard.model_add_hvac_system(self, 'Residential Forced Air Furnace with AC', ht = 'NaturalGas', znht = nil, cl = nil, zones)
    when 'Residential forced air cooling hot water baseboard heat'
      standard.model_add_hvac_system(self, 'Residential AC', ht = nil, znht = nil, cl = 'Electricity', cooled_zones)
      standard.model_add_hvac_system(self, 'Baseboards', ht = 'NaturalGas', znht = nil, cl = nil, heated_zones)

    when 'Residential forced air with district hot water'
      standard.model_add_hvac_system(self, 'Residential AC', ht = nil, znht = nil, cl = 'Electricity', zones)

    when 'Residential heat pump'
      standard.model_add_hvac_system(self, 'Residential Air Source Heat Pump', ht = 'Electricity', znht = nil, cl = 'Electricity', zones)

    when 'Forced air furnace'
      standard.model_add_hvac_system(self, 'Forced Air Furnace', ht = 'NaturalGas', znht = nil, cl = nil, heated_zones)

    when 'Forced air furnace district chilled water fan coil'
      standard.model_add_hvac_system(self, 'Forced Air Furnace', ht = 'NaturalGas', znht = nil, cl = nil, zones)
      standard.model_add_hvac_system(self, 'Fan Coil', ht = nil, znht = nil, cl = 'DistrictCooling', zones)

    when 'Forced air furnace direct evap cooler'
      # standard.model_add_hvac_system(self, 'Forced Air Furnace', ht='NaturalGas', znht=nil, cl=nil, zones)
      # Using unit heater to represent forced air furnace for this configuration
      # because only one airloop may be connected to each thermal zone.
      standard.model_add_hvac_system(self, 'Unit Heaters', ht = 'NaturalGas', znht = nil, cl = nil, heated_zones)
      standard.model_add_hvac_system(self, 'Evaporative Cooler', ht = nil, znht = nil, cl = 'Electricity', cooled_zones)

    when 'Residential AC with no heat'
      standard.model_add_hvac_system(self, 'Residential AC', ht = nil, znht = nil, cl = 'Electricity', cooled_zones)

    when 'Residential AC with electric baseboard heat'
      standard.model_add_hvac_system(self, 'Residential AC', ht = nil, znht = nil, cl = 'Electricity', cooled_zones)
      standard.model_add_hvac_system(self, 'Baseboards', ht = 'Electricity', znht = nil, cl = nil, heated_zones)

    else
      puts "HVAC system type '#{system_type}' not recognized"

    end
  end
end
