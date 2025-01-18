#!/bin/sh
# shellcheck disable=SC2034,SC2154,SC2086

# effects.sh - effects for screencast
#
# Copyright (c) 2015-2025 Daniel Bermond < gmail.com: danielbermond >
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 2 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.

#########################################
#                effects                #
#########################################

# description: check for a valid special position string
# arguments:
#   $1 - the string to check
# return value: not relevant
# return code (status):
#   0 - a valid special positon string was passed
#   1 - an invalid special positon string was passed
# sets special variables: $special_position - the value to which the string translates
check_special_position() {
    case "$1" in
        topright|tr)
            special_position="main_w-overlay_w-${corner_padding}:${corner_padding}"
            ;;
        bottomright|br)
            special_position="main_w-overlay_w-${corner_padding}:main_h-overlay_h-${corner_padding}"
            ;;
        topleft|tl)
            special_position="${corner_padding}:${corner_padding}"
            ;;
        bottomleft|bl)
            special_position="${corner_padding}:main_h-overlay_h-${corner_padding}"
            ;;
        *)
            return 1
            ;;
    esac
}

# description:
#   check for a valid png optimizer (-g/--png-optimizer)
#   (will exit with error if an invalid png optimizer is chosen)
# arguments: none
# return value: not relevant
# return code (status): 0 - a valid png optimizer was selected
# note1: it will make the program exit with error if an invalid png optimizer was selected
# note2:
#   this png optimizer check should be on check_cmd_line(), but it is implemented
#   as a separate function to allow it to be executed before check_requirements()
check_pngoptimizer() {
    if [ "$pngoptimizer_setted" = 'true' ]
    then
        get_supported_pngoptmz
        
        if ! printf '%s' "$supported_pngoptmz" | grep -q "^${pngoptimizer}$"
        then
            exit_program "'${pngoptimizer}' is not a valid PNG optimizer for this program"
        fi
    fi
}

# description: optimize the png (watermark) image
# arguments: none
# return value: not relevant
# return code (status): not relevant
# note: needs $wmark_image
optimize_png() {
    print_good 'optimizing watermark image'
    
    [ "$pngoptimizer" != 'opt-png' ] && "get_pngoptmz_settings_${pngoptimizer}"
    
    "$pngoptimizer" $pngoptmz_settings "$wmark_image"
    
    # use advdef to optimize PNG even more
    get_pngoptmz_settings_advdef
    advdef $advdef_settings "$wmark_image"
}

# description: create a text watermark and set watermark options to be passed to ffmpeg command
# arguments: none
# return value: not relevant
# return code (status):
#   0 - text watermark image was successfully created
#   1 - failed to create text watermark image
# sets special variables: $watermark_vfilter - ffmpeg video filter options for watermark
create_watermark() {
    print_good 'generating watermark image'
    rndstr_png="$(randomstr '12')" # random string for tmp png filename
    wmark_image="${tmpdir}/screencast-tmpimage-${rndstr_png}.png"
    
    # get font pointsize
    watermark_pointsize="$(magick -size "$watermark_size" \
                                  -font "$watermark_font" \
                                  label:"$watermark_text" \
                                  -format '%[label:pointsize]' \
                                  info:)"
    
    # check if font pointsize was correctly obtained (integer/float number)
    if ! printf '%s' "$watermark_pointsize" | grep -Eq '^[0-9]+(|\.[0-9]+)$'
    then
        exit_program 'failed to obtain the watermark font pointsize'
    fi
    
    # generate the watermark
    if ! magick \
            -size "$watermark_size" \
            -font "$watermark_font" \
            -pointsize "$watermark_pointsize" \
            -gravity center \
            \( \
                xc:grey30 \
                -draw "fill gray70  text 0,0  '${watermark_text}'" \
            \) \
            \( \
                xc:black \
                -draw "fill white  text  1,1  '${watermark_text}'  \
                                   text  0,0  '${watermark_text}'  \
                       fill black  text -1,-1 '${watermark_text}'" \
                -alpha Off \
            \) \
            -alpha Off \
            -compose copy-opacity \
            -composite \
            -trim \
            +repage \
            "$wmark_image"
    then
        exit_program 'failed to create the watermark image'
    fi
    
    # check if the generated watermark is a PNG image file
    if ! file "$wmark_image" | grep -q 'PNG image data'
    then
        exit_program 'the generated watermark is not a PNG image file'
    fi
    
    # optimize PNG image if chosen by user (-g/--png-optimizer)
    [ "$pngoptimizer" != 'none' ] && optimize_png
    
    return 0
}

# description: sets video fade options to be passed to ffmpeg command
# arguments: none
# return value: none
# return code (status): not relevant
# sets special variables: $fade_options - ffmpeg fade options
videofade() {
    get_fade_settings
    
    # get recorded video length in seconds
    video_length="$(ffprobe \
                        -i "${tmpdir}/screencast-lossless-${rndstr_video}.${rec_extension}" \
                        -show_entries format='duration' \
                        -v quiet \
                        -of csv='p=0')"
    
    # set start time of fade-out in seconds
    total_fadeout="$(awk "BEGIN { OFMT=\"%.2f\"; print ${fade_length}  + ${fade_solid_length} }")"
    fadeout_start="$(awk "BEGIN { OFMT=\"%.2f\"; print ${video_length} - ${total_fadeout} }")"
    
    # build ffmpeg fade in/out options
    fadein="fade=type=in:start_time=${fade_solid_length}:duration=${fade_length}:color=${fade_color}"
    fadeout="fade=type=out:start_time=${fadeout_start}:duration=${fade_length}:color=${fade_color}"
    
    # check the chosen fade type and set ffmpeg fade options if necessary
    case "$fade" in
        in)
            fade_options="$fadein"
            ;;
        out)
            fade_options="$fadeout"
            ;;
        both)
            fade_options="${fadein},${fadeout}"
            ;;
    esac
    
    unset -v video_length
    unset -v total_fadeout
    unset -v fadeout_start
    unset -v fadein
    unset -v fadeout
}
