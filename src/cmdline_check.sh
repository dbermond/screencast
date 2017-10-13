#!/bin/sh
# shellcheck disable=SC2034,SC2154

# cmdline_check.sh - check command line for screencast
#
# Copyright (c) 2015-2017 Daniel Bermond < yahoo.com: danielbermond >
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
#          command line checks          #
#########################################

# check_cmd_line function: check validity of command line options and arguments (aslo set some variables)
#                          (will exit with error if any inconsistency is found)
# arguments: the remainder positional parameters passed with double quotes ("$@")
# return value: none
# return code (status): not relevant
check_cmd_line() {
    if [ "$select_region" = 'true' ] 
    then
        # do not allow to use -S/--select-region with -s/--size or -p/--position
        [ "$video_size_setted" = 'true' ] && exit_program '--select-region (-S) option cannot be used with --size (-s) option'
        [ "$video_posi_setted" = 'true' ] && exit_program '--select-region (-S) option cannot be used with --position (-p) option'
    else
        # preparations for check_dimension() and check_screen()
        video_position_x="$(printf '%s' "$video_position" | awk -F',' '{ printf $1 }')"
        video_position_y="$(printf '%s' "$video_position" | awk -F',' '{ printf $2 }')"
        video_width="$(     printf '%s' "$video_size"     | awk -F'x' '{ printf $1 }')"
        video_height="$(    printf '%s' "$video_size"     | awk -F'x' '{ printf $2 }')"
        
        if [ "$video_size_setted" = 'true' ] 
        then
            # check for a valid video size format (NxN) (-s/--size)
            printf '%s' "$video_size" | grep -Eq '^[0-9]+x[0-9]+$' || exit_program "'${video_size}' is not a valid video size format"
            
            # check if video width and height are a multiple of 8
            check_dimension "$video_width"  || exit_program "$(dimension_msg 'width')"
            check_dimension "$video_height" || exit_program "$(dimension_msg 'height')"
        fi
        
        if [ "$video_posi_setted" = 'true' ] 
        then
            # check for a valid screen position format to record (N,N) (-p/--position)
            printf '%s' "$video_position" | grep -Eq '^[0-9]+,[0-9]+$' || exit_program "'${video_position}' is not a valid screen position format"
        fi
        
        check_screen
    fi
    
    if [ "$video_rate_setted" = 'true' ] 
    then
        # check if the entered framerate (fps) is a valid integer number (-r/--fps)
        # (when live streaming, the video framerate (fps) cannot be a floating point number
        #  because it will be multiplied by two to obtain the gop value. This multiplication
        #  will be done using the shell simple aritmetic operator, which does not support floats.
        #  This will make bc to be required only when using fade effect.)
        if [ "$streaming" = 'true' ] 
        then
            if ! printf '%s' "$video_rate" | grep -Eq '^[0-9]+$'
            then
                if printf '%s' "$video_rate" | grep -Eq '^[0-9]+(\.[0-9]+)?$'
                then
                    exit_program 'video framerate (fps) cannot be a floating point value when live streaming'
                else
                    exit_program "'${video_rate}' is not a valid video framerate (fps) format"
                fi
            fi
        
        # check if the entered framerate (fps) is a valid integer/float number (-r/--fps)
        else
            printf '%s' "$video_rate" | grep -Eq '^[0-9]+(\.[0-9]+)?$' ||
                exit_program "'${video_rate}' is not a valid video framerate (fps) format"
        fi
    fi
    
    # check if user entered a valid audio encoder
    if [ "$audio_encoder_setted" = 'true' ] 
    then
        if ! printf '%s' "$supported_audiocodecs_all" | grep -q "^${audio_encoder}$"
        then
            exit_program "'${audio_encoder}' is not a valid audio encoder for this program"
        fi
    fi
    
    # check if user entered a valid video encoder
    if [ "$video_encoder_setted" = 'true' ] 
    then
        if ! printf '%s' "$supported_videocodecs_all" | grep -q "^${video_encoder}$"
        then
            exit_program "'${video_encoder}' is not a valid video encoder for this program"
        fi
    fi
    
    # check if user is recording audio (if not, modify the corresponding control variable)
    if [ "$audio_input" = 'none' ] || [ "$audio_encoder" = 'none' ] 
    then
        recording_audio='false'
    fi
    
    # check if user is saving an output video (if not, modify the corresponding control variable)
    [ "$streaming"  = 'true' ] && [ "$keep_video" = 'false' ] && saving_output='false'
    
    # check if user entered a valid fade effect (-e/--fade)
    if [ "$fade_setted" = 'true' ] 
    then
        get_supported_fade
        
        if printf '%s' "$supported_fade" | grep -q "^${fade}$"
        then
            # do not allow to use fade effect when using a one step process (-1/--one-step)
            [ "$one_step"  = 'true' ] && [ "$fade" != 'none' ] && exit_program 'fade effect (-e) cannot be used when using a one step process (-1)'
        else
            exit_program "'${fade}' is not a valid fade effect for this program"
        fi
    fi
    
    # checks and settings based on usage of the '-u' option
    if [ "$auto_filename" = 'false' ] 
    then
        # check if user have not entered an output filename after the options (only if saving the output video)
        [ "$#" -eq '0' ] && [ "$saving_output" = 'true' ] && exit_program "you must enter an output filename with extension (or use '-u')"
        
        # do not allow to enter an output filename when not saving the live streaming
        [ "$#" -eq '1' ] && [ "$saving_output" = 'false' ] &&
            exit_program "output filename was specified but but not saving the live streaming ('-K' not set)"
        
        # do not allow to enter anything after the output filename
        [ "$#" -gt '1' ] && exit_program 'please do not enter anything after the output filename'
        
        # do not allow to use -f/--format when specifying an output filename
        if [ "$format_setted" = 'true' ] &&
           {
               [ "$streaming" = 'false' ] ||
               {
                   [ "$streaming"  = 'true'  ] &&
                   [ "$keep_video" = 'false' ] ;
               } ;
           }
        then
            exit_program "--format (-f) option can be used only with --auto-filename (-u)
                      (when not using '-u', set format in the output filename)"
        fi
        
        # do not allow to use -o/--output-dir when specifying an output filename
        if [ "$outputdir_setted" = 'true' ] &&
           {
               [ "$streaming" = 'false' ] ||
               {
                   [ "$streaming"  = 'true'  ] &&
                   [ "$keep_video" = 'false' ] ;
               } ;
           }
        then
            exit_program "--output-dir (-o) option can be used only with --auto-filename (-u)
                      (when not using '-u', set output directory with the output filename)"
        fi
        
        # if user specified a save directory directly with output filename that
        # is different than the current working directory, use it
        [ "$(dirname "$1")" != '.' ] && savedir="$(dirname "$1")"
        
        # if user specified './' as a save directory directly with output
        # filename, use it ('pwd' makes the program output more clear)
        printf '%s' "$1" | grep -q '^\./.*' && savedir="$(pwd)"
        
        # the case that user specifies '../' as a save directory directly with
        # output filename is already covered above in
        # 'if [ "$(dirname "$1")" != "." ]'. here we just use 'dirname "$(pwd)"'
        # to make the program output more clear
        printf '%s' "$1" | grep -q '^\.\./.*' && savedir="$(printf '%s' "$(dirname "$(pwd)")")"
        
        # set the output filename and get the container format (only if saving the output video)
        if [ "$saving_output" = 'true' ] 
        then
            output_file="$(basename "$1")" # set the output filename
            format="${output_file##*.}"    # set container format (output filename extension)
        fi
    else
        # do not allow to use '-u' when not saving the live streaming
        [ "$saving_output" = 'false' ] && exit_program "'-u' is set but not saving the live streaming ('-K' not set)"
        
        # if '-u' is set, don't allow to set an output filename in command line
        [ "$#" -gt '0' ] && exit_program '--auto-filename (-u) does not allow to set an output filename'
        
        current_time="$(date +%Y-%m-%d_%H.%M.%S)" # get current time for placing on filename
        
        # set the output filename
        if [ "$streaming" = 'true' ] 
        then
            output_file="screencast-livestreaming-${current_time}.${format}"
        else
            output_file="screencast-${current_time}.${format}"
        fi
    fi
    
    # check if user entered a valid container format
    if [ "$format_setted" = 'true' ] ||
       {
           [ "$auto_filename" = 'false' ] &&
           [ "$saving_output" = 'true'  ] ;
       }
    then
        if ! printf '%s' "$supported_formats_all" | grep -q "^${format}$"
        then
           exit_program "'${format}' is not a valid container format for this program"
        fi
    fi
    
    # check for valid live streaming settings
    if [ "$streaming" = 'true' ] 
    then
        get_supported_streaming_settings
        
        # check if the detected ffmpeg build has support for flv muxer (used for live streaming)
        check_component flv muxer || component_error flv muxer false
        
        # do not allow live streaming without recording audio (YouTube seems to refuse it)
        [ "$recording_audio" = 'false' ] && exit_program 'live streaming cannot be sent without audio'
        
        # do not allow to use fade effect with live streaming (-L/--live-streaming)
        [ "$fade" != 'none' ] && exit_program 'fade effect (-e) cannot be used with live streaming (-L)'
        
        # check for an invalid container format if saving the live stream
        # (supported audio/video encoders in the flv muxer that have restrictions in specific container formats)
        if [ "$saving_output" = 'true' ] 
        then
            if ! printf '%s' "$supported_streaming_formats" | grep -q "^${format}$"
            then
                exit_program "live streaming cannot be saved to the '${format}' container format"
            fi
        fi
        
        # check for an invalid audio encoder for live streaming (flv muxer restrictions)
        if ! printf '%s' "$supported_streaming_audiocodecs" | grep -q "^${audio_encoder}$"
        then
            exit_program "live streaming cannot be made with the '${audio_encoder}' audio encoder"
        fi
        
        # check for an invalid video encoder for live streaming (flv muxer restrictions)
        if ! printf '%s' "$supported_streaming_videocodecs" | grep -q "^${video_encoder}$"
        then
            exit_program "live streaming cannot be made with the '${video_encoder}' video encoder"
        fi
    fi
    
    # checks and settings for formats and audio/video encoders when saving the output video
    if [ "$saving_output" = 'true' ] 
    then
        # execute container formats checks and settings
        "format_settings_${format}"
        
        # check if user entered and invalid combination of audio encoder and container format
        if [ "$format_setted" = 'true' ] || [ "$audio_encoder_setted" = 'true' ] 
        then
            if ! printf '%s' "$supported_audiocodecs" | grep -q "^${audio_encoder}$"
            then
                msg="container format '${format}' does not support '${audio_encoder}' audio encoder"
                
                if [ "$auto_filename" = 'true' ] && [ "$format_setted" = 'false' ] 
                then
                    msg="${msg}
                      (did you forget to select the container format?)"
                fi
                
                show_settings
                exit_program "$msg"
            fi
        fi
        
        # check if user entered and invalid combination of video encoder and container format
        if [ "$format_setted" = 'true' ] || [ "$video_encoder_setted" = 'true' ] 
        then
            if ! printf '%s' "$supported_videocodecs" | grep -q "^${video_encoder}$"
            then
                msg="container format '${format}' does not support '${video_encoder}' video encoder"
                
                if [ "$auto_filename" = 'true' ] && [ "$format_setted" = 'false' ] 
                then
                    msg="${msg}
                      (did you forget to select the container format?)"
                fi
                
                show_settings
                exit_program "$msg"
            fi
            
            # special condition check: mp4 + vp9
            # support is enabled only in ffmpeg 3.4 or greater (or git master N-86119-g5ff31babfc or greater)
            if {
                    [ "$video_encoder" = 'vp9'       ] ||
                    [ "$video_encoder" = 'vp9_vaapi' ] ;
               } &&
               [ "$format" = 'mp4' ] 
            then
                ffmpeg_version="$(ffmpeg -version | grep 'Copyright' | awk '{ printf $3 }')"
                
                if {
                       printf '%s' "$ffmpeg_version" | grep -Eq '^[0-9]+\..*' &&
                       ! {
                             [ "$(printf '%s' "$ffmpeg_version" | awk -F'.' '{ printf $1 }')" -ge '3' ] &&
                             [ "$(printf '%s' "$ffmpeg_version" | awk -F'.' '{ printf $2 }')" -ge '4' ] ;
                         } ;
                   } ||
                   {
                       printf '%s' "$ffmpeg_version" | grep -q '^N-.*' &&
                       ! [ "$(printf '%s' "$ffmpeg_version" | awk -F'-' '{ printf $2 }')" -ge '86119' ] ;
                   }
                then
                    msg="support for 'vp9' encoder in 'mp4' container format in your ffmpeg build is experimental
                      it's needed ffmpeg 3.4 or greater (or git master N-86119-g5ff31babfc or greater)"
                    
                    if [ "$auto_filename" = 'true' ] && [ "$format_setted" = 'false' ] 
                    then
                        msg="${msg}
                      (did you forget to select the container format?)"
                    fi
                    
                    show_settings
                    exit_program "$msg"
                    
                fi # end: if { <complex multi-line ffmpeg version check>
                
            fi # end: [ "$format" = 'mp4' ] &&
            
        fi # end: [ "$format_setted" = 'true' ] || [ "$video_encoder_setted" = 'true' ]
        
    fi # end: [ "$saving_output" = 'true' ]
    
    # audio input checks and adjustments
    if [ "$recording_audio" = 'true' ] 
    then
        # check if the detected ffmpeg build has support for a lossless audio encoder and decoder for recording
        check_lossless_component audiocodec
        
        # check for ALSA support in ffmpeg
        if check_component alsa demuxer
        then
            # check if user entered a valid ALSA input device name
            if [ "$audio_input_setted" = 'true' ] 
            then
                case "$audio_input" in
                    pulse|default)
                        :
                        ;;
                    # do not allow 'null' ALSA input device
                    null)
                        exit_program "the use of 'null' ALSA input device causes problems and is not allowed"
                        ;;
                    *)
                        if command -v arecord >/dev/null 2>&1
                        then
                            if ! check_alsa_long_name && ! check_alsa_short_name
                            then
                                exit_program "'${audio_input}' is not a valid ALSA input device name on this system"
                            fi
                        else
                            print_error "'arecord' was not found"
                            printf '%s%s\n' '                       ' \
                                            "please install 'arecord' (alsa-utils)" >&2
                            exit 1
                        fi
                        ;;
                esac
            fi
            
        # check for PulseAudio support in ffmpeg (fallback mode if ALSA is not available)
        elif check_component pulse demuxer
        then
            # check for PulseAudio support in ffmpeg
            if check_component pulse demuxer
            then
                audio_input_options="$(printf '%s' "$audio_input_options" | sed 's/alsa/pulse/')"
                
                print_warn 'the detected ffmpeg build has no ALSA support, falling back to PulseAudio backend'
            fi
            
            if [ "$audio_input_setted" = 'false' ] 
            then
                print_warn "auto setting audio input device to 'default'"
            else
                # check if user entered a valid PulseAudio input source
                case "$audio_input" in
                    default)
                        :
                        ;;
                    *)
                        if command -v pactl >/dev/null 2>&1
                        then
                            if ! printf '%s' "$(pactl list sources |
                                                 grep '[Nn]ame:'   |
                                                 grep 'input'      |
                                                 sed  's/[[:space:]]*[Nn]ame:[[:space:]]//;s/^<//;s/>$//'
                                               )" | grep -q "^${audio_input}$"
                            then
                                exit_program "'${audio_input}' is not a valid PulseAudio input source on this system"
                            fi
                        else
                            print_error "'pactl' was not found after falling back to PulseAudio backend"
                            printf '%s%s\n' '                       ' \
                                            "please install 'pactl'" >&2
                            exit 1
                        fi
                        ;;
                esac
            fi
        
        # no ALSA ou PulseAudio support available in ffmpeg
        else
            component_error 'ALSA or PulseAudio' backend false
            
        fi # end: else clause of: if check_component alsa demuxer
        
        audio_input="-i ${audio_input}" # add ffmpeg '-i' option for audio input
        
    fi # end: [ "$recording_audio" = 'true' ]
    
    # do not allow to use '-i none' with an '-a' argument different than 'none'
    if [ "$audio_input"    = 'none' ] && [ "$audio_input_setted"   = 'true' ] &&
       [ "$audio_encoder" != 'none' ] && [ "$audio_encoder_setted" = 'true' ] 
    then
        exit_program "'-i none' cannot be used with an '-a' argument different than 'none'"
    fi
    
    # do not allow to use '-a none' with an '-i' argument different than 'none'
    if [ "$audio_encoder"  = 'none' ] && [ "$audio_encoder_setted" = 'true' ] &&
       [ "$audio_input"   != 'none' ] && [ "$audio_input_setted"   = 'true' ] 
       
    then
        exit_program "'-a none' cannot be used with an '-i' argument different than 'none'"
    fi
    
    # execute audio encoder checks and settings (only if recording audio)
    if [ "$recording_audio" = 'true' ] 
    then
        "audiocodec_settings_${audio_encoder}"
    
    # adjust settings if user is not recording audio (video without audio stream)
    else
        unset audio_input
        unset audio_channel_layout
        unset audio_input_options
        audio_record_codec='-an'
        audio_encode_codec='-an'
    fi
    
    # execute video encoder checks and settings
    "videocodec_settings_${video_encoder}"
    
    # do not allow to use -A/--vaapi-device without setting a vaapi video encoder
    case "$video_encoder" in
        *_vaapi)
            :
            ;;
        *)
            [ "$vaapi_device_setted" = 'true' ] && exit_program '--vaapi-device (-A) option can be used only when a VAAPI video encoder is selected'
            unset vaapi_device
            ;;
    esac
    
    # do not allow to use -m option when -i or -a are setted to 'none'
    if [ "$recording_audio" = 'false' ] && [ "$volume_factor_setted" = 'true' ] 
    then
        exit_program "--volume-factor (-m) option cannot be used when '-i' or '-a' are setted to 'none'"
    fi
    
    # check if the entered volume factor is a valid integer/float number (-m)
    if [ "$volume_factor_setted" = 'true' ] 
    then
        if printf '%s' "$volume_factor" | grep -Eq '^[0-9]+(\.[0-9]+)?$'
        then
            # enable volume increase effect if chosen by user
            # (a value different than '1.0' or '0.0')
            if ! {
                     printf '%s' "$volume_factor" | grep -Eq '^[0]+(\.[0]+)?$' ||
                     printf '%s' "$volume_factor" | grep -Eq '^[1]+(\.[0]+)?$' ;
                 }
            then
                volume_increase='true'
            fi
        else
            exit_program "'${volume_factor}' is not a valid number for volume increase effect"
        fi
    fi
    
    # watermark checks and settings
    if [ "$watermark" = 'true' ] 
    then
        # check for a valid watermark size format (NxN) (-z/--wmark-size)
        printf '%s' "$watermark_size" | grep -Eq '^[0-9]+x[0-9]+$' || exit_program "'${watermark_size}' is not a valid watermark size format"
        
        # check for a valid watermark position format ('N,N' or 'PRE') (-k/--wmark-position)
        if printf '%s' "$watermark_position" | grep -Eq '^[0-9]+,[0-9]+$'
        then
            # translate watermark position to what is really used in ffmpeg command
            watermark_position="$(printf '%s' "$watermark_position" | tr ',' ':')"
        else
            # check for a valid watermark special position value
            if check_special_position "$watermark_position"
            then
                # translate watermark position to what is really used in ffmpeg command
                watermark_corner="$watermark_position" # save for comparing watermark and webcam overlay corners
                watermark_position="$special_position"
                unset special_position
                
                # translate a possible alias to the full corner position name (for comparing with webcam overlay corner)
                case "$watermark_corner" in
                    tr)
                        watermark_corner='topright'
                        ;;
                    br)
                        watermark_corner='bottomright'
                        ;;
                    tl)
                        watermark_corner='topleft'
                        ;;
                    bl)
                        watermark_corner='bottomleft'
                        ;;
                esac
            else
                exit_program "'${watermark_position}' is not a valid watermark position format"
            fi
        fi
    
    # do not allow to use -z, -k, -c or -g options without -w option
    else
        msg='option can be used only with --watermark (-w) option'
        [ "$wmark_size_setted"   = 'true' ] && exit_program "--wmark-size (-z) ${msg}"
        [ "$wmark_posi_setted"   = 'true' ] && exit_program "--wmark-position (-k) ${msg}"
        [ "$wmark_font_setted"   = 'true' ] && exit_program "--wmark-font (-c) ${msg}"
        [ "$pngoptimizer_setted" = 'true' ] && exit_program "--png-optimizer (-g) ${msg}"
        unset msg
    fi
    
    # webcam overlay checks and settings
    if [ "$webcam_overlay" = 'true' ] 
    then
        # check for a valid webcam input device
        [ -c "$webcam_input" ] || exit_program "'${webcam_input}' is not a valid webcam input device on this system"
        
        # check for a valid webcam size format (NxN) (-Z/--webcam-size)
        printf '%s' "$webcam_size" | grep -Eq '^[0-9]+x[0-9]+$' || exit_program "'${webcam_size}' is not a valid webcam size format"
        
        # check for a valid webcam position format ('N,N' or 'PRE') (-P/--webcam-position)
        if printf '%s' "$webcam_position" | grep -Eq '^[0-9]+,[0-9]+$'
        then
            # translate webcam position to what is really used in ffmpeg command
            webcam_position="$(printf '%s' "$webcam_position" | tr ',' ':')"
        else
            # check for a valid webcam special position value
            if check_special_position "$webcam_position"
            then
                # translate webcam position to what is really used in ffmpeg command
                webcam_corner="$webcam_position" # save for comparing watermark and webcam overlay corners
                webcam_position="$special_position"
                unset special_position
                
                # translate a possible alias to the full corner position name (for comparing with watermark corner)
                case "$webcam_corner" in
                    tr)
                        webcam_corner='topright'
                        ;;
                    br)
                        webcam_corner='bottomright'
                        ;;
                    tl)
                        webcam_corner='topleft'
                        ;;
                    bl)
                        webcam_corner='bottomleft'
                        ;;
                esac
            else
                exit_program "'${webcam_position}' is not a valid webcam position format"
            fi
        fi
    
    # do not allow to use -Z, -I, or -P options without -W option
    else
        msg='option can be used only with --webcam (-W) option'
        [ "$webcam_size_setted"  = 'true' ] && exit_program "--webcam-size (-Z) ${msg}"
        [ "$webcam_input_setted" = 'true' ] && exit_program "--webcam-input (-I) ${msg}"
        [ "$webcam_posi_setted"  = 'true' ] && exit_program "--webcam-position (-P) ${msg}"
        [ "$webcam_rate_setted"  = 'true' ] && exit_program "--webcam-fps (-R) ${msg}"
        unset msg
    fi
    
    # do not allow watermark and webcam overlay to be placed in the same video corner (only works with predefined special values)
    [ "$watermark" = 'true' ] && [ "$webcam_overlay" = 'true' ] && [ "$watermark_corner" = "$webcam_corner" ] &&
        exit_program "watermark and webcam overlay cannot be placed in the same '$webcam_corner' video corner"
    
    # check if the entered fixed video length is a valid integer/float number (-x)
    if [ "$fixed_length_setted" = 'true' ] 
    then
        if printf '%s' "$fixed_length" | grep -Eq '^[0-9]+(\.[0-9]+)?$'
        then
            # enable fixed video length if chosen by user (a value different than '0')
            printf '%s' "$fixed_length" | grep -Eq '^[0]+(\.[0]+)?$' || ff_fixed_length_options="-t ${fixed_length}"
        else
            exit_program "'${fixed_length}' is not a valid number for fixed video length"
        fi
    fi
}
