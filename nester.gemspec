# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "nester/version"

Gem::Specification.new do |s|
  s.name        = "nester"
  s.version     = Nester::VERSION
  s.authors     = ["Adam Lamar"]
  s.email       = ["adamonduty@gmail.com"]
  s.homepage    = ""
  s.summary     = %q{Nest tests using ActionController::TestCase}
  s.description = %q{Dynamically generates named routes and other methods to make using nested routes easy.}

  s.rubyforge_project = "nester"

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]

  s.add_dependency 'rails', '>= 3.0.0'
end
