# *******************************************************************************
# OpenStudio(R), Copyright (c) 2008-2020, Alliance for Sustainable Energy, LLC.
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

class SetWindowToWallRatioByFacade < OpenStudio::Measure::ModelMeasure
  # override name to return the name of your script
  def name
    return 'Set Window to Wall Ratio by Facade'
  end

  # return a vector of arguments
  def arguments(model)
    args = OpenStudio::Measure::OSArgumentVector.new

    # make double argument for wwr
    wwr = OpenStudio::Measure::OSArgument.makeDoubleArgument('wwr', true)
    wwr.setDisplayName('Window to Wall Ratio (fraction).')
    wwr.setDefaultValue(0.4)
    args << wwr

    # make double argument for sillHeight
    sillHeight = OpenStudio::Measure::OSArgument.makeDoubleArgument('sillHeight', true)
    sillHeight.setDisplayName('Sill Height (in).')
    sillHeight.setDefaultValue(30.0)
    args << sillHeight

    # make choice argument for facade
    choices = OpenStudio::StringVector.new
    choices << 'North'
    choices << 'East'
    choices << 'South'
    choices << 'West'
    choices << 'All'
    facade = OpenStudio::Measure::OSArgument.makeChoiceArgument('facade', choices, true)
    facade.setDisplayName('Cardinal Direction.')
    facade.setDefaultValue('South')
    args << facade

    # bool to not apply windows to spaces that are not included in the building floor area
    exl_spaces_not_incl_fl_area = OpenStudio::Measure::OSArgument.makeBoolArgument('exl_spaces_not_incl_fl_area', true)
    exl_spaces_not_incl_fl_area.setDisplayName("Don't alter spaces that are not included in the building floor area")
    exl_spaces_not_incl_fl_area.setDefaultValue(true)
    args << exl_spaces_not_incl_fl_area

    # make an argument for splitting base surfaces at doors
    choices = OpenStudio::StringVector.new
    choices << 'Do nothing to Doors'
    choices << 'Split Walls at Doors'
    choices << 'Remove Doors'
    split_at_doors = OpenStudio::Measure::OSArgument.makeChoiceArgument('split_at_doors', choices, true)
    split_at_doors.setDisplayName('Exterior Door Logic')
    split_at_doors.setDescription('This will only impact exterior surfaces with specified orientation. Can do nothing, split all, or remove doors.')
    split_at_doors.setDefaultValue('Split Walls at Doors')
    args << split_at_doors

    # bool to create inset windows for triangular base surfaces
    inset_tri_sub = OpenStudio::Measure::OSArgument.makeBoolArgument('inset_tri_sub', true)
    inset_tri_sub.setDisplayName('Inset windows for triangular surfaces')
    inset_tri_sub.setDefaultValue(true)
    args << inset_tri_sub

    # triangulate non rectangular base surfaces
    triangulate = OpenStudio::Measure::OSArgument.makeBoolArgument('triangulate', true)
    triangulate.setDisplayName('Triangulate non-Rectangular surfaces')
    triangulate.setDescription('This will only impact exterior surfaces with specified orientation')
    triangulate.setDefaultValue(true)
    args << triangulate

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
    wwr = runner.getDoubleArgumentValue('wwr', user_arguments)
    sillHeight = runner.getDoubleArgumentValue('sillHeight', user_arguments)
    facade = runner.getStringArgumentValue('facade', user_arguments)
    exl_spaces_not_incl_fl_area = runner.getBoolArgumentValue('exl_spaces_not_incl_fl_area', user_arguments)
    split_at_doors = runner.getStringArgumentValue('split_at_doors', user_arguments)
    inset_tri_sub = runner.getBoolArgumentValue('inset_tri_sub', user_arguments)
    triangulate = runner.getBoolArgumentValue('triangulate', user_arguments)

    # check reasonableness of fraction
    if wwr == 0
      runner.registerInfo('Target window to wall ratio is 0. Windows for selected surfaces will be removed, no new windows will be added.')
    elsif (wwr < 0) || (wwr >= 1)
      runner.registerError('Window to Wall Ratio must be greater than or equal to 0 and less than 1.')
      return false
    end

    # check reasonableness of fraction
    if sillHeight <= 0
      runner.registerError('Sill height must be > 0.')
      return false
    elsif sillHeight > 360
      runner.registerWarning("#{sillHeight} inches seems like an unusually high sill height.")
    elsif sillHeight > 9999
      runner.registerError("#{sillHeight} inches is above the measure limit for sill height.")
      return false
    end

    # setup OpenStudio units that we will need
    unit_sillHeight_ip = OpenStudio.createUnit('ft').get
    unit_sillHeight_si = OpenStudio.createUnit('m').get
    unit_area_ip = OpenStudio.createUnit('ft^2').get
    unit_area_si = OpenStudio.createUnit('m^2').get
    unit_cost_per_area_ip = OpenStudio.createUnit('1/ft^2').get # $/ft^2 does not work
    unit_cost_per_area_si = OpenStudio.createUnit('1/m^2').get

    # define starting units
    sillHeight_ip = OpenStudio::Quantity.new(sillHeight / 12, unit_sillHeight_ip)

    # unit conversion
    sillHeight_si = OpenStudio.convert(sillHeight_ip, unit_sillHeight_si).get

    # hold data for initial condition
    starting_gross_ext_wall_area = 0.0 # includes windows and doors
    starting_ext_window_area = 0.0

    # hold data for final condition
    final_gross_ext_wall_area = 0.0 # includes windows and doors
    final_ext_window_area = 0.0

    # flag for not applicable
    exterior_walls = false
    window_confirmed = false

    # flag to track notifications of zone multipliers
    space_warning_issued = []

    # flag to track warning for new windows without construction
    facade_const_warning = false
    bldg_const_warning = false
    empty_const_warning = false

    # flag for catchall glazing to be made only once
    catchall_glazing_const = nil

    # calculate initial envelope cost as negative value
    envelope_cost = 0
    constructions = model.getConstructions.sort
    constructions.each do |construction|
      const_llcs = construction.lifeCycleCosts
      const_llcs.each do |const_llc|
        if const_llc.category == 'Construction'
          envelope_cost += const_llc.totalCost * -1
        end
      end
    end

    # loop through surfaces finding exterior walls with proper orientation
    if exl_spaces_not_incl_fl_area
      # loop through spaces to gather surfaces.
      surfaces = []
      model.getSpaces.sort.each do |space|
        next if !space.partofTotalFloorArea
        space.surfaces.sort.each do |surface|
          surfaces << surface
        end
      end
    else
      surfaces = model.getSurfaces.sort
    end

    # used for new sub surfaces to find target construction
    orig_sub_surf_const_for_target_facade = {}
    orig_sub_surf_const_for_target_all_ext = {}

    # pre-loop through sub-surfaces to store constructions
    model.getSubSurfaces.sort.each do |sub_surf|
      # store constructions for entire building
      next if sub_surf.subSurfaceType == 'Door' || sub_surf.subSurfaceType == 'OverheadDoor'
      if sub_surf.construction.is_initialized
        if orig_sub_surf_const_for_target_all_ext.key?(sub_surf.construction.get)
          orig_sub_surf_const_for_target_all_ext[sub_surf.construction.get] += 1
        else
          orig_sub_surf_const_for_target_all_ext[sub_surf.construction.get] = 1
        end
      end

      # get the absoluteAzimuth for the surface so we can categorize it
      absoluteAzimuth = OpenStudio.convert(sub_surf.azimuth, 'rad', 'deg').get + sub_surf.surface.get.space.get.directionofRelativeNorth + model.getBuilding.northAxis
      absoluteAzimuth -= 360.0 until absoluteAzimuth < 360.0

      if facade == 'North'
        next if !((absoluteAzimuth >= 315.0) || (absoluteAzimuth < 45.0))
      elsif facade == 'East'
        next if !((absoluteAzimuth >= 45.0) && (absoluteAzimuth < 135.0))
      elsif facade == 'South'
        next if !((absoluteAzimuth >= 135.0) && (absoluteAzimuth < 225.0))
      elsif facade == 'West'
        next if !((absoluteAzimuth >= 225.0) && (absoluteAzimuth < 315.0))
      elsif facade == 'All'
        # no next needed
      else
        runner.registerError('Unexpected value of facade: ' + facade + '.')
        return false
      end

      # store constructions for this facade
      if sub_surf.construction.is_initialized
        if orig_sub_surf_const_for_target_facade.key?(sub_surf.construction.get)
          orig_sub_surf_const_for_target_facade[sub_surf.construction.get] += 1
        else
          orig_sub_surf_const_for_target_facade[sub_surf.construction.get] = 1
        end
      end
    end

    # hash for sub surfaces removed from non rectangular surfaces
    non_rect_parent = {}

    surfaces.sort.each do |s|
      next if s.surfaceType != 'Wall'
      next if s.outsideBoundaryCondition != 'Outdoors'
      if s.space.empty?
        runner.registerWarning("#{s.name} doesn't have a parent space and won't be included in the measure reporting or modifications.")
        next
      end

      # get the absoluteAzimuth for the surface so we can categorize it
      absoluteAzimuth = OpenStudio.convert(s.azimuth, 'rad', 'deg').get + s.space.get.directionofRelativeNorth + model.getBuilding.northAxis
      absoluteAzimuth -= 360.0 until absoluteAzimuth < 360.0

      if facade == 'North'
        next if !((absoluteAzimuth >= 315.0) || (absoluteAzimuth < 45.0))
      elsif facade == 'East'
        next if !((absoluteAzimuth >= 45.0) && (absoluteAzimuth < 135.0))
      elsif facade == 'South'
        next if !((absoluteAzimuth >= 135.0) && (absoluteAzimuth < 225.0))
      elsif facade == 'West'
        next if !((absoluteAzimuth >= 225.0) && (absoluteAzimuth < 315.0))
      elsif facade == 'All'
        # no next needed
      else
        runner.registerError('Unexpected value of facade: ' + facade + '.')
        return false
      end
      exterior_walls = true

      # get surface area adjusting for zone multiplier
      space = s.space
      if !space.empty?
        zone = space.get.thermalZone
      end
      if !zone.empty?
        zone_multiplier = zone.get.multiplier
        if (zone_multiplier > 1) && !space_warning_issued.include?(space.get.name.to_s)
          runner.registerInfo("Space #{space.get.name} in thermal zone #{zone.get.name} has a zone multiplier of #{zone_multiplier}. Adjusting area calculations.")
          space_warning_issued << space.get.name.to_s
        end
      else
        zone_multiplier = 1 # space is not in a thermal zone
        runner.registerWarning("Space #{space.get.name} is not in a thermal zone and won't be included in in the simulation. Windows will still be altered with an assumed zone multiplier of 1")
      end
      surface_gross_area = s.grossArea * zone_multiplier

      # loop through sub surfaces and add area including multiplier
      ext_window_area = 0
      has_doors = false
      s.subSurfaces.sort.each do |subSurface|
        # stop if non window or glass door
        if subSurface.subSurfaceType == 'Door' || subSurface.subSurfaceType == 'OverheadDoor'
          if split_at_doors == 'Remove Doors'
            subSurface.remove
          else
            has_doors = true
          end
          next
        end
        ext_window_area += subSurface.grossArea * subSurface.multiplier * zone_multiplier
        if subSurface.multiplier > 1
          runner.registerInfo("Sub-surface #{subSurface.name} in space #{space.get.name} has a sub-surface multiplier of #{subSurface.multiplier}. Adjusting area calculations.")
        end
      end

      starting_gross_ext_wall_area += surface_gross_area
      starting_ext_window_area += ext_window_area

      all_surfaces = [s]
      if split_at_doors == 'Split Walls at Doors' && has_doors
        # split base surfaces at doors to create  multiple base surfaces
        split_surfaces = s.splitSurfaceForSubSurfaces.to_a # frozen array

        # add original surface to new surfaces
        split_surfaces.sort.each do |ss|
          all_surfaces << ss
        end
      end

      if wwr > 0 && triangulate

        all_surfaces2 = []
        all_surfaces.sort.each do |ss|
          # see if surface is rectangular (only checking non rotated on vertical wall)
          # todo - add in more robust rectangle check that can look for rotate and tilted rectangles
          rect_tri = false
          x_vals = []
          y_vals = []
          z_vals = []
          vertices = ss.vertices
          flag = false
          vertices.each do |vertex|
            # initialize new vertex to old vertex
            # rounding values to address tolerance issue 10 digits digits in
            x_vals << vertex.x.round(8)
            y_vals << vertex.y.round(8)
            z_vals << vertex.z.round(8)
          end
          if x_vals.uniq.size <= 2 && y_vals.uniq.size <= 2 && z_vals.uniq.size <= 2
            rect_tri = true
          end

          has_doors = false
          ss.subSurfaces.sort.each do |subSurface|
            if subSurface.subSurfaceType == 'Door' || subSurface.subSurfaceType == 'OverheadDoor'
              has_doors = true
            end
          end

          if has_doors || rect_tri
            all_surfaces2 << ss
            next
          end

          # add triangulated surfaces
          # todo - bring in more attributes

          # get construction from sub-surfaces and then delete them
          pre_tri_sub_const = {}
          ss.subSurfaces.sort.each do |subSurface|
            if subSurface.construction.is_initialized && !subSurface.isConstructionDefaulted
              if pre_tri_sub_const.key?(subSurface.construction.get)
                pre_tri_sub_const[subSurface.construction.get] = subSurface.grossArea
              else
                pre_tri_sub_const[subSurface.construction.get] = + subSurface.grossArea
              end
            end
            subSurface.remove
          end

          ss.triangulation.each do |tri|
            new_surface = OpenStudio::Model::Surface.new(tri, model)
            new_surface.setSpace(ss.space.get)
            if ss.construction.is_initialized && !ss.isConstructionDefaulted
              new_surface.setConstruction(ss.construction.get)
            end
            if !pre_tri_sub_const.empty?
              non_rect_parent[new_surface] = pre_tri_sub_const.key(pre_tri_sub_const.values.max)
            end
            all_surfaces2 << new_surface
          end

          # remove orig surface
          ss.remove
        end

      else
        all_surfaces2 = all_surfaces
      end

      # add windows
      all_surfaces2.sort.each do |ss|
        orig_sub_surf_constructions = {}
        ss.subSurfaces.sort.each do |sub_surf|
          next if sub_surf.subSurfaceType == 'Door' || sub_surf.subSurfaceType == 'OverheadDoor'
          if sub_surf.construction.is_initialized
            if orig_sub_surf_constructions.key?(sub_surf.construction.get)
              orig_sub_surf_constructions[sub_surf.construction.get] += 1
            else
              orig_sub_surf_constructions[sub_surf.construction.get] = 1
            end
          end
        end

        # remove windows if ratio 0 or add in other cases
        if wwr == 0
          # remove all sub surfaces
          ss.subSurfaces.sort.each(&:remove)
          new_window = []
          window_confirmed = true
        else
          new_window = ss.setWindowToWallRatio(wwr, sillHeight_si.value, true)
          window_confirmed = false
        end

        if wwr > 0 && new_window.empty?

          # if new window is empty then inset base surface to add window (check may need to skip on base surfaces with doors)
          if inset_tri_sub

            # skip of surface already has sub-surfaces or if not triangle
            if ss.subSurfaces.empty? && ss.vertices.size <= 3
              # get centroid
              vertices = ss.vertices
              centroid = OpenStudio.getCentroid(vertices).get
              x_cent = centroid.x
              y_cent = centroid.y
              z_cent = centroid.z

              # reduce vertices towards centroid
              scale = Math.sqrt(wwr)
              new_vertices = OpenStudio::Point3dVector.new
              vertices.each do |vertex|
                x = (vertex.x * scale + x_cent * (1.0 - scale))
                y = (vertex.y * scale + y_cent * (1.0 - scale))
                z = (vertex.z * scale + z_cent * (1.0 - scale))
                new_vertices << OpenStudio::Point3d.new(x, y, z)
              end

              # create inset window
              new_window = OpenStudio::Model::SubSurface.new(new_vertices, model)
              new_window.setSurface(ss)
              new_window.setSubSurfaceType('FixedWindow')
              if non_rect_parent.key?(ss)
                new_window.setConstruction(non_rect_parent[ss])
              end
              window_confirmed = true
            end

          end
        else
          if wwr > 0
            new_window = new_window.get
          end
          window_confirmed = true
        end

        if !window_confirmed
          runner.registerWarning("Fenestration could not be added for #{ss.name}. Surface may not be rectangular or triangular, may have a door, or the requested WWR may be too large.")
        end

        # warn user if resulting window doesn't have a construction, as it will result in failed simulation. In the future may use logic from starting windows to apply construction to new window.
        if wwr > 0 && window_confirmed && new_window.construction.empty?
          # construction search order (orig window on this base surface, window in this orientation, andy window in building)
          if !orig_sub_surf_constructions.empty?
            new_window.setConstruction(orig_sub_surf_constructions.key(orig_sub_surf_constructions.values.max))
          elsif !orig_sub_surf_const_for_target_facade.empty?
            new_window.setConstruction(orig_sub_surf_const_for_target_facade.key(orig_sub_surf_const_for_target_facade.values.max))
            facade_const_warning = true
          elsif !orig_sub_surf_const_for_target_all_ext.empty?
            new_window.setConstruction(orig_sub_surf_const_for_target_all_ext.key(orig_sub_surf_const_for_target_all_ext.values.max))
            bldg_const_warning = true
          else
            empty_const_warning = true
            if catchall_glazing_const.nil?
              material = OpenStudio::Model::SimpleGlazing.new(model)
              material.setUFactor(2.556)
              material.setSolarHeatGainCoefficient(0.764)
              material.setVisibleTransmittance(0.812)
              catchall_glazing_const = OpenStudio::Model::Construction.new(model)
              catchall_glazing_const.insertLayer(0, material)
              catchall_glazing_const.setName('Dbl Clr 3mm/13mm Air') # from E+ dataset
            end
            new_window.setConstruction(catchall_glazing_const)
          end
        end
      end
    end

    # warn if some constructions do not have sub-surfaces
    if facade_const_warning
      runner.registerInfo('One or more new sub-surfaces did not have construction, using most commonly used construction for this facade.')
    end
    if bldg_const_warning
      runner.registerInfo('One or more new sub-surfaces did not have construction, using most commonly used construction across the entire building.')
    end
    if empty_const_warning
      # TODO: - add in catchall like something equiv to double glazed of glass with new simple glazing construction
      runner.registerWarning("Could not find existing window with construction as guide for new windows. Using a catchall glazing of #{catchall_glazing_const.name}.")
    end

    # report initial condition wwr
    # the initial and final ratios does not currently account for either sub-surface or zone multipliers.
    starting_wwr = format('%.02f', (starting_ext_window_area / starting_gross_ext_wall_area))
    runner.registerInitialCondition("The model's initial window to wall ratio for #{facade} facing exterior walls was #{starting_wwr}.")

    if !exterior_walls
      runner.registerAsNotApplicable("The model has no exterior #{facade.downcase} walls and was not altered")
      return true
    elsif !window_confirmed
      runner.registerAsNotApplicable("The model has exterior #{facade.downcase} walls, but no windows could be added with the requested window to wall ratio")
      return true
    end

    # data for final condition wwr
    surfaces.sort.each do |s|
      next if s.surfaceType != 'Wall'
      next if s.outsideBoundaryCondition != 'Outdoors'
      if s.space.empty?
        runner.registerWarning("#{s.name} doesn't have a parent space and won't be included in the measure reporting or modifications.")
        next
      end

      # get the absoluteAzimuth for the surface so we can categorize it
      absoluteAzimuth = OpenStudio.convert(s.azimuth, 'rad', 'deg').get + s.space.get.directionofRelativeNorth + model.getBuilding.northAxis
      absoluteAzimuth -= 360.0 until absoluteAzimuth < 360.0

      if facade == 'North'
        next if !((absoluteAzimuth >= 315.0) || (absoluteAzimuth < 45.0))
      elsif facade == 'East'
        next if !((absoluteAzimuth >= 45.0) && (absoluteAzimuth < 135.0))
      elsif facade == 'South'
        next if !((absoluteAzimuth >= 135.0) && (absoluteAzimuth < 225.0))
      elsif facade == 'West'
        next if !((absoluteAzimuth >= 225.0) && (absoluteAzimuth < 315.0))
      elsif facade == 'All'
        # no next needed
      else
        runner.registerError('Unexpected value of facade: ' + facade + '.')
        return false
      end

      # get surface area adjusting for zone multiplier
      space = s.space
      if !space.empty?
        zone = space.get.thermalZone
      end
      if !zone.empty?
        zone_multiplier = zone.get.multiplier
        if zone_multiplier > 1
        end
      else
        zone_multiplier = 1 # space is not in a thermal zone
      end
      surface_gross_area = s.grossArea * zone_multiplier

      # loop through sub surfaces and add area including multiplier
      ext_window_area = 0
      s.subSurfaces.sort.each do |subSurface| # onlky one and should have multiplier of 1
        ext_window_area += subSurface.grossArea * subSurface.multiplier * zone_multiplier
      end

      final_gross_ext_wall_area += surface_gross_area
      final_ext_window_area += ext_window_area
    end

    # get delta in ft^2 for final - starting window area
    increase_window_area_si = OpenStudio::Quantity.new(final_ext_window_area - starting_ext_window_area, unit_area_si)
    increase_window_area_ip = OpenStudio.convert(increase_window_area_si, unit_area_ip).get

    # calculate final envelope cost as positive value
    constructions = model.getConstructions.sort
    constructions.each do |construction|
      const_llcs = construction.lifeCycleCosts
      const_llcs.sort.each do |const_llc|
        if const_llc.category == 'Construction'
          envelope_cost += const_llc.totalCost
        end
      end
    end

    # report final condition
    final_wwr = format('%.02f', (final_ext_window_area / final_gross_ext_wall_area))
    runner.registerFinalCondition("The model's final window to wall ratio for #{facade} facing exterior walls is #{final_wwr}. Window area increased by #{OpenStudio::toNeatString(increase_window_area_ip.value, 0)} (ft^2). The material and construction costs increased by $#{OpenStudio::toNeatString(envelope_cost, 0)}.")

    return true
  end
end

# this allows the measure to be used by the application
SetWindowToWallRatioByFacade.new.registerWithApplication
