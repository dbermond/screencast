#!/bin/sh
# shellcheck disable=SC2034,SC2154

# settings_format.sh - container format settings for screencast
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
#       container format settings       #
#########################################

# supported container formats (one per line for accurate grepping and easy deletion)
supported_formats_all="$(     printf 'mp4\nmov\nmkv\nwebm\nogg\nogv\nflv\nnut\nwmv\nasf\navi')"
supported_formats_lossless="$(printf 'matroska\nnut')"

# container formats that, depending on the selected audio/video encoder, may be unplayable in some players
possible_unplayable_formats="$(printf 'mp4\nmov')"

# lossless container format settings functions: make checks and settings for container format to store lossless video
#                                               (for the 1st step, lossless recording)
# arguments: none
# return value: not relevant
# return code (status): 0 - the detected ffmpeg build has support for the tested container format
#                       1 - the detected ffmpeg build has no support for the tested container format
# sets special variable: $rec_extension - file extension (container format) of the lossless video
# note: the program will exit with error if the tested container format is not supported by the detected ffmpeg build
lossless_format_settings_matroska() {
    if check_component  matroska       muxer &&
       check_component 'matroska,webm' demuxer
    then
        rec_extension='mkv'
    else
        return 1
    fi
}

lossless_format_settings_nut() {
    if check_component nut muxer && 
       check_component nut demuxer
    then
        rec_extension='nut'
    else
        return 1
    fi
}

# format settings functions: make checks and settings for the selected container format
# arguments: none
# return value: none
# return code (status): not relevant
# sets special variables: $supported_audiocodecs - audio encoders supported by the selected container format (one per line)
#                         $supported_videocodecs - video encoders supported by the selected container format (one per line)
# note: the program will exit with error if the selected container format is not supported by the detected ffmpeg build
format_settings_mp4() {
    supported_audiocodecs="$(printf '%s' "$supported_audiocodecs_all" | sed '/^opus$/d;/^wma$/d')"
    supported_videocodecs="$(printf '%s' "$supported_videocodecs_all" | sed '/^theora$/d;/^vp8$/d;/^vp8_vaapi$/d;/^wmv$/d')"
    
    possible_unplayable_videocodecs="$(printf 'vp9\nvp9_vaapi')"
    
    # check if the detected ffmpeg build has support for the mp4/mov muxer
    check_component "$format" muxer || component_error "$format" muxer true
    
    # move the moov atom to the beginning of the file
    if [ "$streaming"  = 'true' ] 
    then
        [ "$saving_output" = 'true' ] && tee_faststart='[movflags=+faststart]'
    else
        ff_faststart='-movflags +faststart'
    fi
}

format_settings_mov() {
    format_settings_mp4 "$@"
    
    supported_audiocodecs="$(printf '%s' "$supported_audiocodecs_all" | sed '/^opus$/d')"
    supported_videocodecs="$(printf '%s' "$supported_videocodecs_all" | sed '/^vp9$/d;/^vp9_vaapi$/d;/^aom_av1$/d;/^rav1e$/d')"
    
    possible_unplayable_audiocodecs="$(printf 'vorbis\nwma')"
    possible_unplayable_videocodecs="$(printf 'theora\nvp8\nvp8_vaapi\nwmv')"
}

format_settings_mkv() {
    # note: mkv container formats supports all valid audio and video encoders for this program
    supported_audiocodecs="$supported_audiocodecs_all"
    supported_videocodecs="$supported_videocodecs_all"
    
    # check if the detected ffmpeg build has support for the matroska (mkv) muxer
    if [ "$rec_extension" != "$format" ] 
    then
        check_component matroska muxer || component_error matroska muxer true
    fi
}

