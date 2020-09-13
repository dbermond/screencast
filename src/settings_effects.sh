#!/bin/sh
# shellcheck disable=SC2034,SC2154

# settings_effects.sh - effects settings for screencast
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
#            effects settings           #
#########################################

# watermark settings
watermark_font='DejaVu-Sans'
watermark_size='256x36'
watermark_position='bottomright'
    # good absolute position values for hd720p (1280x720) with default watermark size:
    # 970,10  - top right corner
    # 10,10   - top left  corner
    # 970,688 - bottom right corner
    # 10,688  - bottom left  corner
    # 550,350 - centralized

# webcam settings
webcam_input_options="-f video4linux2 -thread_queue_size ${queue_size} -probesize 10M"
webcam_size='320x240'
webcam_input='/dev/video0'
webcam_position='topright'

# effect settings functions
# description: make settings for the selected effect(s)
# arguments: none
# return value: none
# return code (status): not relevant
# sets special variables: various, depending on the effect
get_supported_fade() {
    supported_fade="$(cat <<- __EOF__
		none
		in
		out
		both
__EOF__
)"
}

get_supported_pngoptmz() {
    supported_pngoptmz="$(cat <<- __EOF__
		none
		optipng
		oxipng
		opt-png
		truepng
		pingo
__EOF__
)"
}

get_fade_settings() {
    fade_color='black'      # color to be used by the video fade effect
    fade_length='0.6'       # length (in seconds) of video fade effect itself
    fade_solid_length='0.1' # solid color length (in seconds) of video fade effect
}

get_supported_streaming_settings() {
    # container formats that supports the audio/video encoders of the allowed flv muxers
    supported_streaming_formats="$(cat <<- __EOF__
		mp4
		mov
		mkv
		flv
		nut
		wmv
		asf
		avi
__EOF__
)"
    
    # flv muxer restrictions
    supported_streaming_audiocodecs="$(cat <<- __EOF__
		$audiocodecs_aac
		$audiocodecs_mp3
__EOF__
)"
    supported_streaming_videocodecs="$(cat <<- __EOF__
		$videocodecs_h264
__EOF__
)"
}

get_pngoptmz_settings_truepng() {
    pngoptmz_settings='-o max'
}

get_pngoptmz_settings_pingo() {
    pngoptmz_settings='-s8'
}

get_pngoptmz_settings_optipng() {
    pngoptmz_settings='-o 7'
}

get_pngoptmz_settings_oxipng() {
    pngoptmz_settings='-o 6 --strip safe'
}

get_pngoptmz_settings_advdef() {
    advdef_settings='-z4i10'
}
