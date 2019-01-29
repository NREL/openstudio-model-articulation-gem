# see the URL below for information on how to write OpenStudio measures
# http://nrel.github.io/OpenStudio-user-documentation/reference/measure_writing_guide/

# start the measure
class CreateAndAssignThermalZonesForUnassignedSpaces < OpenStudio::Ruleset::ModelUserScript

  # human readable name
  def name
    return "Create and Assign Thermal Zones for Unassigned Spaces"
  end

  # human readable description
  def description
    return "If any spaces are not part of a thermal zone, then this measure will create a new thermal zone and assign it to the space."
  end

  # human readable description of modeling approach
  def modeler_description
    return "Thermal zones will be named after the spac with a prefix added"
  end

  # define the arguments that the user will input
  def arguments(model)
    args = OpenStudio::Ruleset::OSArgumentVector.new

    return args
  end

  # define what happens when the measure is run
  def run(model, runner, user_arguments)
    super(model, runner, user_arguments)

    # use the built-in error checking
    if !runner.validateUserArguments(arguments(model), user_arguments)
      return false
    end

    # report initial condition of model
    runner.registerInitialCondition("The building started with #{model.getThermalZones.size} thermal zones.")

    # loop through spaces
    model.getSpaces.sort.each do |space|

      # if space doesn't have zone, then add, rename and assign
      if not space.thermalZone.is_initialized
        zone = OpenStudio::Model::ThermalZone.new(model)
        zone.setName("Zone - #{space.name.get}")
        space.setThermalZone(zone)
        runner.registerInfo("Assigning #{space.name} to new thermal zone named #{zone.name}")
      end

    end

    # report final condition of model
    runner.registerFinalCondition("The building finished with #{model.getThermalZones.size} thermal zones.")

    return true

  end
  
end

# register the measure to be used by the application
CreateAndAssignThermalZonesForUnassignedSpaces.new.registerWithApplication
