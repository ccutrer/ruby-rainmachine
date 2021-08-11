# frozen_string_literal: true

require "faraday_middleware"
require "rain_machine/device"

module RainMachine
  class Cloud
    attr_reader :device_ids

    def initialize(email, password)
      @password = password
      @conn = Faraday.new(url: "https://my.rainmachine.com/") do |f|
        f.request :json
        f.request :retry
        f.response :raise_error
        f.response :json
        f.adapter :net_http_persistent
      end
      auth_params = { user: { email: email, pwd: password, remember: true } }
      resp = @conn.post("/login/auth", auth_params)

      case resp.body["errorType"]
      when 1 then raise "email has not been validated"
      when 3 then raise "the password provided is wrong"
      when 4 then raise "internal server error"
      end

      @conn.params[:access_token] = resp.body["access_token"]

      @device_ids = case resp.body["errorType"]
                    when 0 then [resp.body["sprinklerId"]]
                    when 2 then []
                    when -1
                      resp = @conn.post("/devices/get-sprinklers", auth_params)
                      resp.body["sprinklers"].map { |s| s["sprinklerId"] }
                    end.freeze
    end

    def device(id)
      raise ArgumentError, "unknown device" unless @device_ids.include?(id)

      Device.new("https://api.rainmachine.com/#{id}/",
                 access_token: @conn.post("/devices/login-sprinkler",
                                          { sprinklerId: id, pwd: @password }).body["access_token"])
    end
  end
end
