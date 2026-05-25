require "json"

package = JSON.parse(File.read(File.join(__dir__, "package.json")))

Pod::Spec.new do |s|
  s.name         = "simula-ad-sdk"
  s.version      = package["version"]
  s.summary      = "Simula Ad SDK React Native Bridge wrapping native iOS Swift SDK"
  s.homepage     = "https://github.com/Simula-AI-SDK/simula-ad-sdk"
  s.license      = "MIT"
  s.authors      = "Simula Team"

  s.platforms    = { :ios => "16.0" }
  s.source       = { :git => "https://github.com/Simula-AI-SDK/simula-ad-sdk.git", :tag => "#{s.version}" }

  s.source_files = "ios/**/*.{h,m,swift}"
  
  s.dependency "React-Core"
end
