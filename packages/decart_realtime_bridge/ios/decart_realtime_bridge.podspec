Pod::Spec.new do |s|
  s.name             = 'decart_realtime_bridge'
  s.version          = '0.1.0'
  s.summary          = 'Flutter platform bridge for Morphly realtime Decart sessions.'
  s.description      = 'Exposes Morphly Decart realtime controls to Flutter.'
  s.homepage         = 'https://morphly.local'
  s.license          = { :type => 'MIT' }
  s.author           = { 'Morphly' => 'engineering@morphly.local' }
  s.source           = { :path => '.' }
  s.source_files     = 'Classes/**/*'
  s.dependency 'Flutter'
  s.platform = :ios, '14.0'
  s.swift_version = '5.9'
end
