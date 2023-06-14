# *******************************************************************************
# OpenStudio(R), Copyright (c) Alliance for Sustainable Energy, LLC.
# See also https://openstudio.net/license
# *******************************************************************************

# see the URL below for information on how to write OpenStudio measures
# http://nrel.github.io/OpenStudio-user-documentation/measures/measure_writing_guide/

# start the measure
class CloneBuildingFromExternalModel < OpenStudio::Measure::ModelMeasure
  # human readable name
  def name
    return 'Clone Building From External Model'
  end

  # human readable description
  def description
    return "This measures clones the building in from an external model in place of the existing building in a model. In addition to changing the feilds in the building object itself, it will bring in meters, building story objects, shading surface groups, thermal zones, and spaces. This includes their children. Currently this doesn't included HVAC systems, site lighitng."
  end

  # human readable description of modeling approach
  def modeler_description
    return 'The intent of this measure is to provide a measure is to provide a way in a single analysis to use a collection of custom seed models. Your real seed model woudl be an empty model, maybe containing custom weather data and simulation settings, then you would have a variety of models with pre-generated builiding envelopes to choose from. They custom seeds coudl jsut have surraes, or could contain constructions, schedules, and loads.'
  end

  # define the arguments that the user will input
  def arguments(model)
    args = OpenStudio::Measure::OSArgumentVector.new

    # make an argument for external model
    external_model_name = OpenStudio::Measure::OSArgument.makeStringArgument('external_model_name', true)
    external_model_name.setDisplayName('External OSM File Name')
    external_model_name.setDescription('Name of the model to clone building from. This is the filename with the extension (e.g. MyModel.osm). Optionally this can inclucde the full file path, but for most use cases should just be file name.')
    args << external_model_name

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
    external_model_name = runner.getStringArgumentValue('external_model_name', user_arguments)

    # check the external_model_name for reasonableness
    if external_model_name == ''
      runner.registerError('No Source OSM File Path was Entered.')
      return false
    end

    # find external model
    osw_file = runner.workflow.findFile(external_model_name)
    if osw_file.is_initialized
      external_model_name = osw_file.get.to_s
    else
      runner.registerError("Did not find #{external_model_name} in paths described in OSW file.")
      return false
    end

    # load external model
    translator = OpenStudio::OSVersion::VersionTranslator.new
    path = OpenStudio::Path.new(external_model_name)
    model2 = translator.loadModel(path)
    if model2.empty?
      runner.registerError("Couldn't load #{path}.")
      return false
    else
      model2 = model2.get
    end

    # report how many spaces are in the external model
    runner.registerInfo("The external model has #{model2.getSpaces.size} spaces.")

    # report initial condition of model
    runner.registerInitialCondition("The building started with #{model.getSpaces.size} spaces.")

    # clone in building from external model
    building2 = model2.getBuilding
    building2.clone(model)

    # match surfaces (currently clone breaks surface matching, I'll do it here vs. adding a measure to workflow just for this)
    # put all of the spaces in the model into a vector
    spaces = OpenStudio::Model::SpaceVector.new
    model.getSpaces.each do |space|
      spaces << space
    end
    # match surfaces for each space in the vector
    OpenStudio::Model.matchSurfaces(spaces)
    runner.registerInfo('Matching surfaces..')

    # report final condition of model
    runner.registerFinalCondition("The building finished with #{model.getSpaces.size} spaces.")
    runner.registerValue('Building_Name', model.getBuilding.name.to_s)

    return true
  end
end

# register the measure to be used by the application
CloneBuildingFromExternalModel.new.registerWithApplication
