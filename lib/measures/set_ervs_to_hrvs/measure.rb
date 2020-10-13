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
class SetERVsToHRVs < OpenStudio::Measure::ModelMeasure

  # human readable name
  def name
    return 'Set ERVs to HRVs'
  end

  # human readable description
  def description
    return 'Change both zone ERVs and central ERVs to HRVs by setting the latent heat recovery efficiency to zero.'
  end

  # human readable description of modeling approach
  def modeler_description
    return 'Sets the latent effectiveness of OS:HeatExchanger:AirToAir:SensibleAndLatent objects to zero.'
  end

  # define the arguments that the user will input
  def arguments(model)
    args = OpenStudio::Measure::OSArgumentVector.new

    return args
  end

  # define what happens when the measure is run
  def run(model, runner, user_arguments)
    super(model, runner, user_arguments)

    # use the built-in error checking
    if !runner.validateUserArguments(arguments(model), user_arguments)
      return false
    end

    existing_ervs = model.getHeatExchangerAirToAirSensibleAndLatents
    if existing_ervs.size.zero?
      runner.registerAsNotApplicable('The model does not contain any HeatExchangerAirToAirSensibleAndLatent objects.')
      return true
    else
      runner.registerInitialCondition("The models contains #{existing_ervs.size} existing ERVs.")
    end

    # set heat exchanger objects to have zero latent effectiveness
    ervs_changed = []
    existing_ervs.each do |erv|
      if erv.latentEffectivenessat100HeatingAirFlow > 0.0
        erv.setLatentEffectivenessat100HeatingAirFlow(0.0)
        erv.setLatentEffectivenessat75HeatingAirFlow(0.0)
        erv.setLatentEffectivenessat100CoolingAirFlow(0.0)
        erv.setLatentEffectivenessat75CoolingAirFlow(0.0)
        runner.registerInfo("Set ERV '#{erv.name}' to zero latent effectiveness.")
        ervs_changed << erv
      end
    end

    runner.registerFinalCondition("#{ervs_changed.size} were changed to HRVs; the rest were already HRVs.")
    return true
  end
end

# register the measure to be used by the application
SetERVsToHRVs.new.registerWithApplication
