# create-images.rb
# Script that creates Asset catalog's imagesets from images for both dark and light appearance and multiple scales.
# Created by Dmitry Bespalov on 02.03.2022

# input: 
# multiple file names with the following format:
# <name><luminosity><scale>
# <name> = any string
# <luminosity> = @any | @dark
# <scale> = @1x | @2x | @3x

# assumes that all names are in the correct format and we have any and dark variants, i.e.
# each image 'name' has 6 variants: all combinations of luminosity and scale.

# Creates the imagesets in the current directory and moves the images into those image sets.

# output:
# folder <name>.imageset
#   - Contents.json
#   - all files with the same <name>

# Contents
#   images: [Image]
#   info: Info

# Image
#   filename?: filename
#   idiom: universal
#   scale: 1x | 2x | 3x
#   appearances?: [Appearance]

# Appearance
#   appearance: luminosity
#   value: dark | light

# Info
#   author: "xode"
#   version: 1

require 'json'
require 'set'
require 'fileutils'

filenames = ARGV[1...]

if filenames.nil? || filenames.length < 2
    puts "Pass multiple files"
    exit
end

imagenames = Set[]

for file_name in filenames
    basename = File.basename(file_name, ".png")
    parts = basename.split("@")
    
    if parts.length != 3 
        puts "File #{file_name} is not in the format <name>@<any|dark>@<1x|2x|3x>.png"
        exit 
    end

    image_name = parts[0]
    
    imagenames.add(image_name)
end


imagesets = []

for image_name in imagenames
    imageset = {}
    folder_name = image_name + ".imageset"

    appearances = ["any", "dark"]
    scales = ["1x", "2x", "3x"]

    images = []

    for scale in scales
        for appearance in appearances
            filename = "#{image_name}@#{appearance}@#{scale}.png"

            image = {
                "filename" => filename,
                "idiom" => "universal",
                "scale" => scale
            }

            if appearance != "any"
                image["appearances"] = [
                    {
                        "appearance" => "luminosity",
                        "value" => appearance   
                    }
                ]
            end

            images << image
        end
    end

    content_filename = "Contents.json"
    content_contents = {
        "info" => {
            "author" => "xcode",
            "version" => 1
        },
        "images" => images
    }

    imageset[:folder] = folder_name
    imageset[:images] = images
    imageset[:content_file] = File.join(folder_name, content_filename)
    imageset[:content_file_content] = content_contents

    imagesets << imageset
end

for set in imagesets 
    # create folder
    FileUtils.mkdir set[:folder]

    # move files to folder
    for image in set[:images]
        FileUtils.mv image["filename"], set[:folder]
    end

    File.open(set[:content_file], "w") { |f| 
        f.write(JSON.pretty_generate(set[:content_file_content]))
    }
end
