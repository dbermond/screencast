#!/bin/sh
# shellcheck disable=SC2154,SC2086

# ffmpeg.sh - ffmpeg related functions for screencast
#
# Copyright (c) 2015-2020 Daniel Bermond < gmail.com: danielbermond >
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
#                ffmpeg                 #
#########################################

# description:
#   check if at least one supported lossless component of the given type is
#   available in the detected ffmpeg build
# arguments:
#   $1 - component type (format, audiocodec, videocodec)
# return value: none
# return code (status): not relevant
# note1:
#   it will automatically fallback to the next supported lossless component of the
#   given type that is found
# note2:
#   program will exit with error if no supported lossless components of the given type
#   is available in ffmpeg
check_lossless_component() {
    case "$1" in
        format)
            component_list="$supported_formats_lossless"
            component_generic_name='muxer/demuxer'
            ;;
        audiocodec)
            component_list="$supported_audiocodecs_lossless"
            component_generic_name='audio encoder/decoder'
            ;;
        videocodec)
            component_list="$supported_videocodecs_lossless"
            component_generic_name='video encoder/decoder'
            ;;
        *)
            exit_program "check_lossless_component(): invalid component type '${1}'"
            ;;
    esac
    
    first_component="$( printf '%s' "$component_list" | head -n 1)"
    second_component="$(printf '%s' "$component_list" | sed  -n '2p')"
    last_component="$(  printf '%s' "$component_list" | tail -n 1)"
        
    for component in $component_list
    do
        if "lossless_${1}_settings_${component}"
        then
            if [ "$component" = "$first_component" ]
            then
                break
            else
                if [ "$component" = "$second_component" ]
                then
                    previous_components="$(printf '%s' "$previous_components" | sed "s/,[[:space:]]$//")"
                    
                elif [ "$component" = "$last_component" ]
                then
                    previous_components="$(printf '%s' "$previous_components" | sed 's/,[[:space:]]$//')"
                    last_word="$(          printf '%s' "$previous_components" | awk '{ print $NF }')"
                    previous_components="$(printf '%s' "$previous_components" | sed "s/,[[:space:]]${last_word}$/ or ${last_word}/")"
                fi
                
                print_warn "no '${previous_components}' ${component_generic_name} support in ffmpeg"
                print_warn "falling back to '${component}' ${component_generic_name} for lossless recording"
                
                if [ "$1" = 'videocodec' ] &&
                   printf '%s' "$largefile_videocodecs_lossless" | grep -q "^${component}$"
                then
                    print_warn "'${component}' encoder will produce an extra-large temporary video, change the tmp direcotry if needed"
                fi
                
                break
            fi
        else
            if [ "$component" = "$last_component" ]
            then
                previous_components="$(printf '%s' "$previous_components" | sed "s/,[[:space:]]$/ or ${component}/")"
                component_error "$previous_components" "$component_generic_name" false
            else
                previous_components="${previous_components}${component}, "
                continue
            fi
        fi
    done
    
    unset -v component_list
    unset -v component_generic_name
    unset -v first_component
    unset -v second_component
    unset -v last_component
    unset -v component
    unset -v previous_components
}

# description: check if the detected ffmpeg build has support for a given component
# arguments:
#   $1 - component name
#   $2 - component type (encoder, decoder, muxer, demuxer)
# return value: not relevant
# reutrn code (status):
#   0 - ffmpeg build has support for the desired component
#   1 - ffmpeg build has no support for the desired component
# note1: needs $ffmpeg_codecs for encoders and decoders - ffmpeg_codecs="$(ffmpeg -codecs -v quiet)"
# note2: needs $ffmpeg_formats for muxers and demuxers - ffmpeg_formats="$(ffmpeg -formats -v quiet)"
check_component() {
    case "$2" in
        encoder)
            if ! printf '%s' "$ffmpeg_codecs" | grep -q "(encoders:.*${1}" &&
               ! printf '%s' "$ffmpeg_codecs" | grep -q "^[[:space:]].E.\\{4\\}[[:space:]]${1}[[:space:]]"
            then
                return 1
            fi
            ;;
        decoder)
            if ! printf '%s' "$ffmpeg_codecs" | grep -q "(decoders:.*${1}" &&
               ! printf '%s' "$ffmpeg_codecs" | grep -q "^[[:space:]]D.\\{5\\}[[:space:]]${1}[[:space:]]"
            then
                return 1
            fi
            ;;
        muxer)
            if ! printf '%s' "$ffmpeg_formats" | grep -q "^[[:space:]].E[[:space:]]${1}[[:space:]]"
            then
                return 1
            fi
            ;;
        demuxer)
            if ! printf '%s' "$ffmpeg_formats" | grep -q "^[[:space:]]D.[[:space:]]${1}[[:space:]]"
            then
                return 1
            fi
            ;;
        *)
            exit_program "check_component(): invalid component type '${2}'"
            ;;
    esac
}

# description:
#   check if the version of the detected ffmpeg build is at least at a minium required
#   version (checks if ffmpeg version is greater of equal than a specified one; checks
#   for both release and git versions)
# arguments:
#   $1 - ffmpeg release version (example: 4.4)
#   $2 - ffmpeg internal git revision (example: 98615)
# return value: not relevant
# reutrn code (status):
#   0 - ffmpeg version is greater or equal than the specified one
#   1 - ffmpeg version is not greater or equal than the specified one
check_minimum_ffmpeg_version() {
    if [ -z "$1" ] || [ -z "$2" ]
    then
        exit_program 'check_minimum_ffmpeg_version(): invalid usage'
    fi
    
    ffmpeg_version="$(ffmpeg -version | awk '/Copyright/ { print $3 }')"
    
    if printf '%s' "$ffmpeg_version" | grep -Eq '^[0-9]+\..*'
    then
        if [ "$(printf '%s\n' "$1" "$ffmpeg_version" | sort | head -n1)" != "$1" ]
        then
            return 1
        fi
    elif printf '%s' "$ffmpeg_version" | grep -Eq '^N-[0-9]+-[[:alnum:]]+$'
    then
        if [ "$(printf '%s' "$ffmpeg_version" | awk -F'-' '{ print $2 }')" -lt "$2" ]
        then
            return 1
        fi
    else
        exit_program "check_minimum_ffmpeg_version(): unrecognized ffmpeg version format '${ffmpeg_version}'"
    fi
}

# description: execute ffmpeg command according to predefined variables
# arguments: none
# return value: not relevant
# return code (status):
#   the ffmpeg return status, usually:
#   0 - ffmpeg command executed successfully (ffmpeg normal exit)
#   1 - ffmpeg command failed (ffmpeg error)
run_ffmpeg() {
    ffmpeg \
        $ff_audio_options \
        $ff_vaapi_options \
        $ff_video_options \
        $ff_webcam_options \
        $ff_watermark_options \
        $ff_vfilter_option $ff_vfilter_settings \
        $ff_volume_options \
        $ff_flag_global_header \
        $ff_audio_codec \
        -codec:v $ff_video_codec \
        $ff_fixed_length_options \
        $ff_pixfmt_options \
        $ff_faststart \
        $ff_map \
        -metadata "$metadata" \
        -y \
        $ff_output
}
