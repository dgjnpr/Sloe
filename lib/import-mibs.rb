#!/usr/bin/env ruby

require 'yaml'

def eval_mib_data(mib_hash)
  ruby_hash = mib_hash.
    gsub(':', '=>').                  # fix hash syntax
    gsub('(', '[').gsub(')', ']').    # fix tuple syntax
    sub('FILENAME =', 'filename =').  # get rid of constants
    sub('MIB =', 'mib =')
  mib = nil
  eval(ruby_hash)
  mib
end

def module_file_name(module_name, mib_dir)
  File.join(mib_dir, module_name + ".yaml")
end

raise "smidump tool must be installed" unless `smidump --version` =~ /^smidump 0.4/  && $? == 0
mib_hash = `smidump -k -p mib-jnx-smi.txt -f python #{ARGV[0]}`
mib = eval_mib_data(mib_hash)
if mib
  module_name = mib["moduleName"]
  raise "#{module_file}: invalid file format; no module name" unless module_name
  if mib["nodes"]
    oid_hash = {}
    mib["nodes"].each { |key, value| oid_hash[key] = value["oid"] }
    if mib["notifications"]
      mib["notifications"].each { |key, value| oid_hash[key] = value["oid"] }
    end
    File.open(module_file_name(module_name, ARGV[1]), 'w') do |file|
      YAML.dump(oid_hash, file)
      file.puts
    end
    module_name
  else
    warn "*** No nodes defined in: #{module_file} ***"
    nil
  end
else
  warn "*** Import failed for: #{module_file} ***"
  nil
end
