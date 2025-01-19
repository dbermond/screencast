#!/bin/sh
# shellcheck disable=SC2034

# settings_general.sh - general settings for screencast
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
#           general settings            #
#########################################

# program settings
screencast_version=
screencast_website='https://github.com/dbermond/screencast/'

# system related settings
queue_size='3096'            # ffmpeg thread queue size
ffplay_volume='35'           # ffplay playback volume (0-100)
expire_time_short='1700'     # expire time for short notifications
expire_time_normal='3000'    # expire time for normal notifications
expire_time_long='5000'      # expire time for long notifications
savedir="$(pwd)"             # path to save output files
tmpdir="${XDG_CACHE_HOME:-"${HOME}/.cache"}/screencast" # path to save temporary files
error_icon='dialog-error'
record_icon='media-record'
encode_icon='media-playback-stop'
finish_icon_generic='video-x-generic'
finish_icon_oxygen='/usr/share/icons/oxygen/base/128x128/actions/dialog-ok-apply.png'
finish_sound='/usr/share/sounds/freedesktop/stereo/complete.oga'

# control settings (controls various aspects)
saving_output='true'          # if user is saving an output video (true, false)
recording_audio='true'        # if user is recording audio (true, false)
select_region='false'         # mouse screen region selection (true, false)
auto_filename='false'         # auto choose output filename based on date/time
keep_video='false'            # keep live streaming or the tmp video (true, false)
fade='none'                   # fade effect (in, out, both, none)
volume_increase='false'       # volume increase effect (true, false)
watermark='false'             # watermark effect (true, false)
pngoptimizer='none'           # png (watermark) optimizer (truepng, pingo, optipng, opt-png, none)
webcam_overlay='false'        # webcam overlay effect (true, false)
streaming='false'             # live streaming (true, false)
one_step='false'              # one step process (true, false)
one_step_lossless='false'     # one step process without encoding the lossless video (true, false)
fixed_length='0'              # fixed length video in seconds (0 disable)
notifications='true'          # desktop notifications (true, false)
audio_input_setted='false'    # if audio input    was setted by cmd line with -i
audio_channels_setted='false' # if audio channels was setted by cmd line with -c
audio_encoder_setted='false'  # if audio encoder  was setted by cmd line with -a
display_setted='false'        # if display        was setted by cmd line with -d
border_setted='false'         # if border         was setted by cmd line with -b
video_encoder_setted='false'  # if video encoder  was setted by cmd line with -v
hwdevice_setted='false'       # if the hw device  was setted by cmd line with -D
video_size_setted='false'     # if video size     was setted by cmd line with -s
video_posi_setted='false'     # if video position was setted by cmd line with -p
video_rate_setted='false'     # if video rate/fps was setted by cmd line with -r
format_setted='false'         # if video format   was setted by cmd line with -f
fade_setted='false'           # if fade effect    was setted by cmd line with -e
volume_factor_setted='false'  # if volume factor  was setted by cmd line with -m
wmark_size_setted='false'     # if wmark size     was setted by cmd line with -z
wmark_posi_setted='false'     # if wmark position was setted by cmd line with -k
wmark_font_setted='false'     # if wmark font     was setted by cmd line with -c
webcam_input_setted='false'   # if webcam input   was setted by cmd line with -I
webcam_size_setted='false'    # if webcam size    was setted by cmd line with -Z
webcam_posi_setted='false'    # if wcam position  was setted by cmd line with -P
webcam_rate_setted='false'    # if webcam fps     was setted by cmd line with -R
one_step_setted='false'       # if one step       was setted by cmd line with -1
fixed_length_setted='false'   # if fixed length   was setted by cmd line with -x
pngoptimizer_setted='false'   # if png optimizer  was setted by cmd line with -g
outputdir_setted='false'      # if output dir     was setted by cmd line with -o
tmpdir_setted='false'         # if tmp dir        was setted by cmd line with -t

# audio settings
audio_input='default'        # audio input
audio_encoder='aac'          # audio encoder
volume_factor='1.0'          # volume increase effect factor (0.0/1.0 disable)
audio_input_channels='1'
audio_output_channels='2'
audio_channel_layout='-channel_layout mono' # audio channel layout for inputs
audio_input_options="-f alsa -thread_queue_size ${queue_size} -sample_rate 48000"

# video settings
video_encoder='x264'               # video encoder
pixel_format='yuv420p'             # pixel format
format='mp4'                       # container format (file extension) for output
video_position='0,0' #200,234      # X and Y screen coordinates to record video from
video_size='640x480'               # video size (resolution)
video_rate='25'                    # video framerate (fps)
corner_padding='10'                # video corner padding (for watermark and webcam effects)
display=':0.0'                     # display (and screen) number(s) ($DISPLAY environment variable)
border='2'                         # tickness of the screen region border delimiter (0 to disable border)
border_options="-show_region 1 -region_border ${border}"
video_input_options="-f x11grab -thread_queue_size ${queue_size} -probesize 20M"
hwencoder='false'
nvenc_default_hwdevice='0'
qsv_default_hwdevice='hw'
vaapi_default_hwdevice='/dev/dri/renderD128'
vulkan_default_hwdevice='0'

# metadata settings
metadata="comment=$(printf '%s\n%s' "Created with screencast ${screencast_version}" "${screencast_website}")"

# default options for later comparison (to print informative messages)
audio_encoder_default="$audio_encoder"
video_encoder_default="$video_encoder"
format_default="$format"
