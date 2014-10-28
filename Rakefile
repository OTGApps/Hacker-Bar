# -*- coding: utf-8 -*-
$:.unshift("/Library/RubyMotion/lib")
require 'motion/project/template/osx'

begin
  require 'bundler'
  Bundler.require
rescue LoadError
end

Motion::Project::App.setup do |app|
  app.name = 'Hacker Bar'
  app.version = "1.1.1"
  app.short_version = "20"
  app.icon = 'AppIcon.icns'
  app.identifier = "com.mohawkapps.#{app.name.gsub(' ', '-').downcase}"
  app.info_plist['LSUIElement'] = true
  app.frameworks += ['ServiceManagement', 'IOKit']
  app.copyright = "Copyright © 2014 Mohawk Apps, LLC.\nAll rights reserved."
  app.deployment_target = "10.8"
  app.archs['MacOSX'] = ['x86_64']

  app.pods do
    pod 'Mixpanel-OSX-Community', :git => "https://github.com/orta/mixpanel-osx-unofficial.git"
    pod 'Ono'
  end

  app.vendor_project('vendor/time_ago_in_words', :static, :cflags => '-fobjc-arc')
  app.vendor_project('vendor/UniqueIdentifier', :static, :cflags => '-fobjc-arc')

  app.entitlements['com.apple.security.app-sandbox'] = true
  app.entitlements['com.apple.security.network.client'] = true
  app.category = "news"

  app.release do
    app.info_plist['AppStoreRelease'] = true
    app.codesign_certificate = "Developer ID Application: Mohawk Apps, LLC (DW9QQZR4ZL)"
    # app.codesign_certificate = "3rd Party Mac Developer Application: Mohawk Apps, LLC (DW9QQZR4ZL)"
  end

end

after :"build", :"build:development" do
  helper_name = "HackerBarLauncher"

  destination = File.join(config.app_bundle(platform), 'Library/LoginItems')
  info 'Create', destination
  FileUtils.mkdir_p destination

  helper_path = File.join("./#{helper_name}", config.versionized_build_dir(platform)[1..-1], "#{helper_name}.app")
  info 'Copy', helper_path
  FileUtils.cp_r helper_path, destination
end