format_settings_webm() {
    supported_audiocodecs="$(printf '%s' "$supported_audiocodecs_all" | sed '/^aac$/d;/^mp3lame$/d;/^shine$/d;/^wma$/d')"
    supported_videocodecs="$(printf 'vp8\nvp8_vaapi\nvp9\nvp9_vaapi\naom_av1\nrav1e')"
    
    # check if the detected ffmpeg build has support for the webm muxer
    check_component "$format" muxer || component_error "$format" muxer true
    
    # auto choose audio/video encoder if needed
    [ "$audio_encoder_setted" = 'false' ] && audio_encoder='opus' && audio_outstr='(auto chosen)'
    [ "$video_encoder_setted" = 'false' ] && video_encoder='vp9'  && video_outstr='(auto chosen)'
}

format_settings_ogg() {
    supported_audiocodecs="$(printf '%s' "$supported_audiocodecs_all" | sed '/^aac$/d;/^mp3lame$/d;/^shine$/d;/^wma$/d')"
    supported_videocodecs="$(printf 'vp8\nvp8_vaapi\ntheora')"
    
    # check if the detected ffmpeg build has support for the ogg/ogv muxer
    check_component "$format" muxer || component_error "$format" muxer true
    
    # auto choose audio/video encoder if needed
    [ "$audio_encoder_setted" = 'false' ] && audio_encoder='vorbis' && audio_outstr='(auto chosen)'
    [ "$video_encoder_setted" = 'false' ] && video_encoder='theora' && video_outstr='(auto chosen)'
}

format_settings_ogv() {
    format_settings_ogg "$@"
}

format_settings_flv() {
    supported_audiocodecs="$(printf '%s' "$supported_audiocodecs_all" | sed '/^opus$/d;/^vorbis$/d;/^wma$/d')"
    supported_videocodecs="$(printf 'x264\nh264_nvenc\nh264_vaapi\nh264_qsv')"
    
    # check if the detected ffmpeg build has support for the flv muxer only if recording offline
    # (flv muxer support in ffmpeg is already checked during the live streaming checks)
    if [ "$streaming" = 'false' ] 
    then
        check_component "$format" muxer || component_error "$format" muxer true
    fi
}

format_settings_nut() {
    # note: nut container formats supports all valid audio and video encoders for this program
    supported_audiocodecs="$supported_audiocodecs_all"
    supported_videocodecs="$supported_videocodecs_all"
    
    # check if the detected ffmpeg build has support for the nut muxer
    if [ "$rec_extension" != "$format" ] 
    then
        check_component "$format" muxer || component_error "$format" muxer true
    fi
}

format_settings_wmv() {
    supported_audiocodecs="$(printf '%s' "$supported_audiocodecs_all" | sed '/^opus$/d')"
    
    supported_videocodecs="$(printf '%s' "$supported_videocodecs_all" |
                                 sed '/^x265$/d;/^kvazaar$/d;/^svt_hevc$/d;/^hevc_nvenc$/d;/^hevc_vaapi$/d;/^hevc_qsv$/d')"
    
    # check if the detected ffmpeg build has support for the asf muxer
    # note: asf muxer is used for wmv (and wma) container format
    check_component asf muxer || component_error asf muxer true
}

format_settings_asf() {
    supported_audiocodecs="$(printf '%s' "$supported_audiocodecs_all" | sed '/^opus$/d')"
    
    supported_videocodecs="$(printf '%s' "$supported_videocodecs_all" |
                                 sed '/^x265$/d;/^kvazaar$/d;/^svt_hevc$/d;/^hevc_nvenc$/d;/^hevc_vaapi$/d;/^hevc_qsv$/d')"
    
    # check if the detected ffmpeg build has support for the asf muxer
    check_component "$format" muxer || component_error "$format" muxer true
}

format_settings_avi() {
    # note: avi container formats supports all valid video encoders for this program
    supported_audiocodecs="$(printf '%s' "$supported_audiocodecs_all" | sed '/^opus$/d')"
    supported_videocodecs="$supported_videocodecs_all"
    
    # check if the detected ffmpeg build has support for the avi muxer
    check_component "$format" muxer || component_error "$format" muxer true
}
