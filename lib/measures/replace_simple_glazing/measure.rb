# see the URL below for information on how to write OpenStudio measures
# http://nrel.github.io/OpenStudio-user-documentation/reference/measure_writing_guide/

# start the measure
class ReplaceSimpleGlazing < OpenStudio::Ruleset::ModelUserScript

  # human readable name
  def name
    return "replace_simple_glazing"
  end

  # define the arguments that the user will input
  def arguments(model)
    args = OpenStudio::Ruleset::OSArgumentVector.new

    # glazing u_value
    u_value = OpenStudio::Ruleset::OSArgument.makeDoubleArgument("u_value", true)
    u_value.setDisplayName("U-value in W/(K-m2)")
	u_value.setDefaultValue(1.65)
    args << u_value
	
	# glazing shgc
    shgc = OpenStudio::Ruleset::OSArgument.makeDoubleArgument("shgc", true)
    shgc.setDisplayName("shgc")
	shgc.setDefaultValue(0.20)
    args << shgc
	
	# glazing visible transmittance
    vt = OpenStudio::Ruleset::OSArgument.makeDoubleArgument("vt", true)
    vt.setDisplayName("vt")
	vt.setDefaultValue(0.81)
    args << vt

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
    u_value = runner.getDoubleArgumentValue("u_value",user_arguments)
	shgc = runner.getDoubleArgumentValue("shgc",user_arguments)
	vt = runner.getDoubleArgumentValue("vt",user_arguments)

	# replace simple glazing window parameters
	materials = model.getMaterials
	materials.each do |material|
	  if material.to_SimpleGlazing.is_initialized
		material_type_glazingsimple = material.to_SimpleGlazing.get
		
		# get the original value for reporting
		u_value_old = nil
		shgc_old = nil
		vt_old = nil
		
		u_value_old = material_type_glazingsimple.uFactor
		shgc_old = material_type_glazingsimple.solarHeatGainCoefficient
		vt_old = material_type_glazingsimple.visibleTransmittance
		
		# set values with user inputs
		material_type_glazingsimple.setUFactor(u_value)
		material_type_glazingsimple.setSolarHeatGainCoefficient(shgc)
		material_type_glazingsimple.setVisibleTransmittance(vt)
		
		# report initial condition of model
		runner.registerInitialCondition("The building started with #{u_value_old} U-value, #{shgc_old} SHGC, #{vt_old} Visible Transmittance.")

		# report final condition of model
		runner.registerFinalCondition("The building finished with #{u_value} U-value, #{shgc} SHGC, #{vt} Visible Transmittance.")
		
	  end
	
	end

    return true

  end
  
end

# register the measure to be used by the application
ReplaceSimpleGlazing.new.registerWithApplication
