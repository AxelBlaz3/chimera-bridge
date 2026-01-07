require "json"

# Adjust path to package.json (it is now one level up)
package = JSON.parse(File.read(File.join(__dir__, "./package.json")))

Pod::Spec.new do |s|
  s.name         = "{{name}}"
  s.version      = package["version"]
  s.summary      = "Flutter Bridge for {{name}}"
  s.homepage     = "https://github.com/AxelBlaz3/chimera-bridge.git"
  s.license      = "MIT"
  s.authors      = { "Karthik Gaddam" => "karthikgaddam4@gmail.com" }
  
  s.platforms    = { :ios => "{{ios_platform}}" }
  s.source       = { :git => "https://github.com/AxelBlaz3/chimera-bridge.git", :tag => "#{s.version}" }

  # 1. Source files are now siblings (no "ios/" prefix)
  s.source_files = "**/*.{h,m,swift}"
  
  # 2. Frameworks are now in the local "Frameworks" folder
  s.vendored_frameworks = 'ios/Frameworks/Release/*.xcframework'
  
  s.dependency "React-Core"
end