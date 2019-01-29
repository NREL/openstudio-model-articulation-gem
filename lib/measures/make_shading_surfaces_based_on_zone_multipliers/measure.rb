# see the URL below for information on how to write OpenStudio measures
# http://nrel.github.io/OpenStudio-user-documentation/reference/measure_writing_guide/

require "#{File.dirname(__FILE__)}/resources/os_lib_helper_methods"

# start the measure
class MakeShadingSurfacesBasedOnZoneMultipliers < OpenStudio::Ruleset::ModelUserScript

  # human readable name
  def name
    return "Make Shading Surfaces Based on Zone Multipliers"
  end

  # human readable description
  def description
    return "Initially this will jsut focus on Z shifting of geometry, but in future could work on x,z or y,z multiplier grids like what is use don the large hotel"
  end

  # human readable description of modeling approach
  def modeler_description
    return "Not sure how I will handle arguments. Maybe lump together all spaces on same sotry that have the same multilier value. This will have variable number of arguments basd on the model pased in. Alternative is to either only allo w one group to be chosen at at time, or allow a comlex string that describes everything. Also need to see how to define shirting. There is an offset but it may be above and below and may not be equal. In Some cases a mid floor is halfway betwen floors which makes just copying the base surfaces as shading multiple times probemeatic, since there is overlap. It coudl be nice to stretch one surface over many stories. If I check for vertial adn orthogonal surface that may work fine. "
  end

  # define the arguments that the user will input
  def arguments(model)
    args = OpenStudio::Ruleset::OSArgumentVector.new


    # todo - make arguments for each group of common non 1 multipliers on the same story


    # todo - optionally could also list individual zones with non 1 multiliers as well


    # todo - argument for z offset distance per zone
    z_offset_dist = OpenStudio::Ruleset::OSArgument.makeDoubleArgument("z_offset_dist", true)
    z_offset_dist.setDisplayName("Z offset distance for selcected zones.")
    z_offset_dist.setDefaultValue(10.0)
    z_offset_dist.setUnits("ft")
    args << z_offset_dist

    # todo - argument for z start offset starting position (0 is equal above and below)
    z_num_pos = OpenStudio::Ruleset::OSArgument.makeIntegerArgument("z_num_pos", true)
    z_num_pos.setDisplayName("Number of copies in the positive direction.")
    z_num_pos.setDescription("Should be integer no more than the multiplier - 1")
    z_num_pos.setDefaultValue(1) # todo - replace with half of multiplier rounded up
    args << z_num_pos

    # todo - argument for x offset distance per zone


    # todo - argument for x start offset starting position (0 is equal above and below)


    # todo - argument for y offset distance per zone


    # todo - argument for y start offset starting position (0 is equal above and below)



    return args
  end

  # define what happens when the measure is run
  def run(model, runner, user_arguments)
    super(model, runner, user_arguments)

    # assign the user inputs to variables
    args  = OsLib_HelperMethods.createRunVariables(runner, model,user_arguments, arguments(model))
    if !args then return false end

    # report initial condition of model
    runner.registerInitialCondition("The building started with #{model.getShadingSurfaces.size} shading surfaces.")

    # find thermal zones with multiplier greater than 1
    zones_to_alter = {}
    model.getThermalZones.each do |zone|
      if zone.multiplier > 1
        puts "#{zone.name} has a multiplier of #{zone.multiplier}"
        zones_to_alter[zone.spaces] = zone.multiplier
      end
    end

    # gather inputs
    z_offset_si = OpenStudio.convert(args['z_offset_dist'],"ft",'m').get

    # gather surfaces to copy
    surfaces_to_copy = {}
    zones_to_alter.each do |spaces,multiplier|
      spaces.each do |space|

        # space_origin
        origin = [space.xOrigin,space.yOrigin,space.zOrigin]

        origin_pos_z = space.zOrigin
        args['z_num_pos'].times do

          origin_pos_z += z_offset_si

          # make shading surface group and set origin
          shading_surface_group = OpenStudio::Model::ShadingSurfaceGroup.new(model)
          shading_surface_group.setXOrigin(origin[0])
          shading_surface_group.setYOrigin(origin[1])
          shading_surface_group.setZOrigin(origin_pos_z)

          space.surfaces.each do |surface|
            next if surface.outsideBoundaryCondition != "Outdoors"
            surfaces_to_copy[surface] = multiplier

            # store  vertices
            vertices = surface.vertices

            # make shading surface for new group
            shading_surface = OpenStudio::Model::ShadingSurface.new(vertices,model)
            shading_surface.setShadingSurfaceGroup(shading_surface_group)
            shading_surface.setName("mult - #{surface.name}")

          end

        end

        origin_neg_z = space.zOrigin
        num_nug = (multiplier - args['z_num_pos']) - 1 # one copy already exist, so only need multiplier - 1
        num_nug.times do

          origin_neg_z -= z_offset_si

          # make shading surface group and set origin
          shading_surface_group = OpenStudio::Model::ShadingSurfaceGroup.new(model)
          shading_surface_group.setXOrigin(origin[0])
          shading_surface_group.setYOrigin(origin[1])
          shading_surface_group.setZOrigin(origin_neg_z)

          space.surfaces.each do |surface|
            next if surface.outsideBoundaryCondition != "Outdoors"
            surfaces_to_copy[surface] = multiplier

            # store  vertices
            vertices = surface.vertices

            # make shading surface for new group
            shading_surface = OpenStudio::Model::ShadingSurface.new(vertices,model)
            shading_surface.setShadingSurfaceGroup(shading_surface_group)
            shading_surface.setName("mult - #{surface.name}")

          end

        end

      end
    end

    # todo - stretching on non orthogonal won't work, take different approach in those cases.

    # report final condition of model
    runner.registerFinalCondition("The building finished with #{model.getShadingSurfaces.size} surfaces.")

    return true

  end
  
end

# register the measure to be used by the application
MakeShadingSurfacesBasedOnZoneMultipliers.new.registerWithApplication
