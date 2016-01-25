# -*- encoding: utf-8 -*-
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'sloe/version'

Gem::Specification.new do |gem|
  gem.name          = "sloe"
  gem.version       = Sloe::VERSION
  gem.authors       = ["David Gethings"]
  gem.email         = ["dgjnpr@gmail.com"]
  gem.description   = %q{Sloe uses NETCONF and/or SNMP to gather data regarding a network device. Designed to help with automated testing this gem can also be used with things like Ruby on Rails}
  gem.summary       = %q{A one stop shop for collecting data from a network device using NETCONF or SNMP}
  gem.homepage      = "https://github.com/dgjnpr/Sloe"

  gem.add_dependency('snmp', '~> 1.2')
  gem.add_dependency('net-netconf', '~> 0.3')
  gem.add_dependency('net-scp', '~> 1.2')
  gem.add_development_dependency('rspec', '~> 3.4')
  gem.add_development_dependency('yard', '~> 0.8')
  gem.add_development_dependency('simplecov', '~> 0.11')
  gem.add_development_dependency('ci_reporter', '~> 2.0')
  gem.add_development_dependency('ci_reporter_rspec')
  gem.add_development_dependency('rake', '>= 10')
  gem.add_development_dependency('pry-byebug', '~> 3.3')

  gem.files         = `git ls-files`.split($/)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.require_paths = ["lib"]
end
