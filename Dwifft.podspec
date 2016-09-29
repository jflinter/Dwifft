Pod::Spec.new do |s|
  s.name = 'Dwifft'
  s.version = '0.4'
  s.license = 'MIT'
  s.summary = 'Swift Diff'
  s.homepage = 'https://github.com/jflinter/Dwifft'
  s.social_media_url = 'http://twitter.com/jflinter'
  s.author = "Jack Flintermann"
  s.source = { :git => 'https://github.com/jflinter/Dwifft.git', :tag => s.version }

  s.ios.deployment_target = '8.0'
  s.tvos.deployment_target = '9.0'

  s.source_files = 'Dwifft/*.swift'

  s.requires_arc = true
end
