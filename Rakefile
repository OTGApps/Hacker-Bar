# -*- coding: utf-8 -*-
$:.unshift("/Library/RubyMotion/lib")
require 'motion/project/template/osx'

begin
  require 'bundler'
  Bundler.require
rescue LoadError
end

Motion::Project::App.setup do |app|
  # Use `rake config' to see complete project settings.
  app.name = 'YCMenu'
  app.identifier = "com.mohawkapps.#{app.name}"
  app.info_plist['LSUIElement'] = true
  app.frameworks += [ 'ServiceManagement']

end

class Motion::Project::App
  class << self
    #
    # The original `build' method can be found here:
    # https://github.com/HipByte/RubyMotion/blob/master/lib/motion/project/app.rb#L75-L77
    #
    alias_method :build_before_copy_helper, :build
    def build platform, options = {}
      # First let the normal `build' method perform its work.
      build_before_copy_helper(platform, options)
      # Now the app is built, but not codesigned yet.
      destination = File.join(config.app_bundle(platform), 'Library/LoginItems')
      info 'Create', destination
      FileUtils.mkdir_p destination
      helper_path = File.dirname(__FILE__)+'/ycmenu-app-launcher/build/MacOSX-10.8-Development/ycmenu-app-launcher.app'
      info 'Copy', helper_path
      FileUtils.cp_r helper_path, destination
    end
  end
end
