#
#  Be sure to run `pod spec lint TYVideoPlayer.podspec' to ensure this is a
#  valid spec and to remove all comments including this before submitting the spec.
#
#  To learn more about Podspec attributes see http://docs.cocoapods.org/specification.html
#  To see working Podspecs in the CocoaPods repo see https://github.com/CocoaPods/Specs/
#

Pod::Spec.new do |s|

  # ―――  Spec Metadata  ―――――――――――――――――――――――――――――――――――――――――――――――――――――――――― #
  #
  #  These will help people to find your library, and whilst it
  #  can feel like a chore to fill in it's definitely to your advantage. The
  #  summary should be tweet-length, and the description more in depth.
  #

  s.name         = "TYVideoPlayer"
  s.version      = "0.0.1"
  s.summary      = "A short description of TYVideoPlayer."

  # This description is used to generate tags and improve search results.
  #   * Think: What does it do? Why did you write it? What is the focus?
  #   * Try to keep it short, snappy and to the point.
  #   * Write the description between the DESC delimiters below.
  #   * Finally, don't worry about the indent, CocoaPods strips it!
  s.description  = <<-DESC
  A video player for iOS platform, functions include: player basic control, video cache while playing, prefetching, and other utilities.
                   DESC

  s.homepage     = "http://confluence.tangyishipin.com/pages/viewpage.action?pageId=1933486"
  # s.screenshots  = "www.example.com/screenshots_1.gif", "www.example.com/screenshots_2.gif"


  # ―――  Spec License  ――――――――――――――――――――――――――――――――――――――――――――――――――――――――――― #
  #
  #  Licensing your code is important. See http://choosealicense.com for more info.
  #  CocoaPods will detect a license file if there is a named LICENSE*
  #  Popular ones are 'MIT', 'BSD' and 'Apache License, Version 2.0'.
  #

  # s.license      = "MIT (example)"
  s.license      = { :type => "MIT", :file => "FILE_LICENSE" }


  # ――― Author Metadata  ――――――――――――――――――――――――――――――――――――――――――――――――――――――――― #
  #
  #  Specify the authors of the library, with email addresses. Email addresses
  #  of the authors are extracted from the SCM log. E.g. $ git log. CocoaPods also
  #  accepts just a name if you'd rather not provide an email address.
  #
  #  Specify a social_media_url where others can refer to, for example a twitter
  #  profile URL.
  #

  s.author             = { "liyongqiang" => "1184954731@qq.com" }
  # Or just: s.author    = "liyongqiang"
  # s.authors            = { "liyongqiang" => "1184954731@qq.com" }
  # s.social_media_url   = "http://twitter.com/liyongqiang"

  # ――― Platform Specifics ――――――――――――――――――――――――――――――――――――――――――――――――――――――― #
  #
  #  If this Pod runs only on iOS or OS X, then specify the platform and
  #  the deployment target. You can optionally include the target after the platform.
  #

  # s.platform     = :ios
  # s.platform     = :ios, "5.0"
  s.platform = :ios, '7.0'
  s.ios.deployment_target = '7.0'
  s.requires_arc = true

  #  When using multiple platforms
  # s.ios.deployment_target = "5.0"
  # s.osx.deployment_target = "10.7"
  # s.watchos.deployment_target = "2.0"
  # s.tvos.deployment_target = "9.0"


  # ――― Source Location ―――――――――――――――――――――――――――――――――――――――――――――――――――――――――― #
  #
  #  Specify the location from where the source should be retrieved.
  #  Supports git, hg, bzr, svn and HTTP.
  #

  # s.source       = { :git => "http://EXAMPLE/TYVideoPlayer.git", :tag => "#{s.version}" }

  s.source           = { :git => 'git@code.aliyun.com:zzuliliyongqiang/TYVideoPlayer.git', :tag => s.version.to_s }
  # ――― Source Code ―――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――― #
  #
  #  CocoaPods is smart about how it includes source code. For source files
  #  giving a folder will include any swift, h, m, mm, c & cpp files.
  #  For header files it will include any header in the folder.
  #  Not including the public_header_files will make all headers public.
  #

#  s.source_files  = "Classes", "Classes/**/*.{h,m}"
#  s.source_files = [
#  'TYVideoPlayer/Classes/*.{h,m}',
#  'TYVideoPlayer/Classes/**/*.{h,m}'
# ]
#    #s.exclude_files = "Classes/Exclude"
    s.subspec 'CacheFlie' do |ss|
            ss.source_files = ['TYVideoPlayer/Classes/CacheFlie/**/*.{h,m}*']
    end
    s.subspec 'Prefetch' do |ss|
        ss.source_files = ['TYVideoPlayer/Classes/Prefetch/**/*.{h,m}*']
    end
    s.subspec 'Network' do |ss|
        ss.source_files = ['TYVideoPlayer/Classes/Network/**/*.{h,m}*']
    end
    
    s.subspec 'Player' do |ss|
        ss.source_files = ['TYVideoPlayer/Classes/Player/**/*.{h,m}*']
    end
    s.subspec 'Utils' do |ss|
        ss.source_files = ['TYVideoPlayer/Classes/Utils/**/*.{h,m}*']
    end
    s.subspec 'Public' do |ss|
        ss.source_files = ['TYVideoPlayer/Classes/Public/**/*.{h,m}*']
        ss.public_header_files = ['TYSafeKit/Classes/Public/**/*.h']
    end

#   s.framework  = "Foundation"
   s.frameworks = "Foundation", "UIKit"

  # s.library   = "iconv"
  # s.libraries = "iconv", "xml2"


  # ――― Project Settings ――――――――――――――――――――――――――――――――――――――――――――――――――――――――― #
  #
  #  If your library depends on compiler flags you can set them in the xcconfig hash
  #  where they will only apply to your library. If you depend on other Podspecs
  #  you can include multiple dependencies to ensure it works.

  # s.requires_arc = true

  # s.xcconfig = { "HEADER_SEARCH_PATHS" => "$(SDKROOT)/usr/include/libxml2" }
  # s.dependency "JSONKit", "~> 1.4"

end
