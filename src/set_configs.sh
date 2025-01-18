#!/bin/sh
# shellcheck disable=SC2034,SC2154

# set_configs.sh - set various configurations for screencast
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
#              set configs              #
#########################################

# description: set needed options for live streaming (-L/--live-streaming)
# arguments: none
# return value: none
# return code (status): not relevant
set_live() {
    # set ffmpeg '-maxrate' and '-bufsize' options
    if   [ "$video_height" -gt '2160' ]
    then
         if [ "$video_rate" -ge '60' ]
         then
             video_encode_codec="${video_encode_codec} -maxrate 40M -bufsize 80M"
         else
             video_encode_codec="${video_encode_codec} -maxrate 30M -bufsize 60M"
         fi
         
    elif [ "$video_height" -eq '2160' ]
    then
         if [ "$video_rate" -ge '60' ]
         then
             video_encode_codec="${video_encode_codec} -maxrate 22M -bufsize 44M"
         else
             video_encode_codec="${video_encode_codec} -maxrate 15M -bufsize 30M"
         fi
         
    elif [ "$video_height" -eq '1440' ] ||
         {
             [ "$video_height" -lt '2160' ] &&
             [ "$video_height" -gt '1440' ];
         }
    then
         if [ "$video_rate" -ge '60' ]
         then
             video_encode_codec="${video_encode_codec} -maxrate 10M -bufsize 20M"
         else
             video_encode_codec="${video_encode_codec} -maxrate 7M -bufsize 14M"
         fi
         
    elif [ "$video_height" -eq '1080' ] ||
         {
             [ "$video_height" -lt '1440' ] &&
             [ "$video_height" -gt '1080' ];
         }
    then
         if [ "$video_rate" -ge '60' ]
         then
             video_encode_codec="${video_encode_codec} -maxrate 5M -bufsize 10M"
         else
             video_encode_codec="${video_encode_codec} -maxrate 4M -bufsize 8M"
         fi
         
    elif [ "$video_height" -eq '720' ] ||
         {
             [ "$video_height" -lt '1080' ] &&
             [ "$video_height" -gt '720'  ];
         }
    then
         if [ "$video_rate" -ge '60' ]
         then
             video_encode_codec="${video_encode_codec} -maxrate 3M -bufsize 6M"
         else
             video_encode_codec="${video_encode_codec} -maxrate 2M -bufsize 4M"
         fi
         
    elif [ "$video_height" -eq '480' ] ||
         {
             [ "$video_height" -lt '720' ] &&
             [ "$video_height" -gt '480' ];
         }
    then
         video_encode_codec="${video_encode_codec} -maxrate 1M -bufsize 2M"
         
    elif [ "$video_height" -eq '360' ] ||
         {
             [ "$video_height" -lt '480' ] &&
             [ "$video_height" -gt '360' ];
         }
    then
         video_encode_codec="${video_encode_codec} -maxrate 500k -bufsize 1000k"
         
    elif [ "$video_height" -eq '240' ] ||
         {
             [ "$video_height" -lt '360' ] &&
             [ "$video_height" -gt '240' ];
         }
    then
         video_encode_codec="${video_encode_codec} -maxrate 400k -bufsize 800k"
         
    else
         video_encode_codec="${video_encode_codec} -maxrate 2M -bufsize 4M"
    fi
    
    video_encode_codec="${video_encode_codec} -g $((video_rate * 2))" # set gop size
}

# description: enable watermark effect if chosen by user (-w/--watermark)
# arguments: none
# return value: none
# return code (status): not relevant
set_watermark() {
    if [ "$watermark" = 'true' ]
    then
        check_dir "$tmpdir"
        
        if create_watermark
        then
            ff_watermark_options="-framerate ${video_rate} -thread_queue_size ${queue_size} -i ${wmark_image}"
            
            watermark_vfilter="overlay=${watermark_position}"
            
            ff_vfilter_option='-filter_complex'
            ff_vfilter_settings="${ff_vfilter_settings:+"${ff_vfilter_settings},${watermark_vfilter}"}"
            ff_vfilter_settings="${ff_vfilter_settings:-"$watermark_vfilter"}"
        fi
    fi
}

# description: enable webcam overlay effect if chosen by user (-W/--webcam)
# arguments: none
# return value: none
# return code (status): not relevant
set_webcam() {
    if [ "$webcam_overlay" = 'true' ]
    then
        check_component video4linux2,v4l2 demuxer || component_error video4linux2,v4l2 demuxer false
        
        [ "$webcam_rate_setted" = 'true' ] && ff_webcam_options="-framerate ${webcam_rate}"
        
        ff_webcam_options="${webcam_input_options} ${ff_webcam_options} -video_size ${webcam_size} -i ${webcam_input}"
        
        ff_vfilter_option='-filter_complex'
        ff_vfilter_settings="${ff_vfilter_settings:+"${ff_vfilter_settings},overlay=${webcam_position}:format=auto"}"
        ff_vfilter_settings="${ff_vfilter_settings:-"overlay=${webcam_position}:format=auto"}"
    fi
}

# description:
#   enable volume increase effect if chosen by user (-m/--volume-factor)
#   (to enable: a value different than '1.0' or '0.0')
# arguments: none
# return value: none
# return code (status): not relevant
set_volume() {
    [ "$volume_increase" = 'true' ] && ff_volume_options="-af volume=${volume_factor}"
}

# description: fix 'pass duration too large' messages in ffmpeg
# arguments: none
# return value: none
# return code (status): not relevant
fix_pass_duration() {
    [ "$webcam_overlay" = 'false' ] && [ "$watermark" = 'false' ] && ff_vfilter_option='-vf'
    ff_vfilter_settings="${ff_vfilter_settings:+"${ff_vfilter_settings},fps=${video_rate}"}"
    ff_vfilter_settings="${ff_vfilter_settings:-"fps=${video_rate}"}"
}

# description:
#   initialize hardware for accelerated video encoders
#   (-v/--video-encoder) if they are chosen by the user
# arguments: none
# return value: none
# return code (status): not relevant
set_hw_device_and_pixel_format() {
    if [ "$hwencoder" = 'true' ]
    then
        if [ "$one_step" = 'true' ]
        then
            [ "$webcam_overlay" = 'false' ] && [ "$watermark" = 'false' ] && [ "$fade" = 'none'  ] && ff_vfilter_option='-vf'
        else
            [ "$streaming"      = 'false' ] && [ "$watermark" = 'false' ] && [ "$fade" = 'none'  ] && ff_vfilter_option='-vf'
        fi
        
        pixel_format='nv12'
        ff_init_hw_options="-init_hw_device ${hwaccel}=gpu:${hwdevice} -filter_hw_device gpu"
        ff_vfilter_settings="${ff_vfilter_settings:+"${ff_vfilter_settings},format=${pixel_format},hwupload"}"
        ff_vfilter_settings="${ff_vfilter_settings:-"format=${pixel_format},hwupload"}"
    else
        ff_pixfmt_options="-pix_fmt ${pixel_format}"
    fi
}
