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
    return ['Adds', 'the', 'properties', 'for', 'the', 'MoisturePenetrationDepthConductionTransferFunction', 'or', 'effective', 'moisture', 'penetration', 'depth', '(EMPD)', 'Heat', 'Balance', 'Model', 'with', 'inputs', 'for', 'penetration', 'depths.', "\n\n", 'Leaving', 'Change', 'heat', 'balance', 'algorithm?', 'blank', 'will', 'use', 'the', 'current', 'OpenStudio', 'heat', 'balance', 'algorithm', 'setting.', "\n\n", 'At', 'least', '1', 'interior', 'material', 'needs', 'to', 'have', 'moisture', 'penetration', 'depth', 'properties', 'set', 'to', 'use', 'the', 'EMPD', 'heat', 'balance', 'algorithm.'].join(' ')
  end

  # define the arguments that the user will input
  def arguments(model)
    args = OpenStudio::Measure::OSArgumentVector.new

    # find the available materials
    list_materials = model.getMaterials
    mat_names = []
    list_materials.each do |v|
      mat_names.append(v.name.to_s)
    end
    mat_names.sort!

    # Create arguments for material selection (Choice)
    selected_material = OpenStudio::Measure::OSArgument.makeChoiceArgument('selected_material',
                                                                           mat_names, true, true)
    selected_material.setDisplayName('Select Material')
    if !mat_names.empty?
      selected_material.setDefaultValue(mat_names[0])
    else
      selected_material.setDefaultValue('No Materials In Model!')
    end
    args << selected_material

    # create argument for Water Vapor Diffusion Resistance Factor
    water_diff_fact = OpenStudio::Measure::OSArgument.makeDoubleArgument('water_diff_fact', true)
    water_diff_fact.setDisplayName('Set value for Water Vapor Diffusion Resistance Factor')
    water_diff_fact.setDefaultValue(0)
    args << water_diff_fact

    # create argument for Coefficient A
    coef_a = OpenStudio::Measure::OSArgument.makeDoubleArgument('coef_a', true)
    coef_a.setDisplayName('Set value for Moisture Equation Coefficient A')
    coef_a.setDefaultValue(0)
    args << coef_a

    # create argument for Coefficient B
    coef_b = OpenStudio::Measure::OSArgument.makeDoubleArgument('coef_b', true)
    coef_b.setDisplayName('Set value for Moisture Equation Coefficient B')
    coef_b.setDefaultValue(0)
    args << coef_b

    # create argument for Coefficient C
    coef_c = OpenStudio::Measure::OSArgument.makeDoubleArgument('coef_c', true)
    coef_c.setDisplayName('Set value for Moisture Equation Coefficient C')
    coef_c.setDefaultValue(0)
    args << coef_c

    # create argument for Coefficient D
    coef_d = OpenStudio::Measure::OSArgument.makeDoubleArgument('coef_d', true)
    coef_d.setDisplayName('Set value for Moisture Equation Coefficient D')
    coef_d.setDefaultValue(0)
    args << coef_d

    # create argument for Surface Layer Penetration Depth
    surface_penetration = OpenStudio::Measure::OSArgument.makeStringArgument('surface_penetration', true)
    surface_penetration.setDisplayName('Set value for Surface Layer Penetration Depth')
    surface_penetration.setDefaultValue('Auto')
    args << surface_penetration

    # create argument for Deep Layer Penetration Depth
    deep_penetration = OpenStudio::Measure::OSArgument.makeStringArgument('deep_penetration', false)
    deep_penetration.setDisplayName('Set value for Deep Layer Penetration Depth')
    deep_penetration.setDefaultValue('Auto')
    args << deep_penetration

    # create argument for Coating layer Thickness
    coating = OpenStudio::Measure::OSArgument.makeDoubleArgument('coating', true)
    coating.setDisplayName('Set value for Coating Layer Thickness')
    coating.setDefaultValue(0)
    args << coating

    # create argument for Coating layer Resistance
    coating_res = OpenStudio::Measure::OSArgument.makeDoubleArgument('coating_res', true)
    coating_res.setDisplayName('Set value for Coating Layer Resistance Factor')
    coating_res.setDefaultValue(0)
    args << coating_res

    # create argument for heat balance algorithm
    algs = ['', 'MoisturePenetrationDepthConductionTransferFunction',
            'ConductionTransferFunction']
    algorithm = OpenStudio::Measure::OSArgument.makeChoiceArgument('algorithm', algs, false)
    algorithm.setDisplayName('Change heat balance algorithm?')
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
    water_diff_fact = runner.getDoubleArgumentValue('water_diff_fact', user_arguments)
    coef_a = runner.getDoubleArgumentValue('coef_a', user_arguments)
    coef_b = runner.getDoubleArgumentValue('coef_b', user_arguments)
    coef_c = runner.getDoubleArgumentValue('coef_c', user_arguments)
    coef_d = runner.getDoubleArgumentValue('coef_d', user_arguments)
    surface_penetration = runner.getStringArgumentValue('surface_penetration', user_arguments)
    surface_penetration = surface_penetration.to_f
    deep_penetration = runner.getStringArgumentValue('deep_penetration', user_arguments)
    deep_penetration = deep_penetration.to_f
    coating = runner.getDoubleArgumentValue('coating', user_arguments)
    coating_res = runner.getDoubleArgumentValue('coating_res', user_arguments)
    algorithm = runner.getStringArgumentValue('algorithm', user_arguments)

    #---------------------------------------------------------------------------
    # Validate arguments
    if water_diff_fact == 0
      runner.registerError('The Water Vapor Diffusion Resistance Factor needs to be greater than 0.')
      return false
    end
    if coef_a == 0
      runner.registerWarning('The Moisture Equation Coefficient A has been left as 0. This is usally a non-zero value.')
    end
    if coef_b == 0
      runner.registerWarning('The Moisture Equation Coefficient B has been left as 0. This is usally a non-zero value.')
    end
    if coef_c == 0
      runner.registerWarning('The Moisture Equation Coefficient C has been left as 0. This is usally a non-zero value.')
    end
    if coef_d == 0
      runner.registerWarning('The Moisture Equation Coefficient D has been left as 0. This is usally a non-zero value.')
    end
    #---------------------------------------------------------------------------

    # Get os object for selected material
    mats = model.getMaterials
    mat = ''
    mats.each do |m|
      if m.name.to_s == selected_material
        mat = m
      end
    end

    # report initial condition of model
    runner.registerInitialCondition("The building has #{mats.size} materials.")

    #---------------------------------------------------------------------------
    # Set algorithm and report to users
    if algorithm != ''
      alg = model.getHeatBalanceAlgorithm
      alg.setAlgorithm(algorithm)
      runner.registerInfo("Heat Balance Algorithm Set to : #{algorithm}")
    end
    #---------------------------------------------------------------------------

    # Add moisture properties object and make changes to model
    n = OpenStudio::Model::MaterialPropertyMoisturePenetrationDepthSettings.new(
      mat, water_diff_fact, coef_a, coef_b, coef_c, coef_d, coating, coating_res
    )

    # check if the surface penetration is being autocalculated, and if not set the depth
    if surface_penetration > 0
      n.setSurfaceLayerPenetrationDepth(surface_penetration)
      runner.registerInfo("Surface layer penetration depth set to: #{surface_penetration}")
    else
      n.autocalculateSurfaceLayerPenetrationDepth
      runner.registerInfo('Surface layer penetration depth set to: AutoCalculate')
    end

    # check if the deep penetration is being autocalculated, and if not set the depth
    if deep_penetration > 0
      n.setDeepLayerPenetrationDepth(deep_penetration)
      runner.registerInfo("Deep layer penetration depth set to: #{surface_penetration}")
    else
      n.autocalculateDeepLayerPenetrationDepth
      runner.registerInfo('Deep layer penetration depth set to: AutoCalculate')
    end

    # report final condition of model
    runner.registerFinalCondition("Moisture properties were added to #{selected_material}.")

    return true
  end
end

# register the measure to be used by the application
AddEMPDMaterialProperties.new.registerWithApplication
