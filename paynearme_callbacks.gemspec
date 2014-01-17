# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)

require 'paynearme/callbacks/version'

Gem::Specification.new do |spec|
  spec.name          = "paynearme_callbacks"
  spec.version       = Paynearme::Callbacks::VERSION
  spec.authors       = ["PayNearMe", "Grio"]
  spec.email         = ["rschultz@grio.com"]
  spec.description   = %q{Callback api implementation for rails and rack applications.}
  spec.summary       = %q{Need to write a summary}
  spec.homepage      = "http://www.paynearme.com/"
  spec.license       = "Proprietary"

  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_dependency "grape", "~> 0.6"
  spec.add_dependency "rack"
  spec.add_dependency "nokogiri", "~> 1.5"

  spec.add_development_dependency "bundler", "~> 1.3"
  spec.add_development_dependency "rake"
end
