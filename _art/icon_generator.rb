#!/usr/bin/env ruby

# Easily create AppIcon.icns files from a single 1024x1024 image.

raise "You must pass a folder name to this utility" unless ARGV[0]
require 'rubygems'

def main
  check_deps

  sizes = [512, 256, 128, 32, 16]
  original_file = ARGV[0].chomp
  folder = File.dirname(__FILE__) << "/AppIcon.iconset"
  FileUtils.mkdir_p(folder)

  puts "\nGenerating sizes for image: #{original_file}\n"
  sizes.each do |size|
    # Make the @2x image
    FastImage.resize(original_file, size*2, size*2, :outfile => "#{folder}/icon_#{size}x#{size}@2x.png")

    # Make the regular image
    FastImage.resize(original_file, size, size, :outfile => "#{folder}/icon_#{size}x#{size}.png")
  end

  puts "Optimizing images... please wait.\n"
  %x(/Applications/ImageOptim.app/Contents/MacOS/ImageOptim 2>/dev/null #{folder}/icon_*x*.png)

  puts "Generating iconset file. \n"
  %x(iconutil -c icns -o AppIcon.icns AppIcon.iconset)

end

def check_deps
  ['fastimage_resize'].each do |dep|
    begin
      Gem::Specification::find_by_name(dep)
    rescue Gem::LoadError
      puts "\nPlease run 'gem install #{dep}' and try again.\n\n"
      abort
    end
    require dep
  end
end

main
