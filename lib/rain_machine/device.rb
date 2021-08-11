# frozen_string_literal: true

require "active_support/core_ext/enumerable"
require "faraday_middleware"
require "rain_machine/zone"

module RainMachine
  class Device
    attr_reader :ip_address, :id, :name, :model, :api_version, :zones, :notifier

    def initialize(url, access_token: nil, password: nil)
      raise ArgumentError, "must provide either access_token or password" unless access_token || password

      @conn = Faraday.new(url: url) do |f|
        f.request :json
        f.request :retry
        f.response :raise_error
        f.response :json
        f.adapter :net_http_persistent
      end
      @conn.path_prefix << "api/4/"

      access_token ||= @conn.post("auth/login", { pwd: password }).body["access_token"]
      @conn.params[:access_token] = access_token

      switch_to_local

      vers = @conn.get("apiVer").body
      @model = case vers["hwVer"]
               when 2 then "RainMachine Mini 8"
               when 3 then "RainMachine Touch HD"
               when 5 then "RainMachine Pro"
               else "Unknown"
               end
      @api_version = vers["apiVer"]

      provision = @conn.get("provision").body
      @name = provision["system"]["netName"]

      @id = @conn.get("provision/cloud").body["sprinklerID"]

      @zones = @conn.get("zone").body["zones"].map do |attrs|
        Zone.new(self, attrs["uid"]).tap { |z| z.update(attrs) }
      end.index_by(&:uid).freeze
    end

    def on_update(&block)
      @notifier = block
    end

    def update
      @conn.get("zone").body["zones"].each do |attrs|
        next unless (zone = @zones[attrs["uid"]])

        zone.update(attrs)
      end
    end

    private

    def switch_to_local
      @ip_address = @conn.get("provision/wifi").body["ipAddress"]

      return unless @conn.host == "api.rainmachine.com"

      ipaddr = IPAddr.new(@ip_address)
      use_local = Socket.getifaddrs.any? do |ifaddr|
        next unless ifaddr.addr.ip?

        IPAddr.new("#{ifaddr.addr.ip_address}/#{ifaddr.netmask.ip_address}").include?(ipaddr)
      end
      return unless use_local

      original_url = @conn.url_prefix
      @conn.url_prefix = "http://#{@ip_address}:8081/api/4/"
      @conn.options.open_timeout = 0.5
      begin
        @conn.get("apiVer")
      rescue Faraday::ConnectionFailed
        @conn.url_prefix = original_url
      end
    end
  end
end
