# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)

require 'manageiq/providers/proxmox/version'

Gem::Specification.new do |spec|
  spec.name          = "manageiq-providers-proxmox"
  spec.version       = ManageIQ::Providers::Proxmox::VERSION
  spec.authors       = ["ManageIQ Authors"]

  spec.summary       = "ManageIQ plugin for the Proxmox VE provider."
  spec.description   = "ManageIQ plugin for the Proxmox VE provider."
  spec.homepage      = "https://github.com/ManageIQ/manageiq-providers-proxmox"
  spec.licenses      = ["Apache-2.0"]

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency "manageiq-providers-base", "~> 1.0"
  spec.add_dependency "rest-client", "~> 2.1"
  spec.add_dependency "faraday", "~> 2.0"
  spec.add_dependency "faraday-cookie_jar", "~> 0.0.7"

  spec.add_development_dependency "codeclimate-test-reporter", "~> 1.0.0"
  spec.add_development_dependency "simplecov"
end

