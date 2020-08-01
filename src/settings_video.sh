#!/bin/sh
# shellcheck disable=SC2034,SC2154

# settings_video.sh - video encoder settings for screencast
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
#         video encoder settings        #
#########################################

# supported video encoders (one per line for accurate grepping and easy deletion)
supported_videocodecs_all="$(printf 'x264\nh264_nvenc\nh264_vaapi\nh264_qsv
                                     x265\nkvazaar\nsvt_hevc\nhevc_nvenc\nhevc_vaapi\nhevc_qsv
                                     vp8\nvp8_vaapi
                                     vp9\nvp9_vaapi
                                     theora\nwmv\naom_av1\nrav1e' | sed 's/^[[:space:]]*//g')"

supported_videocodecs_software="$(printf 'x264\nx265\nkvazaar\nsvt_hevc\nvp8\nvp9\n\ntheora\nwmv\naom_av1\nrav1e')"
supported_videocodecs_lossless="$(printf 'ffv1\nffvhuff\nhuffyuv')"
largefile_videocodecs_lossless="$(printf 'ffvhuff\nhuffyuv')"

# supported video encoders (for use with show_list() in -l/--list option)
get_list_videocodecs() {
    for item in $supported_videocodecs_all
    do
        list_videocodecs="${list_videocodecs:-}${item}, "
    done
    
    # shellcheck disable=SC1004
    list_videocodecs="$(printf '%s' "$list_videocodecs" | sed 's/,[[:space:]]$//;s/[[:space:]]svt_hevc.*/\
                        &/;s/[[:space:]]vp8_vaapi.*/\
                        &/')"
}

# get_videocodecs_for_nonmulti8_msg function: defines video encoders to be used with dimension_msg()
# arguments: none
# return value: none
# return code (status): not relevant
# sets special variables: $msg_speedloss_videocodecs   - video encoders that can lead to speedloss with non multiple of
#                                                        8 dimensions (one per line)
#                         $msg_requirement_videocodecs - video encoders requires multiple of 8 dimensions (one per line)
get_videocodecs_for_nonmulti8_msg() {
    msg_speedloss_videocodecs="$(printf '%s' "$supported_videocodecs_all" |
                                     sed '/^x265$/d;/^kvazaar$/d;/^hevc_nvenc$/d;/^hevc_vaapi$/d;/^hevc_qsv$/d')"
    
    msg_requirement_videocodecs="$(printf 'x265\nkvazaar\nhevc_nvenc\nhevc_vaapi\nhevc_qsv')"
}

# lossless video encoder settings functions: make checks and settings for lossless video encoder
#                                           (for the 1st step, lossless recording)
# arguments: none
# return value: not relevant
# return code (status): 0 - the detected ffmpeg build has support for the tested lossless video_encoder
#                       1 - the detected ffmpeg build has no support for the tested lossless video encoder
# sets special variable: $video_record_codec - ffmpeg lossless video codec option and settings
# note: the program will exit with error if the selected lossless video encoder is not supported by the detected ffmpeg build
lossless_videocodec_settings_ffv1() {
    if check_component ffv1 encoder &&
       check_component ffv1 decoder
    then
        video_record_codec='ffv1 -level 3 -slicecrc 1'
    else
        return 1
    fi
}

lossless_videocodec_settings_ffvhuff() {
    if check_component ffvhuff encoder &&
       check_component ffvhuff decoder
    then
        video_record_codec='ffvhuff'
    else
        return 1
    fi
}

lossless_videocodec_settings_huffyuv() {
    if check_component huffyuv encoder &&
       check_component huffyuv decoder
    then
        video_record_codec='huffyuv'
    else
        return 1
    fi
}

# video encoder settings functions: make checks and settings for the selected video encoder
# arguments: none
# return value: none
# return code (status): not relevant
# sets special variable: $video_encode_codec - ffmpeg video codec settings
# note: the program will exit with error if the selected video encoder is not supported by the detected ffmpeg build
videocodec_settings_x264() {
    check_component libx264 encoder || component_error libx264 'video encoder' true
    
    if [ "$streaming" = 'true' ] 
    then
        video_encode_codec='libx264 -crf 30 -preset veryfast'
    else
        if [ "$one_step" = 'true' ] 
        then
            video_encode_codec='libx264 -crf 21 -preset ultrafast'
        else
            video_encode_codec='libx264 -crf 21 -preset veryslow'
        fi
    fi
}

