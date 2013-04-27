Gem::Specification.new do |s|
  s.name        = 'nuclear'
  s.version     = '0.0.1'
  s.platform    = Gem::Platform::RUBY
  s.authors     = ['Keith Stone']
  s.email       = ['keithjustinstone@gmail.com']
  s.homepage    = ''
  s.summary     = '2 phase commit implementation in ruby'
  s.description = 'System for setting up replicated key value store that uses 2-phase commit to ensure atomic operations'
  s.licenses    = ['BSD']

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {spec}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib", 'gen-rb']
end
