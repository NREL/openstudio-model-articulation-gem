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

# Only uncomment if you need to test a different version of the extension gem that is not
# included in the openstudio-common-measures
# if allow_local && File.exist?('../OpenStudio-extension-gem')
#   gem 'openstudio-extension', path: '../OpenStudio-extension-gem'
# elsif allow_local
#   gem 'openstudio-extension', github: 'NREL/OpenStudio-extension-gem', branch: 'develop'
# end

if allow_local && File.exist?('../openstudio-common-measures-gem')
  gem 'openstudio-common-measures', path: '../openstudio-common-measures-gem'
elsif allow_local
  gem 'openstudio-common-measures', github: 'NREL/openstudio-common-measures-gem', branch: 'develop'
end

# simplecov has an unnecessary dependency on native json gem, use fork that does not require this
gem 'simplecov', github: 'NREL/simplecov'
