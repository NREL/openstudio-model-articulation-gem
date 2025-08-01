# OpenStudio(R) ModelArticulation

Library and measures for OpenStudio Model Articulation.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'openstudio-model-articulation'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install 'openstudio-model-articulation'

## Tests

To run the tests similar to how Jenkins run:

```
bundle install

bundle exec rake
bundle exec rake openstudio:list_measures
bundle exec rake openstudio:update_measures
bundle exec rake openstudio:test_with_openstudio
```

To run the tests the same way Jenkins run:

```
docker run -it -v $(pwd):/var/simdata/openstudio -u root -e "LANG=en_US.UTF-8" nrel/openstudio:3.0.0-beta-ruby-slim bash

# inside the container
gem install bundler -v '~> 2.1'
bundle update

# Run all the tests
bundle exec rake openstudio:test_with_openstudio

# or a sinlge measure's test, e.g.,
/usr/local/openstudio-3.0.0-beta/bin/openstudio-3.0.0-beta --verbose --bundle '/var/simdata/openstudio/Gemfile' --bundle_path '/var/simdata/openstudio/.bundle/install/' measure -r '/var/simdata/openstudio/lib/measures/radiance_measure/'
```

# Compatibility Matrix

|OpenStudio Model Articulation Gem|OpenStudio|Ruby|
|:--------------:|:----------:|:--------:|
| 0.12.1         | 3.10     | 3.2.2  |
| 0.12.0         | 3.10     | 3.2.2  |
| 0.11.1         | 3.9      | 3.2.2  |
| 0.11.0         | 3.9      | 3.2.2  |
| 0.10.0         | 3.8      | 3.2.2  |
| 0.9.0          | 3.7      | 2.7    |
| 0.8.0          | 3.6      | 2.7    |
| 0.7.0          | 3.5      | 2.7    |
| 0.6.0 - 0.6.1  | 3.4      | 2.7    |
| 0.5.0          | 3.3      | 2.7    |
| 0.4.0 - 0.4.2  | 3.2      | 2.7    |
| 0.3.0 - 0.3.1  | 3.1      | 2.5    |
| 0.2.0 - 0.2.1  | 3.0      | 2.5    |
| 0.1.1 and below | 2.9 and below      | 2.2.4    |

# Contributing 

Please review the [OpenStudio Contribution Policy](https://openstudio.net/openstudio-contribution-policy) if you would like to contribute code to this gem.

## TODO

- [x] Move articulation measures from openstudio-measures
- [x] Move articulation measure lib files to openstudio-extension lib
- [ ] Update measures to correct naming conventions 

# Releasing

* Update CHANGELOG.md
* Run `rake openstudio:rubocop:auto_correct`
* Run `rake openstudio:update_copyright`
* Run `rake openstudio:update_measures` (this has to be done last since prior tasks alter measure files)
* Update version in `readme.md`
* Review dependency versions in `openstudio-model-articulation.gemspec` (especially openstudio-standards and openstudio-extension)
* Update version in `/lib/openstudio/model_articulation/version.rb`. Do not create a patch release if there are breaking changes or if this new version will support a biannual OpenStudio release; make a "minor" release instead. (ex: going from 0.7.0 to 0.8.0)
* Create PR to master, after tests and reviews complete, then merge
* Locally - from the master branch, run `rake release`
* On GitHub, go to the releases page and update the latest release tag. Name it “Version x.y.z” and copy the CHANGELOG entry into the description box.
