lib = File.expand_path('lib', __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'openstudio/model_articulation/version'

Gem::Specification.new do |spec|
  spec.name          = 'openstudio-model-articulation'
  spec.version       = OpenStudio::ModelArticulation::VERSION
  spec.platform      = Gem::Platform::RUBY
  spec.authors       = ['David Goldwasser']
  spec.email         = ['david.goldwasser@nrel.gov']

  spec.homepage      = 'https://openstudio.net'
  spec.summary       = 'Library and measures for OpenStudio Model Articulation'
  spec.description   = 'Library and measures for OpenStudio Model Articulation'
  spec.metadata = {
    'bug_tracker_uri' => 'https://github.com/NREL/openstudio-model-articulation-gem/issues',
    'changelog_uri' => 'https://github.com/NREL/openstudio-model-articulation-gem/blob/develop/CHANGELOG.md',
    # 'documentation_uri' =>  'https://www.rubydoc.info/gems/openstudio-model-articulation-gem/#{gem.version}',
    'source_code_uri' => "https://github.com/NREL/openstudio-model-articulation-gem/tree/v#{spec.version}"
  }

  spec.files = `git ls-files -z`.split("\x0").reject do |f|
    f.match(%r{^(test|lib.measures.*tests|spec|features)/})
  end
  spec.bindir = 'exe'
  spec.executables = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  spec.required_ruby_version = '~> 2.7.0'

  spec.add_dependency 'bundler', '~> 2.1'
  spec.add_dependency 'openstudio-extension', '~> 0.5.1'
  spec.add_dependency 'openstudio-standards', '~> 0.2.16.rc2'


  spec.add_development_dependency 'rake', '~> 13.0'
  spec.add_development_dependency 'rspec', '~> 3.9'
end
