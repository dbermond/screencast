#!/bin/sh
# shellcheck disable=SC2034,SC2154

# settings_format.sh - container format settings for screencast
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
#       container format settings       #
#########################################

# supported container formats (one per line for accurate grepping and easy deletion)
supported_formats_all="$(cat <<- __EOF__
		mp4
		mov
		mkv
		webm
		ogg
		ogv
		flv
		nut
		wmv
		asf
		avi
__EOF__
)"
supported_formats_lossless="$(cat <<- __EOF__
		matroska
		nut
__EOF__
)"

# container formats that, depending on the selected audio/video encoder, may be unplayable in some players
possible_unplayable_formats="$(cat <<- __EOF__
		mp4
		mov
__EOF__
)"

# lossless container format settings functions
# description:
#   make checks and settings for container format to store lossless video
#   (for the 1st step, lossless recording)
# arguments: none
# return value: not relevant
# return code (status):
#   0 - the detected ffmpeg build has support for the tested container format
#   1 - the detected ffmpeg build has no support for the tested container format
# sets special variable: $rec_extension - file extension (container format) of the lossless video
# note:
#   the program will exit with error if the tested container format is not supported
#   by the detected ffmpeg build
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

# format settings functions
# description: make checks and settings for the selected container format
# arguments: none
# return value: none
# return code (status): not relevant
# sets special variables:
#   $supported_audiocodecs - audio encoders supported by the selected container format (one per line)
#   $supported_videocodecs - video encoders supported by the selected container format (one per line)
# note:
#   the program will exit with error if the selected container format is not supported
#   by the detected ffmpeg build
format_settings_mp4() {
    supported_audiocodecs="$(cat <<- __EOF__
		$audiocodecs_aac
		$audiocodecs_opus
		$audiocodecs_vorbis
		$audiocodecs_mp3
__EOF__
)"
    supported_videocodecs="$(cat <<- __EOF__
		$videocodecs_h264
		$videocodecs_hevc
		$videocodecs_vp9
		$videocodecs_av1
__EOF__
)"
    possible_unplayable_videocodecs="$(cat <<- __EOF__
		$videocodecs_vp9
__EOF__
)"
    
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
    
    supported_audiocodecs="$(cat <<- __EOF__
		$audiocodecs_aac
		$audiocodecs_vorbis
		$audiocodecs_mp3
		$audiocodecs_wma
__EOF__
)"
    supported_videocodecs="$(cat <<- __EOF__
		$videocodecs_h264
		$videocodecs_hevc
		$videocodecs_theora
		$videocodecs_wmv
__EOF__
)"
    possible_unplayable_audiocodecs="$(cat <<- __EOF__
		$audiocodecs_vorbis
		$audiocodecs_wma
__EOF__
)"
    possible_unplayable_videocodecs="$(cat <<- __EOF__
		$videocodecs_theora
		$videocodecs_wmv
__EOF__
)"
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
    supported_audiocodecs="$(cat <<- __EOF__
		$audiocodecs_opus
		$audiocodecs_vorbis
__EOF__
)"
    supported_videocodecs="$(cat <<- __EOF__
		$videocodecs_vp8
		$videocodecs_vp9
		$videocodecs_av1
__EOF__
)"
    
    # check if the detected ffmpeg build has support for the webm muxer
    check_component "$format" muxer || component_error "$format" muxer true
    
    # auto choose audio/video encoder if needed
    if [ "$audio_encoder_setted" = 'false' ]
    then
        audio_encoder="$(printf '%s' "$audiocodecs_opus" | head -n1)"
        audio_outstr='(auto chosen)'
    fi
    
    if [ "$video_encoder_setted" = 'false' ]
    then
        video_encoder="$(printf '%s' "$videocodecs_vp9" | head -n1)"
        video_outstr='(auto chosen)'
    fi
}

format_settings_ogg() {
    supported_audiocodecs="$(cat <<- __EOF__
		$audiocodecs_opus
		$audiocodecs_vorbis
__EOF__
)"
    supported_videocodecs="$(cat <<- __EOF__
		$videocodecs_vp8
		$videocodecs_theora
__EOF__
)"
    
    # check if the detected ffmpeg build has support for the ogg/ogv muxer
    check_component "$format" muxer || component_error "$format" muxer true
    
    # auto choose audio/video encoder if needed
    if [ "$audio_encoder_setted" = 'false' ]
    then
        audio_encoder="$(printf '%s' "$audiocodecs_vorbis" | head -n1)"
        audio_outstr='(auto chosen)'
    fi
    
    if [ "$video_encoder_setted" = 'false' ]
    then
        video_encoder="$(printf '%s' "$videocodecs_theora" | head -n1)"
        video_outstr='(auto chosen)'
    fi
}

format_settings_ogv() {
    format_settings_ogg "$@"
}

format_settings_flv() {
    supported_audiocodecs="$(cat <<- __EOF__
		$audiocodecs_aac
		$audiocodecs_mp3
__EOF__
)"
    supported_videocodecs="$(cat <<- __EOF__
		$videocodecs_h264
__EOF__
)"
    
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
    supported_audiocodecs="$(cat <<- __EOF__
		$audiocodecs_aac
		$audiocodecs_vorbis
		$audiocodecs_mp3
		$audiocodecs_wma
__EOF__
)"
    supported_videocodecs="$(cat <<- __EOF__
		$videocodecs_h264
		$videocodecs_vp8
		$videocodecs_vp9
		$videocodecs_theora
		$videocodecs_wmv
		$videocodecs_av1
__EOF__
)"
    
    # check if the detected ffmpeg build has support for the asf muxer
    # note: asf muxer is used for wmv (and wma) container format
    check_component asf muxer || component_error asf muxer true
}

format_settings_asf() {
    format_settings_wmv "$@"
}

format_settings_avi() {
    # note: avi container formats supports all valid video encoders for this program
    supported_audiocodecs="$(cat <<- __EOF__
		$audiocodecs_aac
		$audiocodecs_vorbis
		$audiocodecs_mp3
		$audiocodecs_wma
__EOF__
)"
    supported_videocodecs="$supported_videocodecs_all"
    
    # check if the detected ffmpeg build has support for the avi muxer
    check_component "$format" muxer || component_error "$format" muxer true
}
