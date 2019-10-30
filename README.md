# OpenStudio ModelArticulation

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

## Usage

To be filled out later. 

## TODO

- [ ] Move articulation measures from openstudio-measures
- [ ] Move articulation measure lib files to openstudio-extension lib
- [ ] Update measures to correct naming conventions 

# Releasing

* Update CHANGELOG.md
* Run `rake rubocop:auto_correct`
* Update version in `/lib/openstudio/model-articulation/version.rb`
* Create PR to master, after tests and reviews complete, then merge
* Locally - from the master branch, run `rake release`
* On GitHub, go to the releases page and update the latest release tag. Name it “Version x.y.z” and copy the CHANGELOG entry into the description box.
