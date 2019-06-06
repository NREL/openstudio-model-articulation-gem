# see the URL below for information on how to write OpenStudio measures
# http://nrel.github.io/OpenStudio-user-documentation/reference/measure_writing_guide/

# start the measure
class TenantStarInternalLoads < OpenStudio::Ruleset::ModelUserScript

  require 'openstudio-standards'

  # require all .rb files in resources folder
  Dir[File.dirname(__FILE__) + '/resources/*.rb'].each {|file| require file }

  # resource file modules
  include OsLib_HelperMethods

  # human readable name
  def name
    return "Tenant Star Internal Loads"
  end

  # human readable description
  def description
    return "Overrides existing model values for lightings, equipment, people, and infiltration."
  end

  # human readable description of modeling approach
  def modeler_description
    return "Lighting should be stacked value unless we add uncertainty. Equipment and people will vary based on information provided by tenant, and infiltration will be used for uncertainty. Schedules will be addressed in a separate measure that creates parametric schedules based on hours of operation."
  end

  # define the arguments that the user will input
  def arguments(model)
    args = OpenStudio::Ruleset::OSArgumentVector.new

    # argument for lpd
    # note: the new consumption method is ontly setup to work on lights that are wattsperSpaceFloorArea and use ScheduleRulesets. It will fail with ruby error if that isn't the case, but for TenantStart this will be fine.
    #lpd = OpenStudio::Ruleset::OSArgument.makeDoubleArgument("lpd", true)
    #lpd.setDisplayName("Target Annual lighting power consumption")
    #lpd.setDefaultValue(5.0)
    #lpd.setUnits("kBtu/ft^2")
    #lpd.setDescription("This will be used to calculate an LPD by dividing annual consumption by annual_equivalent_full_load_hrs and floor area. Lighting schedules should not be changed after this measure has been run or consumpiton will not be as expected.")
    #args << lpd

    # argument for epd
    epd = OpenStudio::Ruleset::OSArgument.makeDoubleArgument("epd", true)
    epd.setDisplayName("Electric Equipment Power Density")
    epd.setDefaultValue(0.55) # 0.55 value came from 50% AEDG Table 4.7
    epd.setUnits("W/ft^2")
    epd.setDescription("Electric Power Density including servers.")
    args << epd

    # argument for people_per_floor_area
    #people_per_floor_area = OpenStudio::Ruleset::OSArgument.makeDoubleArgument("people_per_floor_area", true)
    #people_per_floor_area.setDisplayName("People per floor area")
    #people_per_floor_area.setDefaultValue(0.005) # default value based on medium office prototype
    #people_per_floor_area.setUnits("People/ft^2")
    #args << people_per_floor_area

    return args
  end

  # define what happens when the measure is run
  def run(model, runner, user_arguments)
    super(model, runner, user_arguments)

    # assign the user inputs to variables
    args  = OsLib_HelperMethods.createRunVariables(runner, model,user_arguments, arguments(model))
    if !args then return false end

    #non_neg_args = ["lpd","epd","people_per_floor_area"]
    non_neg_args = ["epd"]
    non_neg = OsLib_HelperMethods.checkDoubleAndIntegerArguments(runner, user_arguments,{"min"=>0.0,"max"=>nil,"min_eq_bool"=>true,"max_eq_bool"=>false,"arg_array" =>non_neg_args})
    if !non_neg then return false end

    # report initial condition of model
    #runner.registerInitialCondition("The building started with an installed LPD of #{ OpenStudio::convert(model.getBuilding.lightingPowerPerFloorArea,"W/m^2","W/ft^2").get} W/ft^2.")

    # calculate initial lighting consumtpion (assuming no daylight controls) to determine LPD adjustmnet multiplier)
    #initial_consumption = 0.0
    #model.getSpaceTypes.each do |space_type|
    #  next if space_type.spaces.size == 0
    #  space_type.lights.each do |light|
    #    floor_area = space_type.floorArea
    #    lpd = light.lightsDefinition.wattsperSpaceFloorArea.get
    #    schedule = light.schedule.get
    #    ann_equiv_hours = schedule.to_ScheduleRuleset.get.annual_equivalent_full_load_hrs
    #    consumption = floor_area * lpd * ann_equiv_hours
    #    runner.registerInfo("#{light.name} has #{ann_equiv_hours} annual equiv. hours with total consumption of #{consumption}.")
    #    initial_consumption += consumption
    #  end
    #end

    # calculate LPD multiplier
    #lpd_multiplier = OpenStudio::convert(model.getBuilding.floorArea,"m^2","ft^2").get * args['lpd']/OpenStudio::convert(initial_consumption,"Wh","kBtu").get

    # array of altered lighting defitinos (tracking so isn't altered twice)
    #altered_light_defs = []

    # loop through spae types altering loads
    #model.getSpaceTypes.each do |space_type|
    #  next if space_type.spaces.size == 0

      # update lights
      #space_type.lights.each do |light|
      #  light_def = light.lightsDefinition
      #  if not altered_light_defs.include?(light_def)
      #    light_def.setWattsperSpaceFloorArea(light_def.wattsperSpaceFloorArea.get * lpd_multiplier)
      #    altered_light_defs << light_def
      #  end
      #end

      # replace electric equipment
      model.getSpaceTypes.each do |space_type|
	epd_si = OpenStudio::convert(args['epd'],"W/ft^2","W/m^2").get
	space_type.setElectricEquipmentPowerPerFloorArea(epd_si)
	runner.registerInfo("Changing EPD for plug loads for #{space_type.name} to #{args['epd']} (W/ft^2)")
      end

      # replace people
      #people_per_floor_area_si = OpenStudio::convert(args['people_per_floor_area'],"1/ft^2","1/m^2").get
      #space_type.setPeoplePerFloorArea(people_per_floor_area_si)
      #runner.registerInfo("Changing People per floor area for #{space_type.name} to #{args['people_per_floor_area']} (People/ft^2)")

    #end

    # report final condition of model
    #runner.registerFinalCondition("The building finished with an installed LPD of #{ OpenStudio::convert(model.getBuilding.lightingPowerPerFloorArea,"W/m^2","W/ft^2").get} W/ft^2.")

    return true

  end
  
end

# register the measure to be used by the application
TenantStarInternalLoads.new.registerWithApplication
