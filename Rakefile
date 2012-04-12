require 'bundler'
Bundler.setup

require "rspec"
require "rspec/core/rake_task"

$LOAD_PATH.unshift File.expand_path("../lib", __FILE__)
require "bus_pirate/version"

desc "Builds the gem"
task :gem => :build
task :build do
  system "gem build buspirate.gemspec"
  Dir.mkdir("pkg") unless Dir.exists?("pkg")
  system "mv buspirate-#{BusPirate::VERSION}.gem pkg/"
end

task :install => :build do
  system "sudo gem install pkg/buspirate-#{BusPirate::VERSION}.gem"
end

desc "Release the gem - Gemcutter"
task :release => :build do
  system "git tag -a v#{BusPirate::VERSION} -m 'Tagging #{BusPirate::VERSION}'"
  system "git push --tags"
  system "gem push pkg/bus_pirate-#{BusPirate::VERSION}.gem"
end


RSpec::Core::RakeTask.new(:spec) do |spec|
  spec.pattern = "spec/**/*_spec.rb"
end

task :default => [:spec]
