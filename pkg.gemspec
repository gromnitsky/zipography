Gem::Specification.new do |s|
  s.version = '0.0.1'
  s.required_ruby_version = '>= 2.4.0'

  s.name = 'zipography'
  s.summary = "Steganography with zip archives"
  s.description = <<END
Steganography with zip archives: hide a blob of data within an
archive. For typical file archivers or file managers, the blob remains
invisible.
END
  s.author = 'Alexander Gromnitsky'
  s.email = 'alexander.gromnitsky@gmail.com'
  s.homepage = 'https://github.com/gromnitsky/zipography'
  s.license = 'MIT'
  s.add_runtime_dependency 'bindata', '~> 2.4.8'

  s.files = [
    'lib.rb',
    'zipography-extract',
    'zipography-info',
    'zipography-inject',
    'README.md',
  ]
  s.bindir = '.'
  s.executables = [
    'zipography-extract',
    'zipography-info',
    'zipography-inject'
  ]
end
