require_relative 'lib/stream_parser/version'

Gem::Specification.new do |s|
  s.name          = 'stream_parser'
  s.version       = StreamParser::VERSION
  s.authors       = ["Jon Bracy"]
  s.email         = ["jonbracy@gmail.com"]
  s.homepage      = "https://github.com/malomalo/stream_parser"
  s.summary       = %q{SAX/Stream style parse helpers}
  s.license       = "MIT"

  s.extra_rdoc_files = %w(README.md)
  s.rdoc_options.concat ['--main', 'README.md']

  s.files         = Dir["LICENSE", "README.md", "lib/**/*"]
  s.require_paths = %w(lib)
  
  s.required_ruby_version = '>= 3.0.0'

  s.add_development_dependency "rake"
  s.add_development_dependency 'bundler'
  s.add_development_dependency 'minitest'
  s.add_development_dependency 'minitest-reporters'
  s.add_development_dependency 'mocha'
  s.add_development_dependency 'byebug'
end