# *******************************************************************************
# OpenStudio(R), Copyright (c) Alliance for Sustainable Energy, LLC.
# See also https://openstudio.net/license
# *******************************************************************************

require 'openstudio/model_articulation/version'
require 'openstudio/extension'

module OpenStudio
  module ModelArticulation
    class Extension < OpenStudio::Extension::Extension
      # Override the base class
      def initialize
        super

        @root_dir = File.absolute_path(File.join(File.dirname(__FILE__), '..', '..', '..'))
      end
    end
  end
end
