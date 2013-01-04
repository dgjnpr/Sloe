# -*- encoding: utf-8 -*-
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'sloe/version'

Gem::Specification.new do |gem|
  gem.name          = "sloe"
  gem.version       = Sloe::VERSION
  gem.authors       = ["David Gethings"]
  gem.email         = ["dgethings@juniper.net"]
  gem.description   = %q{Slow uses NETCONF and/or SNMP to gather data regarding a  Juniper device. Designed to help with automated testing this gem can also be used with things like Ruby on Rails}
  gem.summary       = %q{Sloe is a one stop shop for collecting data from a Juniper device using NETCONF or SNMP}
  gem.homepage      = ""

  gem.add_dependency('snmp')
  gem.add_dependency('netconf')
  gem.add_development_dependency('rspec')
  gem.add_development_dependency('yard')
  gem.add_development_dependency('ruby-debug19')

  gem.files         = `git ls-files`.split($/)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.require_paths = ["lib"]
end
