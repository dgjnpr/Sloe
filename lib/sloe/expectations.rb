# include it globally in a spec_helper.rb file <tt>require</tt>d
# from your spec file(s):
#     require 'sloe/expectations'
#
#     RSpec::configure do |config|
#       config.include(Sloe::Expectations::Ixia)
#       config.include(Sloe::Expectations::Junos)
#     end
module Sloe
  module Expectations
    module Ixia
      def have_no_packet_loss
        HaveNoPacketLoss.new
      end

      def have_packet_loss_duration_less_than(duration)
        HavePacketLossDurationLessThan.new(duration)
      end

      class HavePacketLossDurationLessThan
        def initialize(duration)
          @duration = duration
        end

        def match(actual)
          @lossy_flows = actual.select do |row|
            if row['Packet Loss Duration (ms)'].to_f > @duration.to_f
              "#{row['Traffic Item']}\t #{row['Source/Dest Endpoint Pair']}:\t\t #{row['Packet Loss Duration (ms)']}\n"
            end
          end
          @lossy_flows.size == 0
        end

        def failure_message_for_should
          @lossy_flows
        end
      end

      class HaveNoPacketLoss
        def match(actual)
          @lossy_flows = actual.select do |row|
            if row['Loss %'].to_f > 0.0
              "#{row['Source/Dest Endpoint Pair']}:\t\t#{row['Loss %']}\n"
            end
          end
          @lossy_flows.size == 0
        end

        def failure_message_for_should
          @lossy_flows
        end
      end
    end

    class Junos
      def have_pim_neighbor_on_all_interfaces
        HavePimNeighborOnAllInterfaces.new
      end

      def non_jnpr_sfp
        NonJnprSfp.new
      end

      def have_all_ospf_neighbors_as(state)
        HaveAllOspfNeighborsAs.new(state)
      end

      def have_all_bgp_peers_as(state)
        HaveAllBgpPeersAs.new(state)
      end

      class HaveAllOspfNeighborsAs
        def initialize(state)
          @state = state
        end

        def match(actual)
          data = XmlSimple.xml_in(actual.to_xml)
          @no_match = data['ospf-neighbor'].select do |neighbor|
            if neighbor['ospf-neighbor-state'][0] != @state
              "#{neighbor['neighbor-address'][0]} state is #{neighbor['os
              pf-neighbor-state'][0]}"
            end
          end
          @no_match.size == 0
        end

        def failure_message
          @no_match
        end
      end

      class NonJnprSfp
        def match(actual)
          actual.text.strip != "NON-JNPR"
        end
        
        def failure_message_for_should_not
          'Found NON Juniper SFP on chassis'
        end
      end

      class HaveAllBgpPeersAs
        def match(actual)
          @no_match = actual.xpath('//bgp-peer').each do |peer|
            if peer.xpath('peer-state').text != @state
              "#{peer.xpath('peer-address').text} state is #{peer.xpath('peer-state').text}"
            end
          end
          @no_match.size == 0
        end

        def failure_message
          @no_match
        end
      end

      class HavePimNeighborOnAllInterfaces
        def match(actual)
          @pim_int_without_neighbor = actual.xpath('//pim-interface[contains(pim-interface-name,"ae")]').map do |int|
            if int.xpath('neighbor-count').text.to_i == 0
              "#{int.xpath('pim-interface-name').text} has no neighbors"
            end
          end
          @pim_int_without_neighbor.size == 0
        end

        def failure_message_for_should
          @pim_int_without_neighbor
        end
      end
    end
  end
end
