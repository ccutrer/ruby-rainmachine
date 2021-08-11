# frozen_string_literal: true

require "homie-mqtt"

module RainMachine
  module CLI
    class MQTT
      attr_reader :device, :homie

      def initialize(device, homie)
        @device = device
        @homie = homie

        @device.zones.each_value do |zone|
          @homie.node("zone#{zone.uid}", zone.name, "Zone") do |node|
            node.property("state", "Watering status", :enum, zone.state, format: %w[not_running running queued])
            node.property("enabled", "Can be watered and added to watering programs", :boolean, zone.enabled)
            node.property("user-duration", "Duration that was set for water", :integer, zone.user_duration, unit: "s")
            node.property("machine-duration", "Duration of actual watering that was calculated by RainMachine", :integer, zone.machine_duration, unit: "s")
            node.property("remaining", "Remaining duration when water has started",
                          :integer, zone.remaining, unit: "s")
            node.property("cycle", "Current cycle", :integer, zone.cycle)
            node.property("cycle-count", "Number of cycles", :integer, zone.cycle_count)
            node.property("restricted", "If the zone is any current restrictions", :boolean, zone.restricted)
            node.property("master", "If the zone is set as master valve", :boolean, zone.master)
          end
        end

        @homie.publish

        @device.on_update do |zone, field, new_value|
          property = @homie["zone#{zone.uid}"][field.to_s.tr("_", "-")]
          next unless property

          property.value = new_value
        end

        loop do
          sleep 5
          @device.update
        end
      end
    end
  end
end
