# see the URL below for information on how to write OpenStudio measures
# http://nrel.github.io/OpenStudio-user-documentation/measures/measure_writing_guide/

require_relative 'resources/dxf2ruby.rb'
require 'measure_resources/os_lib_geometry.rb'

# start the measure
class CreateSpacesFromDXFDiagram < OpenStudio::Ruleset::ModelUserScript

  # human readable name
  def name
    return "Create Spaces From DXF Diagram"
  end

  # human readable description
  def description
    return "Use a 2d diagram from an external DXF to create spaces in OpenStudio. The number of floors and floor to floor height are exposed as arguments"
  end

  # human readable description of modeling approach
  def modeler_description
    return "This uses the OpenStudio::Model::Space::fromFloorPrint method, and is very much like the Create Spaaces From Diagram tool in the OpenStudio SketchUp plugin, but lets you draw teh diagram in the tool of your choice, and then imports it into the OpenStudio application via a measure."
  end

  # define the arguments that the user will input
  def arguments(model)
    args = OpenStudio::Ruleset::OSArgumentVector.new

    # the name of the space to add to the model
    dxf_path = OpenStudio::Ruleset::OSArgument.makeStringArgument("dxf_path", true)
    dxf_path.setDisplayName("Full path of DXF file with Diagram")
    dxf_path.setDescription("This should include the path and the file name.")
    dxf_path.setUnits("Unit for DXF should be inches")
    args << dxf_path

    # the name of the space to add to the model
    floor_to_floor_height = OpenStudio::Ruleset::OSArgument.makeDoubleArgument("floor_to_floor_height", true)
    floor_to_floor_height.setDisplayName("Floor to Floor Height")
    floor_to_floor_height.setUnits("ft")
    floor_to_floor_height.setDefaultValue(10.0)
    args << floor_to_floor_height

    # the name of the space to add to the model
    num_floors = OpenStudio::Ruleset::OSArgument.makeIntegerArgument("num_floors", true)
    num_floors.setDisplayName("Number of Floors")
    num_floors.setUnits("ft")
    num_floors.setDescription("Diagram will be stacked this many times.")
    num_floors.setDefaultValue(1)
    args << num_floors

    # the name of the space to add to the model
    base_height = OpenStudio::Ruleset::OSArgument.makeDoubleArgument("base_height", true)
    base_height.setDisplayName("Base Height for Lowest Diagram.")
    base_height.setUnits("ft")
    base_height.setDescription("Use 0 unless you are staking multiple diagrams.")
    base_height.setDefaultValue(0.0)
    args << base_height

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
    dxf_path = runner.getStringArgumentValue("dxf_path", user_arguments)
    floor_to_floor_height = runner.getDoubleArgumentValue("floor_to_floor_height", user_arguments)
    num_floors = runner.getIntegerArgumentValue("num_floors", user_arguments)
    base_height = runner.getDoubleArgumentValue("base_height", user_arguments)

    #check the source_idf_path for reasonableness
    if dxf_path == ""
      runner.registerError("No Source DXF File Path was Entered.")
      return false
    end

    # check floor height for reasonableness
    if floor_to_floor_height <= 0.0
      runner.registerError("Enter a positive value for floor to floor height.")
      return false
    end

    # check number of floors for reasonableness
    if floor_to_floor_height < 1
      runner.registerError("Enter a positive value for floor to floor height.")
      return false
    end

    # report initial condition of model
    runner.registerInitialCondition("The building started with #{model.getSpaces.size} spaces.")

    # create an array of polygons
    polygons = []

    dxf = Dxf2Ruby.parse(dxf_path)
    acad_version =  dxf['HEADER']['$ACADVER']

    dxf['ENTITIES'].each do |entity|

      # create polygon, vertices will be added later
      polygon = OpenStudio::Point3dVector.new

      # this and first elseif is what comes out of SketchUp as 3d dxf export
      if entity[0] == "POLYLINE"

        # link that explains part of DXF Polyline
        #http://www.autodesk.com/techpubs/autocad/acad2000/dxf/polyline_dxf_06.htm

      elsif entity[0] == "VERTEX" and entity[100] == ["AcDbEntity", "AcDbVertex", "AcDbPolyFaceMeshVertex"]

        #puts "X = #{entity[10]},Y = #{entity[20]},Z = #{entity[30]},"

      # this came out of autocad360 and also inkscape
      elsif entity[0] == "LWPOLYLINE"

        array = []
        entity[10].length.times do |i|
          x_ip = OpenStudio::convert(entity[10][i],"ft","m").get
          y_ip = OpenStudio::convert(entity[20][i],"ft","m").get
          if not entity[30]
            z_ip = 0.0
          else
            z_ip = OpenStudio::convert(entity[30][i],"ft","m").get
          end
          array << [x_ip,y_ip,z_ip]
        end

        # loop through vertices in polyline
        array.uniq.each do |pt|

          point = OpenStudio::Point3d.new(pt[0],pt[1],pt[2])
          polygon << point
          counter =+ 1
        end

      else
        #puts entity
      end

      # add polygon to array of polygons
      if polygon.size >= 3 # skip of not three points
        polygons << polygon
      end

    end
    counter = 0
    floor_to_floor_height_si = OpenStudio::convert(floor_to_floor_height,"ft","m").get
    base_height_si = OpenStudio::convert(base_height,"ft","m").get

    # create new stories and then add spaces
    num_floors.times do
      nominal_z = counter*floor_to_floor_height_si + base_height_si
      story = OpenStudio::Model::BuildingStory.new(model)
      story.setNominalFloortoFloorHeight(floor_to_floor_height_si)
      story.setNominalZCoordinate(nominal_z)
      counter += 1

      polygons.each do |polygon|

        # todo - add code to sort and name similar to plugin

        # set defaults to use if user inputs not passed in
        defaults = {
            "story" => story,
            "floor_to_floor_height" => floor_to_floor_height_si,
        }

        # make space
        space = OsLib_Geometry.makeSpaceFromPolygon(model,polygon[0],polygon,defaults) # model, origin, polygon, options

        # move space vertically to proper z position.
        space.setZOrigin(nominal_z)

      end

    end

    # report final condition of model
    runner.registerFinalCondition("The building finished with #{model.getSpaces.size} spaces.")

    return true

  end
  
end

# register the measure to be used by the application
CreateSpacesFromDXFDiagram.new.registerWithApplication
