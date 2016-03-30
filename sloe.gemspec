# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'sloe/version'

Gem::Specification.new do |spec|
  spec.name          = 'sloe'
  spec.version       = Sloe::VERSION
  spec.authors       = ['David Gethings']
  spec.email         = ['dgjnpr@gmail.com']
  spec.homepage      = 'https://github.com/dgjnpr/Sloe'
  spec.license       = 'MIT'
  spec.description   = <<-DESC
Sloe uses NETCONF and/or SNMP to gather data regarding a network device. Designed to help with automated testing this gem can also be used with things like Ruby on Rails
DESC
  spec.summary       = <<-SUMM
A one stop shop for collecting data from a network device using NETCONF or SNMP
SUMM

  spec.add_dependency 'snmp', '~> 1.1'
  spec.add_dependency 'netconf', '~> 0.3'
  spec.add_dependency 'net-scp', '~> 1.0'
  spec.add_development_dependency 'bundler', '~> 1.11'
  spec.add_development_dependency 'rspec', '~> 2.12'
  spec.add_development_dependency 'yard', '~> 0.8'
  spec.add_development_dependency 'pry-byebug', '~> 3.3'
  spec.add_development_dependency 'simplecov', '~> 0.11'
  spec.add_development_dependency 'rake', '~> 11.1'
  spec.add_development_dependency 'rubocop', '~> 0.39'

  spec.files         = `git ls-files`.split($INPUT_RECORD_SEPARATOR)
  spec.executables   = spec.files.grep(%r{^bin/}).map { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ['lib']
end
