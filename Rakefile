require 'bundler/gem_tasks'
require 'rspec/core/rake_task'
require 'pry-byebug'

RSpec::Core::RakeTask.new(:spec) do |task|
  task.rspec_opts = ['--color', '--format', 'doc']
end

task default: :spec
task spec: ['vm:start']

require 'rubocop/rake_task'
RuboCop::RakeTask.new

namespace :vm do
  require 'derelict'
  desc 'list VMs'
  task :list do
    Dir.chdir 'vqfx10k' do
      puts FileList['*'].select { |d| File.directory?(d) }
    end
  end

  desc 'given VM(s) state'
  task :status, :name do |_, args|
    raise ArgumentError, 'missing vagrant project name' unless args.name

    project = Derelict.instance('/usr/local').connect 'vqfx10k/' + args.name
    (1..args.name.match(/\d/)[0].to_i).each do |n|
      vm = project.vm("vqfx#{n}".to_sym)
      puts "vqfx#{n} status is #{vm.state}"
    end
  end

  desc 'start given VM(s)'
  task :start, :na do |_, args|
    raise ArgumentError, 'missing vagrant project name' unless args.name

    project = Derelict.instance('/usr/local').connect 'vqfx10k/' + args.name
    (1..args.name.match(/\d/)[0].to_i).each do |n|
      res = project.vm("vqfx#{n}".to_sym).up!
      raise "failed to start vqfx#{n}: res.stderr" unless res.success?
      puts "vqfx#{n} status is " + project.vm("vqfx#{n}".to_sym).state.to_s
    end
  end

  desc 'stop given VM(s)'
  task :stop, :name do |_, args|
    raise ArgumentError, 'missing vagrant project name' unless args.name

    project = Derelict.instance('/usr/local').connect 'vqfx10k/' + args.name
    (1..args.name.match(/\d/)[0].to_i).each do |n|
      res = project.vm("vqfx#{n}".to_sym).halt!
      raise "failed to start vqfx#{n}: res.stderr" unless res.success?
      puts "vqfx#{n} status is " + project.vm("vqfx#{n}".to_sym).state.to_s
    end
  end
end
