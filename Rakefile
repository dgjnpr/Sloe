require 'bundler/gem_tasks'
require 'rspec/core/rake_task'
require 'ci/reporter/rake/rspec'

RSpec::Core::RakeTask.new

task default: ['ci:setup:rspec', :spec]
task test: ['ci:setup:rspec', :spec]
