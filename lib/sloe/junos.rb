require 'net/netconf/jnpr'
require 'sloe/common'
require 'fileutils'

module Sloe
  # Class for working with Netconf device that supports Junos specifc Netconf extensions
  class Junos < Sloe::Common

    # Create Sloe::Junos object. It takes the same arguments as Sloe::Common
    #
    # @param args [Hash] key value pairs of arguments for object
    # @param block [Code] code block that will be executed once object created
    # @return [Sloe::Junos] object that interacts with a Junos device
    def initialize( args, &block )
        super( args, &block )
    end

    # execute CLI commands over NETCONF transport returns plain text, rather than XML, by default
    # 
    # @param cmd_str [String] A valid Junos CLI command.
    # @param attrs [Hash] Supports same attributes as {http://rubydoc.info/gems/netconf/Netconf/RPC/Junos:command Junos#command}
    # @return nil if command returns no text. Otherwise returns text in format requested (default is plain text)
    def cli(cmd_str, attrs = { :format => 'text' })
      attrs[:format] ||= 'text'     # set format to text if attrs supplied but user forgot to set format
      @reply = self.rpc.command(cmd_str, attrs)
      @reply.respond_to?(:text) ? @reply.text : @reply
    end

    def setup( yaml, junos, conf_attr = {:format => 'text', :action => 'merge'} )
      # write something here
    end

    # convience method for applying configuration
    # 
    # @param config [String] Valid Junos configuration. Supports all notation formats
    # @param attrs [Hash] Valid attributes found at {http://www.juniper.net/techpubs/en_US/junos13.1/information-products/topic-collections/junos-xml-management-protocol-guide/index.html?topic-49518.html}
    # @return 
    def apply_config( config, attrs = {:format => 'text', :action => 'merge'} )
      raise ArgumentError unless config
      
      self.rpc.lock_configuration
      @reply = self.rpc.load_configuration( config, attrs )
      self.rpc.commit_configuration
      self.rpc.unlock_configuration

      @reply.xpath('load-configuration-results/load-success') ? true : @reply
    end

    def upgrade_junos( url )
      @re = self.rpc.get_route_engine_information.xpath('route-engine/mastership-state')
      args = {
        :package_name => url,
        :reboot => true,
        :no_copy => true,
        :unlink => true
      }

      # if dual RE perform upgrade on backup RE first
      if @re.size == 1
        self.rpc.request_package_add( args )
      elsif @re[0].inner_text == "master"
        args[:re1] = true
        @upgrade = self.rpc.request_package_add( args )
        raise UpgradeError, @upgrade.xpath('//output') if @upgrade.xpath('//package-result').text.to_i != 0
        args[:re0] = true
        args.delete(:re1)
        @upgrade = self.rpc.request_package_add( args )
        raise UpgradeError, @upgrade.xpath('//output') if @upgrade.xpath('//package-result').text.to_i != 0
      else
        args[:re0] = true
        @upgrade = self.rpc.request_package_add( args )
        raise UpgradeError, @upgrade.xpath('//output') if @upgrade.xpath('//package-result').text.to_i != 0
        args.delete(:re0)
        args[:re1] = true
        @upgrade = self.rpc.request_package_add( args )
        raise UpgradeError, @upgrade.xpath('//output') if @upgrade.xpath('//package-result').text.to_i != 0
      end

      # close connection so we maintain same object while router reboots
      self.close

      sleep 1800 # give the RE 20 mins to upgrade

      # re-establish connection once upgrade complete
      self.open
      true
    end
  end
end
