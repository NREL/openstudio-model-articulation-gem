# *******************************************************************************
# OpenStudio(R), Copyright (c) 2008-2021, Alliance for Sustainable Energy, LLC.
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

# insert your copyright here

# Measure written by Gabriel Flechas
# Assitance by Karl Heine (THANKS KARL!)
# Last edit 05/25/2021

# see the URL below for information on how to write OpenStudio measures
# http://nrel.github.io/OpenStudio-user-documentation/reference/measure_writing_guide/

# start the measure
class AddEMPDMaterialProperties < OpenStudio::Measure::ModelMeasure
  # human readable name
  def name
    # Measure name should be the title case of the class name.
    return 'Add EMPD Material Properties'
  end

  # human readable description
  def description
    return 'Adds the properties for the effective moisture penetration depth (EMPD) Heat Balance Model with inputs for penetration depths.'
  end

  # human readable description of modeling approach
  def modeler_description
    return %W[
			Adds the properties for the "MoisturePenetrationDepthConductionTransferFunction" or effective 
			moisture penetration depth (EMPD) Heat Balance Model with inputs for penetration depths. \n\n
			Leaving "Change heat balance algorithm?" blank will use the current OpenStudio heat balance algorithm setting. \n\n
			At least 1 interior material needs to have moisture penetration depth properties set 
			to use the EMPD heat balance algorithm.
			].join(' ')
  end

  # define the arguments that the user will input
  def arguments(model)
    args = OpenStudio::Measure::OSArgumentVector.new

    # find the available materials
    list_materials = model.getMaterials
    mat_names = Array.new()
    list_materials.each do |v|
      mat_names.append(v.name.to_s)
    end
    mat_names.sort!

    # Create arguments for material selection (Choice)
    selected_material = OpenStudio::Measure::OSArgument.makeChoiceArgument('selected_material',
    				mat_names, true, true)
    selected_material.setDisplayName("Select Material")
    if !mat_names.empty?
    	selected_material.setDefaultValue(mat_names[0])
    else
    	selected_material.setDefaultValue("No Materials In Model!")
    end
    args << selected_material

	  # create argument for Water Vapor Diffusion Resistance Factor
    waterDiffFact = OpenStudio::Measure::OSArgument.makeDoubleArgument('waterDiffFact', true)
    waterDiffFact.setDisplayName("Set value for Water Vapor Diffusion Resistance Factor")
    waterDiffFact.setDefaultValue(0)
    args << waterDiffFact

	  # create argument for Coefficient A
    coefA = OpenStudio::Measure::OSArgument.makeDoubleArgument('coefA', true)
    coefA.setDisplayName("Set value for Moisture Equation Coefficient A")
    coefA.setDefaultValue(0)
    args << coefA

    # create argument for Coefficient B
    coefB = OpenStudio::Measure::OSArgument.makeDoubleArgument('coefB', true)
    coefB.setDisplayName("Set value for Moisture Equation Coefficient B")
    coefB.setDefaultValue(0)
    args << coefB

    # create argument for Coefficient C
    coefC = OpenStudio::Measure::OSArgument.makeDoubleArgument('coefC', true)
    coefC.setDisplayName("Set value for Moisture Equation Coefficient C")
    coefC.setDefaultValue(0)
    args << coefC

    # create argument for Coefficient D
    coefD = OpenStudio::Measure::OSArgument.makeDoubleArgument('coefD', true)
    coefD.setDisplayName("Set value for Moisture Equation Coefficient D")
    coefD.setDefaultValue(0)
    args << coefD

  	# create argument for Surface Layer Penetration Depth
  	surfacePenetration = OpenStudio::Measure::OSArgument.makeStringArgument('surfacePenetration', true)
  	surfacePenetration.setDisplayName("Set value for Surface Layer Penetration Depth")
  	surfacePenetration.setDefaultValue("Auto")
  	args << surfacePenetration

  	# create argument for Deep Layer Penetration Depth
  	deepPenetration = OpenStudio::Measure::OSArgument.makeStringArgument('deepPenetration', false)
  	deepPenetration.setDisplayName("Set value for Deep Layer Penetration Depth")
  	deepPenetration.setDefaultValue("Auto")
  	args << deepPenetration

	  # create argument for Coating layer Thickness
    coating = OpenStudio::Measure::OSArgument.makeDoubleArgument('coating', true)
    coating.setDisplayName("Set value for Coating Layer Thickness")
    coating.setDefaultValue(0)
    args << coating

    # create argument for Coating layer Resistance
    coatingRes = OpenStudio::Measure::OSArgument.makeDoubleArgument('coatingRes', true)
    coatingRes.setDisplayName("Set value for Coating Layer Resistance Factor")
    coatingRes.setDefaultValue(0)
    args << coatingRes

    # create argument for heat balance algorithm
    algs = ["", "MoisturePenetrationDepthConductionTransferFunction",
        "ConductionTransferFunction"]
    algorithm = OpenStudio::Measure::OSArgument.makeChoiceArgument('algorithm', algs, false)
    algorithm.setDisplayName("Change heat balance algorithm?")
    algorithm.setDefaultValue(algs[0])
    args << algorithm

    return args
  end

  # define what happens when the measure is run
  def run(model, runner, user_arguments)
    super(model, runner, user_arguments)

    # use the built-in error checking
    if !runner.validateUserArguments(arguments(model), user_arguments)
      return false
    end

    # assign the user inputs to variables
    selected_material = runner.getStringArgumentValue('selected_material', user_arguments)
    waterDiffFact = runner.getDoubleArgumentValue('waterDiffFact', user_arguments)
    coefA = runner.getDoubleArgumentValue('coefA', user_arguments)
    coefB = runner.getDoubleArgumentValue('coefB', user_arguments)
    coefC = runner.getDoubleArgumentValue('coefC', user_arguments)
    coefD = runner.getDoubleArgumentValue('coefD', user_arguments)
    surfacePenetration = runner.getStringArgumentValue('surfacePenetration', user_arguments)
    surfacePenetration = surfacePenetration.to_f
    deepPenetration = runner.getStringArgumentValue('deepPenetration', user_arguments)
    deepPenetration = deepPenetration.to_f
    coating = runner.getDoubleArgumentValue('coating', user_arguments)
    coatingRes = runner.getDoubleArgumentValue('coatingRes', user_arguments)
    algorithm = runner.getStringArgumentValue('algorithm', user_arguments)

    #---------------------------------------------------------------------------
    # Validate arguments
    if waterDiffFact == 0
      runner.registerError("The Water Vapor Diffusion Resistance Factor needs to be greater than 0.")
      return false
    end
	if coefA == 0
      runner.registerWarning("The Moisture Equation Coefficient A has been left as 0. This is usally a non-zero value.")
    end
	if coefB == 0
      runner.registerWarning("The Moisture Equation Coefficient B has been left as 0. This is usally a non-zero value.")
    end
	if coefC == 0
      runner.registerWarning("The Moisture Equation Coefficient C has been left as 0. This is usally a non-zero value.")
    end
	if coefD == 0
      runner.registerWarning("The Moisture Equation Coefficient D has been left as 0. This is usally a non-zero value.")
    end
    #---------------------------------------------------------------------------

    # Get os object for selected material
    mats = model.getMaterials
    mat = ""
    mats.each do |m|
    	if m.name.to_s == selected_material
    		mat = m
    	end
    end

    # report initial condition of model
    runner.registerInitialCondition("The building has #{mats.size} materials.")

    #---------------------------------------------------------------------------
    # Set algorithm and report to users
    if algorithm != ""
      alg = model.getHeatBalanceAlgorithm
      alg.setAlgorithm(algorithm)
      runner.registerInfo("Heat Balance Algorithm Set to : #{algorithm}")
    end
    #---------------------------------------------------------------------------

    # Add moisture properties object and make changes to model
      n = OpenStudio::Model::MaterialPropertyMoisturePenetrationDepthSettings.new(
    				mat, waterDiffFact,coefA,coefB,coefC,coefD,coating,coatingRes)

    # check if the surface penetration is being autocalculated, and if not set the depth
    if surfacePenetration > 0
		n.setSurfaceLayerPenetrationDepth(surfacePenetration)
		runner.registerInfo("Surface layer penetration depth set to: #{surfacePenetration}")
    else
    	n.autocalculateSurfaceLayerPenetrationDepth()
		runner.registerInfo("Surface layer penetration depth set to: AutoCalculate")
    end


    # check if the deep penetration is being autocalculated, and if not set the depth
    if deepPenetration > 0
    	n.setDeepLayerPenetrationDepth(deepPenetration)
		runner.registerInfo("Deep layer penetration depth set to: #{surfacePenetration}")
    else
    	n.autocalculateDeepLayerPenetrationDepth()
		runner.registerInfo("Deep layer penetration depth set to: AutoCalculate")
    end


  	# report final condition of model
  	runner.registerFinalCondition("Moisture properties were added to #{selected_material}.")

    return true
  end
end

# register the measure to be used by the application
AddEMPDMaterialProperties.new.registerWithApplication
