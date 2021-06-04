# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)

require 'paynearme/callbacks'

Gem::Specification.new do |spec|
  spec.name = "paynearme_callbacks"
  spec.version = Paynearme::Callbacks::VERSION
  spec.authors = ["PayNearMe", "Grio"]
  spec.email = ["rschultz@grio.com"]
  spec.description = %q{Callback api implementation for rails and rack applications.}
  spec.summary = %q{Need to write a summary}
  spec.homepage = "http://www.paynearme.com/"
  spec.license = "Proprietary"

  spec.files = Dir.glob("{bin,lib}/**/*") + %w(paynearme_callbacks.gemspec README.md config.ru)
  spec.executables = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_dependency "grape", "~> 1.5"
  spec.add_dependency "rack"
  spec.add_dependency "nokogiri"
  spec.add_dependency "log4r"

  spec.add_development_dependency "bundler"
  spec.add_development_dependency "rake"
end
