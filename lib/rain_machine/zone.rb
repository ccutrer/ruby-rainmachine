# frozen_string_literal: true

module RainMachine
  class Zone
    attr_reader :uid, :name, :state, :enabled, :user_duration, :machine_duration, :remaining, :cycle,
                :cycle_count, :restricted, :master

    def initialize(device, uid)
      @device = device
      @uid = uid
    end

    def update(attrs)
      assign(:name, attrs["name"])
      assign(:state, case attrs["state"]
                     when 0 then :not_running
                     when 1 then :running
                     when 2 then :queued
                     end)
      assign(:enabled, attrs["active"])
      assign(:user_duration, attrs["userDuration"].to_i)
      assign(:machine_duration, attrs["machineDuration"])
      assign(:remaining, attrs["remaining"])
      assign(:cycle, attrs["cycle"])
      assign(:cycle_count, attrs["noOfCycles"])
      assign(:restricted, attrs["restriction"])
      assign(:master, attrs["master"])
    end

    private

    def assign(ivar, value)
      return if instance_variable_get(:"@#{ivar}") == value

      instance_variable_set(:"@#{ivar}", value)
      @device.notifier&.call(self, ivar, value)
    end
  end
end
