#
# Be sure to run `pod lib lint RBGalleryGrabbing.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = "RBGalleryGrabbing"
  s.version          = "0.1.0"
  s.summary          = "Grab every asset in an iOS photos gallery."

# This description is used to generate tags and improve search results.
#   * Think: What does it do? Why did you write it? What is the focus?
#   * Try to keep it short, snappy and to the point.
#   * Write the description between the DESC delimiters below.
#   * Finally, don't worry about the indent, CocoaPods strips it!  
  s.description      = <<-DESC
			"Pull every asset from the iOS photos gallery in the background without user interaction."
                       DESC

  s.homepage         = "https://github.com/Raztor0/RBGalleryGrabbing"
  s.license          = 'MIT'
  s.author           = { "Razvan Bangu" => "razvan.bangu@gmail.com" }
  s.source           = { :git => "https://github.com/Raztor0/RBGalleryGrabbing.git", :tag => s.version.to_s }
  s.social_media_url = 'https://twitter.com/Razvan_B'

  s.platform     = :ios, '10.0'
  s.requires_arc = true

  s.source_files = 'Pod/Classes/**/*'

  # s.public_header_files = 'Pod/Classes/**/*.h'
  s.frameworks = 'Photos'
end
