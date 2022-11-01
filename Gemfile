source 'http://rubygems.org'

# Specify your gem's dependencies in openstudio-model-articulation.gemspec
gemspec

# Local gems are useful when developing and integrating the various dependencies.
# To favor the use of local gems, set the following environment variable:
#   Mac: export FAVOR_LOCAL_GEMS=1
#   Windows: set FAVOR_LOCAL_GEMS=1
# Note that if allow_local is true, but the gem is not found locally, then it will
# checkout the latest version (develop) from github.
allow_local = ENV['FAVOR_LOCAL_GEMS']

# uncomment when you want CI to use develop branch of extension gem
#gem 'openstudio-extension', github: 'NREL/OpenStudio-extension-gem', branch: 'v0.6.0-rc1'

# uncomment when you want CI to use develop branch of openstudio-standards gem
#gem 'openstudio-standards', github: 'NREL/OpenStudio-standards', branch: 'master'
#gem 'openstudio-standards', '= 0.2.17.rc1', :github => 'NREL/openstudio-standards', :ref => '3.5.0_changes'

# Only uncomment if you need to test a different version of the extension gem
# if allow_local && File.exist?('../OpenStudio-extension-gem')
#   gem 'openstudio-extension', path: '../OpenStudio-extension-gem'
# elsif allow_local
#   gem 'openstudio-extension', github: 'NREL/OpenStudio-extension-gem', branch: 'develop'
# end
