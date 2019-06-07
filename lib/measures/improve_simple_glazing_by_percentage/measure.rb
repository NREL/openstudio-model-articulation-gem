# see the URL below for information on how to write OpenStudio measures
# http://nrel.github.io/OpenStudio-user-documentation/reference/measure_writing_guide/

# start the measure
class ImproveSimpleGlazingByPercentage < OpenStudio::Ruleset::ModelUserScript

  # human readable name
  def name
    return "improve_simple_glazing_by_percentage"
  end

  # define the arguments that the user will input
  def arguments(model)
    args = OpenStudio::Ruleset::OSArgumentVector.new

    # make an argument for glazing u_value improvement percentage
    u_value_improvement_percent = OpenStudio::Ruleset::OSArgument.makeDoubleArgument("u_value_improvement_percent", true)
    u_value_improvement_percent.setDisplayName("U-value Improvement Percentage (%)")
	u_value_improvement_percent.setDefaultValue(20)
    args << u_value_improvement_percent
	
	# make an argument for glazing shgc improvement percentage
    shgc_improvement_percent = OpenStudio::Ruleset::OSArgument.makeDoubleArgument("shgc_improvement_percent", true)
    shgc_improvement_percent.setDisplayName("SHGC improvement Percentage (%)")
	shgc_improvement_percent.setDefaultValue(20)
    args << shgc_improvement_percent

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
    u_value_improvement_percent = runner.getDoubleArgumentValue("u_value_improvement_percent",user_arguments)
	shgc_improvement_percent = runner.getDoubleArgumentValue("shgc_improvement_percent",user_arguments)

	# replace simple glazing window parameters
	materials = model.getMaterials
	materials.each do |material|
	  if material.to_SimpleGlazing.is_initialized
		material_type_glazingsimple = material.to_SimpleGlazing.get
		
		# get the original value for reporting
		u_value_old = nil
		shgc_old = nil
		u_value_old = material_type_glazingsimple.uFactor
		shgc_old = material_type_glazingsimple.solarHeatGainCoefficient

		# Update the values from user input
		material_type_glazingsimple.setUFactor(material_type_glazingsimple.uFactor - material_type_glazingsimple.uFactor * u_value_improvement_percent * 0.01)
		shgc_new = material_type_glazingsimple.setSolarHeatGainCoefficient(material_type_glazingsimple.solarHeatGainCoefficient - material_type_glazingsimple.solarHeatGainCoefficient * shgc_improvement_percent * 0.01)

		# get the updated value for reporting
		u_value_new = nil
		shgc_new = nil
		u_value_new = material_type_glazingsimple.uFactor
		shgc_new = material_type_glazingsimple.solarHeatGainCoefficient
		
		# report initial condition of model
		runner.registerInitialCondition("The building started with #{u_value_old} U-value, #{shgc_old} SHGC.")

		# report final condition of model
		runner.registerFinalCondition("The building finished with #{u_value_new} U-value, #{shgc_new} SHGC.")
		
	  end
	
	end

    return true

  end
  
end

# register the measure to be used by the application
ImproveSimpleGlazingByPercentage.new.registerWithApplication