videocodec_settings_h264_nvenc() {
    check_component h264_nvenc encoder || component_error h264_nvenc 'video encoder' true
    video_encode_codec='h264_nvenc -qmin 10 -qmax 42 -preset slow -cq 10 -bf 2 -g 150'
}

videocodec_settings_h264_vaapi() {
    check_component h264_vaapi encoder || component_error h264_vaapi 'video encoder' true
    check_vaapi_device
    video_encode_codec='h264_vaapi -qp 18'
}

videocodec_settings_h264_qsv() {
    check_component h264_qsv encoder || component_error h264_qsv 'video encoder' true
    video_encode_codec='h264_qsv -preset:v medium -rdo 1 -qscale:v 5 -look_ahead 0'
}

videocodec_settings_x265() {
    check_component libx265 encoder || component_error libx265 'video encoder' true
    
    if [ "$one_step" = 'true' ] 
    then
        video_encode_codec='libx265 -crf 25 -preset ultrafast'
    else
        video_encode_codec='libx265 -crf 25 -preset veryslow'
    fi
}

videocodec_settings_kvazaar() {
    check_component libkvazaar encoder || component_error libkvazaar 'video encoder' true
    
    if [ "$one_step" = 'true' ] 
    then
        video_encode_codec='libkvazaar -kvazaar-params preset=ultrafast'
    else
        video_encode_codec='libkvazaar -kvazaar-params preset=veryslow'
    fi
}

videocodec_settings_svt_hevc() {
    check_component libsvt_hevc encoder || component_error libsvt_hevc 'video encoder' true
    video_encode_codec='libsvt_hevc -rc vbr -tune sq'
}

videocodec_settings_hevc_nvenc() {
    check_component hevc_nvenc encoder || component_error hevc_nvenc 'video encoder' true
    video_encode_codec='hevc_nvenc -preset slow'
}

videocodec_settings_hevc_vaapi() {
    check_component hevc_vaapi encoder || component_error hevc_vaapi 'video encoder' true
    check_vaapi_device
    video_encode_codec='hevc_vaapi -qp 22'
}

videocodec_settings_hevc_qsv() {
    check_component hevc_qsv encoder || component_error hevc_qsv 'video encoder' true
    video_encode_codec='hevc_qsv -load_plugin hevc_hw -preset:v medium -rdo 1 -qscale:v 5 -look_ahead 0'
}

videocodec_settings_vp8() {
    check_component libvpx encoder || component_error libvpx 'video encoder' true
    video_encode_codec='libvpx -crf 8 -b:v 2M'
}

videocodec_settings_vp8_vaapi() {
    check_component vp8_vaapi encoder || component_error vp8_vaapi 'video encoder' true
    check_vaapi_device
    video_encode_codec='vp8_vaapi -global_quality 30'
}

videocodec_settings_vp9() {
    check_component libvpx-vp9 encoder || component_error libvpx-vp9 'video encoder' true
    video_encode_codec='libvpx-vp9 -crf 30 -b:v 0'
}

videocodec_settings_vp9_vaapi() {
    check_component vp9_vaapi encoder || component_error vp9_vaapi 'video encoder' true
    check_vaapi_device
    video_encode_codec='vp9_vaapi -global_quality 80'
}

videocodec_settings_theora() {
    check_component libtheora encoder || component_error libtheora 'video encoder' true
    video_encode_codec='libtheora -qscale:v 5'
}

videocodec_settings_wmv() {
    check_component wmv2 encoder || component_error wmv2 'video encoder' true
    video_encode_codec='wmv2 -qscale:v 3'
}

videocodec_settings_aom_av1() {
    check_component libaom-av1 encoder || component_error libaom-av1 'video encoder' true
    video_encode_codec='libaom-av1 -crf 27 -b:v 0 -strict experimental'
}

videocodec_settings_rav1e() {
    check_component librav1e encoder || component_error librav1e 'video encoder' true
    video_encode_codec='librav1e -qp 90 -speed 5 -rav1e-params low_latency=true'
}
