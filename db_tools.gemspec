# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'db_tools/version'

Gem::Specification.new do |spec|
  spec.name          = 'db_tools'
  spec.version       = DbTools::VERSION
  spec.authors       = ['Robert Birch']
  spec.email         = ['robdbirch@gmail.com']
  spec.summary       = %q{Import/Export data models}
  spec.description   = %q{A hasty utility to back up data based on a dependency between mongo and postgres and zip and store the backups in G-Drive.}
  spec.homepage      = 'http://www.noxaos.com'
  spec.license       = 'MIT'

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f|   File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ['lib']

  spec.add_runtime_dependency 'awesome_print', '~> 1.2'
  spec.add_runtime_dependency'pg', '~> 0.17'
  spec.add_runtime_dependency 'mongo', '~> 1.10'
  spec.add_runtime_dependency 'bson_ext', '~> 1.10'
  spec.add_runtime_dependency 'google-api-client', '~> 0.7'

  spec.add_development_dependency 'bundler', '~> 1.5'
  spec.add_development_dependency 'rake', '~> 10.0'
end
