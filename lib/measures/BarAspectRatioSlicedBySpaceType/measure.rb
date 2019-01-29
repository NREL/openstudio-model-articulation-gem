#see the URL below for information on how to write OpenStudio measures
# http://openstudio.nrel.gov/openstudio-measure-writing-guide

#see the URL below for information on using life cycle cost objects in OpenStudio
# http://openstudio.nrel.gov/openstudio-life-cycle-examples

#see the URL below for access to C++ documentation on model objects (click on "model" in the main window to view model objects)
# http://openstudio.nrel.gov/sites/openstudio.nrel.gov/files/nv_data/cpp_documentation_it/model/html/namespaces.html

#load OpenStudio measure libraries
require "#{File.dirname(__FILE__)}/resources/os_lib_geometry"
require "#{File.dirname(__FILE__)}/resources/os_lib_helper_methods"
require "#{File.dirname(__FILE__)}/resources/OsLib_Cofee"

#start the measure
class BarAspectRatioSlicedBySpaceType < OpenStudio::Ruleset::ModelUserScript
  
  #define the name that a user will see, this method may be deprecated as
  #the display name in PAT comes from the name field in measure.xml
  def name
    return "BarAspectRatioSlicedBySpaceType"
  end
  
  #define the arguments that the user will input
  def arguments(model)
    args = OpenStudio::Ruleset::OSArgumentVector.new
    
    #make an argument for total floor area
    total_bldg_area_ip = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("total_bldg_area_ip",true)
    total_bldg_area_ip.setDisplayName("Total Building Floor Area (ft^2).")
    total_bldg_area_ip.setDefaultValue(10000.0)
    args << total_bldg_area_ip

    #make an argument for aspect ratio
    ns_to_ew_ratio = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("ns_to_ew_ratio",true)
    ns_to_ew_ratio.setDisplayName("Ratio of North/South Facade Length Relative to East/West Facade Length.")
    ns_to_ew_ratio.setDefaultValue(2.0)
    args << ns_to_ew_ratio

    #make an argument for number of floors
    num_floors = OpenStudio::Ruleset::OSArgument::makeIntegerArgument("num_floors",true)
    num_floors.setDisplayName("Number of Floors.")
    num_floors.setDefaultValue(2)
    args << num_floors

    #make an argument for floor height
    floor_to_floor_height_ip = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("floor_to_floor_height_ip",true)
    floor_to_floor_height_ip.setDisplayName("Floor to Floor Height (ft).")
    floor_to_floor_height_ip.setDefaultValue(10.0)
    args << floor_to_floor_height_ip

    #make an argument for the meter name
    spaceTypeHashString = OpenStudio::Ruleset::OSArgument::makeStringArgument("spaceTypeHashString",true)
    spaceTypeHashString.setDisplayName("Hash of Space Types with Name as Key and Fraction as value.")
    args << spaceTypeHashString

    return args
  end

  #define what happens when the measure is run
  def run(model, runner, user_arguments)
    super(model, runner, user_arguments)

    #use the built-in error checking
    if not runner.validateUserArguments(arguments(model), user_arguments)
      return false
    end

    #assign the user inputs to variables
    total_bldg_area_ip = runner.getDoubleArgumentValue("total_bldg_area_ip",user_arguments)
    ns_to_ew_ratio = runner.getDoubleArgumentValue("ns_to_ew_ratio",user_arguments)
    num_floors = runner.getIntegerArgumentValue("num_floors",user_arguments)
    floor_to_floor_height_ip = runner.getDoubleArgumentValue("floor_to_floor_height_ip",user_arguments)
    spaceTypeHashString = runner.getStringArgumentValue("spaceTypeHashString",user_arguments)

    #test for positive inputs
    if not total_bldg_area_ip > 0
      runner.registerError("Enter a total building area greater than 0.")
    end
    if not ns_to_ew_ratio > 0
      runner.registerError("Enter ratio grater than 0.")
    end
    if not num_floors > 0
      runner.registerError("Enter a number of stories 1 or greater.")
    end
    if not floor_to_floor_height_ip > 0
      runner.registerError("Enter a positive floor height.")
    end
    if 1 == 1
      #todo - add test for spaceTypeHashString argument
    end

    #calculate needed variables
    total_bldg_area_si = OpenStudio::convert(total_bldg_area_ip,"ft^2","m^2").get
    footprint_ip = total_bldg_area_ip/num_floors
    footprint_si = OpenStudio::convert(footprint_ip,"ft^2","m^2").get
    floor_to_floor_height =  OpenStudio::convert(floor_to_floor_height_ip,"ft","m").get

    #variables from original rectangle script not exposed in this measure
    width = Math.sqrt(footprint_si/ns_to_ew_ratio)
    length = footprint_si/width

    #reporting initial condition of model
    starting_spaces = model.getSpaces
    runner.registerInitialCondition("The building started with #{starting_spaces.size} spaces.")

    # convert string argument to hash
    spaceTypeHashName = Hash.new
    spaceTypeHashString[1..-2].split(/, /).each {|entry| entryMap=entry.split(/=>/); value_str = entryMap[1]; spaceTypeHashName[entryMap[0].strip[1..-1].to_s] = value_str.nil? ? "" : value_str.strip[1..-2].to_f}

    # sum of hash values
    hashValues = 0

    spaceTypeHash = Hash.new
    model.getSpaceTypes.each do |spaceType|
      if spaceTypeHashName.include?(spaceType.name.to_s)
        spaceTypeHash[spaceType] = spaceTypeHashName[spaceType.name.to_s]*total_bldg_area_si # converting fractional value to area value to pass into method
        hashValues += spaceTypeHashName[spaceType.name.to_s]
      end
    end

    if hashValues != 1.0
      runner.registerWarning("Fractional hash values do not add up to one. Resulting geometry may not have expected area.")
    end

    # see which path to take
    midFloorMultiplier = 1 # show as 1 even on 1 and 2 story buildings where there is no mid floor, in addition to 3 story building
    if num_floors > 3
      # use floor multiplier version. Set mid floor multiplier, use adibatic floors/ceilings and set constructions, raise up building
      midFloorMultiplier = num_floors - 2
    end

    # run method to create envelope
    bar_AspectRatio = OsLib_Cofee.createBar(model,spaceTypeHash,length,width,total_bldg_area_si,num_floors,midFloorMultiplier,0.0,0.0,length,width,0.0,floor_to_floor_height*num_floors,true)

    puts "building area #{model.getBuilding.floorArea}"

    #reporting final condition of model
    finishing_spaces = model.getSpaces
    runner.registerFinalCondition("The building finished with #{finishing_spaces.size} spaces.")
    
    return true
 
  end

end

#this allows the measure to be use by the application
BarAspectRatioSlicedBySpaceType.new.registerWithApplication