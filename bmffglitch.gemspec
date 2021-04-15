
lib = File.expand_path("../lib", __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "bmffglitch/version"

Gem::Specification.new do |spec|
  spec.name          = "bmffglitch"
  spec.version       = BMFFGlitch::VERSION
  spec.authors       = ["sabishirop"]
  spec.email         = ["sabishirop@gmail.com"]

  spec.summary       = %q{A Ruby library to destroy files stored in ISO Base Media File Format(BMFF) and its relatives}
  spec.description   = spec.summary
  spec.homepage      = "http://sabishirop.github.com/bmffglitch"
  spec.license       = "MIT"

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files         = Dir.chdir(File.expand_path('..', __FILE__)) do
    `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  end
  spec.executables   = ["bmffdtmsh"]
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 2.0"
  spec.add_development_dependency "rake", ">= 12.3.3"
  spec.add_development_dependency "rspec", "~> 3.0"

  spec.add_dependency "bmff", "~> 0.1.2"
end
