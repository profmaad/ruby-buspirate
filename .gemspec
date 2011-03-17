require 'rake'

Gem::Specification.new do |s|
  s.name = "ruby-buspirate"
  s.version = "0.1"
  s.summary = "Ruby interface to Bus Pirate (via binary mode)"
  s.author = "Prof. MAAD aka Max Wolter"
  s.homepage = "https://github.com/profmaad/ruby-buspirate"
  s.license = "BSD"

  s.files = FileList["lib/**/*.rb", "examples/*.rb", "README.md", "LICENSE"]

  s.add_dependency("ruby-serialport", [">= 0.7.0"])
end
