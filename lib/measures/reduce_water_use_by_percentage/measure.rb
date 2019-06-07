# see the URL below for information on how to write OpenStudio measures
# http://nrel.github.io/OpenStudio-user-documentation/reference/measure_writing_guide/

# start the measure
class ReduceWaterUseByPercentage < OpenStudio::Ruleset::ModelUserScript

  # human readable name
  def name
    return "reduce_water_use_by_percentage"
  end

  # define the arguments that the user will input
  def arguments(model)
    args = OpenStudio::Ruleset::OSArgumentVector.new

    # make an argument for water use reduction percentage
    water_use_reduction_percent = OpenStudio::Ruleset::OSArgument.makeDoubleArgument("water_use_reduction_percent", true)
    water_use_reduction_percent.setDisplayName("Water Use Reduction Percentage (%)")
	water_use_reduction_percent.setDefaultValue(20)
    args << water_use_reduction_percent

    return args
  end

  # define what happens when the measure is run
  def run(model, runner, user_arguments)	
    super(model, runner, user_arguments)

    # use the built-in error checking
    if !runner.validateUserArguments(arguments(model), user_arguments)
      return false
    end

	#assign the user inputs to variables
    water_use_reduction_percent = runner.getDoubleArgumentValue("water_use_reduction_percent",user_arguments)

	# replace water use parameters
	model.getWaterUseEquipments.each do |water_use_equipment|
	  
	  # get the original value for reporting
	  peak_flow_rate_si_old = water_use_equipment.waterUseEquipmentDefinition.peakFlowRate # m^3/s
	  
	  # Update the values from user input
	  water_use_equipment.waterUseEquipmentDefinition.setPeakFlowRate(water_use_equipment.waterUseEquipmentDefinition.peakFlowRate - water_use_equipment.waterUseEquipmentDefinition.peakFlowRate * water_use_reduction_percent * 0.01)
	  
	  # get the updated value for reporting
	  peak_flow_rate_si_new = water_use_equipment.waterUseEquipmentDefinition.peakFlowRate # m^3/s
		
	  # report initial condition of model
	  runner.registerInitialCondition("Peak flow rate is #{peak_flow_rate_si_old} m^3/s..")

      # report final condition of model
	  runner.registerFinalCondition("Peak flow rate is #{peak_flow_rate_si_new} m^3/s.")
	
	end

    return true

  end
  
end

# register the measure to be used by the application
ReduceWaterUseByPercentage.new.registerWithApplication
