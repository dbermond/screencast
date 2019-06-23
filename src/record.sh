#!/bin/sh
# shellcheck disable=SC2034,SC2154

# record.sh - recording routines for screencast
#
# Copyright (c) 2015-2019 Daniel Bermond < gmail.com: danielbermond >
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
#                record                 #
#########################################

# live_streaming function: record and live stream
# arguments: none
# return value: none
# return code (status): not relevant
# note: it will make the program exit with error if a recording error occurs
live_streaming() {
    set_live
    set_watermark
    set_vaapi_qsv
    set_volume

    ff_audio_codec="$audio_encode_codec"
    ff_video_codec="$video_encode_codec"
    ff_pixfmt_options="-pix_fmt ${pixel_format}"
    
    print_good 'live streaming'
    notify 'normal' '1700' 'media-record' 'live streaming...'
    
    # do the live stream and save the recorded content to an output file
    if [ "$saving_output" = 'true' ] 
    then
        check_dir "$savedir"
        
        ff_flag_global_header='-flags +global_header'
        ff_map='-map 1:v -map 0:a'
        ff_output="-f tee ${tee_faststart}${savedir}/${output_file}|[f=flv]${streaming_url}"
        
    # live streaming only, do not save the recorded content to an output file
    else
        ff_output="-f flv ${streaming_url}"
    fi
    
    if run_ffmpeg
    then
        finish
    else
        recording_error
    fi
}

# record_offline_one_step function: record offline (without live streaming) using one step
#                                   (recording and encoding at the same time).
# arguments: none
# return value: none
# return code (status): not relevant
# note: it will make the program exit with error if a recording error occurs
record_offline_one_step() {
    set_watermark
    set_vaapi_qsv
    set_volume
    check_dir "$savedir"
    
    ff_audio_codec="$audio_encode_codec"
    ff_video_codec="$video_encode_codec"
    ff_pixfmt_options="-pix_fmt ${pixel_format}"
    ff_output="${savedir}/${output_file}"
    
    print_good 'recording (one step process)'
    notify 'normal' '1700' 'media-record' 'recording (one step)...'
    
    # record screen and encode in one step
    if run_ffmpeg
    then
        finish
    else
        recording_error
    fi
}

# record_offline_two_steps function: record offline (without live streaming) using two steps
#                                    (1st step: lossless recording. 2nd step: encoding).
# arguments: none
# return value: none
# return code (status): not relevant
# note: it will make the program exit with error if a recording or encoding error occurs
record_offline_two_steps() {
    [ "$webcam_overlay" = 'false' ] && [ "$watermark" = 'true' ] && ff_vfilter_option='-vf'
    
    set_tmpdir
    check_dir "$savedir"
    check_dir "$tmpdir"
    
    rndstr_video="$(randomstr '20')" # random string for tmp video filename
    
    ff_audio_codec="$audio_record_codec"
    ff_video_codec="$video_record_codec"
    ff_output="${tmpdir}/screencast-lossless-${$}-${rndstr_video}.${rec_extension}"
    
    print_good 'recording'
    notify 'normal' '1700' 'media-record' 'recording...'
    
    # record screen to a lossless video
    if run_ffmpeg
    then
        unset ff_vfilter_option
        unset ff_vfilter_settings
        unset ff_webcam_options
        
        set_watermark
        
        # enable fade effect if chosen by user (-e/--fade)
        if [ "$fade" != 'none' ] 
        then
            videofade
            [ "$watermark" = 'false' ] && ff_vfilter_option='-vf'
            ff_vfilter_settings="${ff_vfilter_settings:+"${ff_vfilter_settings},${fade_options}"}"
            ff_vfilter_settings="${ff_vfilter_settings:-"${fade_options}"}"
        fi
        
        set_vaapi_qsv
        set_volume
        
        ff_audio_options="${audio_channel_layout}"
        ff_video_options="-i ${tmpdir}/screencast-lossless-${$}-${rndstr_video}.${rec_extension}"
        ff_audio_codec="$audio_encode_codec"
        ff_video_codec="$video_encode_codec"
        ff_pixfmt_options="-pix_fmt ${pixel_format}"
        ff_map='-map 0'
        ff_output="${savedir}/${output_file}"
        
        print_good 'encoding'
        notify 'normal' '3000' 'media-playback-stop' 'encoding...'
        
        # encode the recorded lossless video file
        if run_ffmpeg
        then
            finish
        else
            encoding_error
        fi
    else
        recording_error
    fi
}
