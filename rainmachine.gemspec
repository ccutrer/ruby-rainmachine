# frozen_string_literal: true

require_relative "lib/rain_machine/version"

Gem::Specification.new do |s|
  s.name = "rainmachine"
  s.version = RainMachine::VERSION
  s.platform = Gem::Platform::RUBY
  s.authors = ["Cody Cutrer"]
  s.email = "cody@cutrer.com'"
  s.homepage = "https://github.com/ccutrer/ruby-rainmachine"
  s.summary = "Library for communication with RainMachine sprinkler controllers"
  s.license = "MIT"

  s.executables = ["rainmachine"]
  s.files = Dir["{exe,lib}/**/*"]

  s.required_ruby_version = ">= 2.6"

  s.add_dependency "activesupport", "~> 6.1"
  s.add_dependency "faraday_middleware", "~> 1.1"
  s.add_dependency "homie-mqtt", "~> 1.2"
  s.add_dependency "net-http-persistent", "~> 4.0"
  s.add_dependency "thor", "~> 1.1"

  s.add_development_dependency "byebug", "~> 9.0"
  s.add_development_dependency "rake", "~> 13.0"
  s.add_development_dependency "rubocop", "~> 1.18"
  s.add_development_dependency "rubocop-rake", "~> 0.6"
end
