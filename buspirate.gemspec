# -*- encoding: utf-8 -*-
lib = File.expand_path('../lib/', __FILE__)
$:.unshift lib unless $:.include?(lib)

require 'bus_pirate/version'

Gem::Specification.new do |s|
  s.name = "buspirate"
  s.version = BusPirate::VERSION

  s.authors = ["profmaad", "nofxx"]
  s.description = "Bus Pirate with lots of 'arr'"
  s.homepage = "http://github.com/nofxx/bus_pirate"
  s.summary = "Bus Pirate with more 'arr'"
  s.email = "x@nofxx.com"

  s.files = Dir.glob("{lib,spec}/**/*") + %w(README.md Rakefile)
  s.require_path = "lib"

  s.rubygems_version = "1.3.7"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=

  s.add_development_dependency("rspec", ["~> 2.8.0"])
end
