#!/bin/sh
# shellcheck disable=SC2034,SC2154

# cmdline_check.sh - check command line for screencast
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
#          command line checks          #
#########################################

# description:
#   check validity of command line options and arguments (also set some variables)
#   (will exit with error if any inconsistency is found)
# arguments:
#   the remainder positional parameters passed with double quotes ("$@")
# return value: none
# return code (status): not relevant
check_cmd_line() {
    if [ "$display_setted" = 'true' ]
    then
        if ! printf '%s' "$display" | grep -Eq '^:[0-9]+(\.[0-9]+)?$'
        then
            exit_program "'${display}' is not a valid display value"
        fi
    fi
    
    if [ "$select_region" = 'true' ]
    then
        # do not allow to use -S/--select-region with -s/--size or -p/--position
        [ "$video_size_setted" = 'true' ] && exit_program '--select-region (-S) option cannot be used with --size (-s) option'
        [ "$video_posi_setted" = 'true' ] && exit_program '--select-region (-S) option cannot be used with --position (-p) option'
    else
        # preparations for check_dimension() and check_screen()
        video_position_x="$(printf '%s' "$video_position" | awk -F',' '{ print $1 }')"
        video_position_y="$(printf '%s' "$video_position" | awk -F',' '{ print $2 }')"
        video_width="$(     printf '%s' "$video_size"     | awk -F'x' '{ print $1 }')"
        video_height="$(    printf '%s' "$video_size"     | awk -F'x' '{ print $2 }')"
        
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
    
    if [ "$border_setted" = 'true' ]
    then
        if printf '%s' "$border" | grep -Eq '^[0-9]+$'
        then
            # set video border if chosen by user (a value different than '0')
            if [ "$border" -gt '0' ]
            then
                if [ "$border" -le '128' ]
                then
                    border_options="-show_region 1 -region_border ${border}"
                else
                    exit_program "video border '${border}' is out of range (allowed values: 0 - 128)"
                fi
            else
                border_options='-show_region 0'
            fi
        else
            exit_program "'${border}' is not a valid number for video border delimiter (allowed values: 0 - 128)"
        fi
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
    if [ "$audio_input" = 'none' ]
    then
        if [ "$audio_encoder_setted" = 'true' ]
        then
            exit_program "the audio encoder cannot be setted with '-a' option when using '-i none'"
        fi
        
        recording_audio='false'
    fi
    
    # check if user is doing a one step process without encoding the lossless video
    if [ "$video_encoder" = 'none' ] &&
       {
           [ "$audio_encoder"   = 'none'  ] ||
           [ "$recording_audio" = 'false' ];
       }
    then
        video_outstr='(lossless video)'
        [ "$recording_audio" = 'true' ] && audio_outstr='(lossless audio)'
        
        one_step_lossless='true'
        [ "$one_step" != 'true' ] && one_step='true' # implies one step process
    fi
    
    # check if user is saving an output video (if not, modify the corresponding control variable)
    [ "$streaming" = 'true' ] && [ "$keep_video" = 'false' ] && saving_output='false'
    
    # do not allow to use -K/--keep with -1/--one-step
    [ "$one_step" = 'true' ] && [ "$keep_video" = 'true' ] &&
        exit_program "'-K' is set but there is no temporary video to keep when using --one-step"
    
    # check if user entered a valid fade effect (-e/--fade)
    if [ "$fade_setted" = 'true' ]
    then
        get_supported_fade
        
        if printf '%s' "$supported_fade" | grep -q "^${fade}$"
        then
            # do not allow to use fade effect when using a one step process (-1/--one-step)
            [ "$one_step" = 'true' ] && [ "$fade" != 'none' ] && exit_program 'fade effect (-e) cannot be used with --one-step'
        else
            exit_program "'${fade}' is not a valid fade effect for this program"
        fi
    fi
    
    # checks and settings based on usage of the '-u' option
    if [ "$auto_filename" = 'true' ]
    then
        # do not allow to use '-u' when not saving the live streaming
        [ "$saving_output" = 'false' ] && exit_program "'-u' is set but not saving the live streaming ('-K' not set)"
        
        # if '-u' is set, don't allow to set an output filename in command line
        [ "$#" -gt '0' ] && exit_program '--auto-filename (-u) does not allow to set an output filename'
        
        # show full path when using dot folder hardlinks in -o/--output-dir
        if [ "$outputdir_setted" = 'true' ]
        then
            # output dir in format '../myvideo.mp4' or '../path/to/myvideo.mp4' (parent dir as double dot folder hardlink)
            if printf '%s' "$savedir" | grep -Eq '^\.\.[/]?.*'
            then
                savedir="$(printf '%s' "$savedir" | sed "s|^\\.\\.|$(dirname "$(pwd)")|")"
                savedir="${savedir%/}" # remove ending '/' if present
                
            # output dir in format './myvideo.mp4' or './path/to/myvideo.mp4' (current dir as single dot folder hardlink)
            elif printf '%s' "$savedir" | grep -Eq '^\.[/]?.*'
            then
                savedir="$(printf '%s' "$savedir" | sed "s|^\\.|$(pwd)|")"
                savedir="${savedir%/}" # remove ending '/' if present
            fi
        fi
        
        current_time="$(date +%Y-%m-%d_%H.%M.%S)" # get current time for placing on filename
        
        # set the output filename
        if [ "$streaming" = 'true' ]
        then
            output_file="screencast-livestreaming-${current_time}.${format}"
        else
            if [ "$one_step_lossless" = 'true' ] && [ "$format_setted" = 'false' ]
            then
                format='mkv'
                format_outstr='(auto chosen)'
            fi
            
            output_file="screencast-${current_time}.${format}"
        fi
    else
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
                   [ "$keep_video" = 'false' ];
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
                   [ "$keep_video" = 'false' ];
               } ;
           }
        then
            exit_program "--output-dir (-o) option can be used only with --auto-filename (-u)
                      (when not using '-u', set output directory with the output filename)"
        fi
        
        # output dir in format '../myvideo.mp4' or '../path/to/myvideo.mp4' (parent dir as double dot folder hardlink)
        if printf '%s' "$1" | grep -q '^\.\./.*'
        then
            savedir="$(printf '%s' "$(dirname "$1")" | sed "s|^\\.\\.|$(dirname "$(pwd)")|")"
            
        # output dir in format './myvideo.mp4' or './path/to/myvideo.mp4' (current dir as single dot folder hardlink)
        elif printf '%s' "$1" | grep -q '^\./.*'
        then
            savedir="$(printf '%s' "$(dirname "$1")" | sed "s|^\\.|$(pwd)|")"
            
        # any other output dir format, no need of special handling
        else
            savedir="$(dirname "$1")"
        fi
        
        # set the output filename and get the container format (only if saving the output video)
        if [ "$saving_output" = 'true' ]
        then
            output_file="$(basename "$1")" # set the output filename
            format="${output_file##*.}"    # set container format (output filename extension)
        fi
        
    fi # end: else clause of: if [ "$auto_filename" = 'true' ]
    
    # show full path when using dot folder hardlinks in -t/--tmp-dir
    if [ "$tmpdir_setted" = 'true' ]
    then
        # tmpdir in format '../' or '../path/to/' (parent dir as double dot folder hardlink)
        if printf '%s' "$tmpdir" | grep -Eq '^\.\.[/]?.*'
        then
            tmpdir="$(printf '%s' "$tmpdir" | sed "s|^\\.\\.|$(dirname "$(pwd)")|")"
            tmpdir="${tmpdir%/}" # remove ending '/' if present
            
        # tmpdir in format './' or './path/to/' (current dir as single dot folder hardlink)
        elif printf '%s' "$tmpdir" | grep -Eq '^\.[/]?.*'
        then
            tmpdir="$(printf '%s' "$tmpdir" | sed "s|^\\.|$(pwd)|")"
            tmpdir="${tmpdir%/}" # remove ending '/' if present
        fi
    fi
    
    # check if user entered a valid container format
    if [ "$format_setted" = 'true' ] ||
       {
           [ "$auto_filename" = 'false' ] &&
           [ "$saving_output" = 'true'  ];
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
    
    # do not allow to use '-a none' with an '-v' argument different than 'none'
    if [ "$audio_encoder" = 'none' ] && [ "$video_encoder" != 'none' ]
    then
        msg="'-a none' cannot be used with an '-v' argument different than 'none'"
        
        if [ "$video_encoder_setted" = 'false' ]
        then
            msg="${msg}
                      (did you forget to select the video encoder?)"
        fi
        
        exit_program "$msg"
    fi
    
    # do not allow to use '-v none' with an '-a' argument different than 'none'
    if [ "$video_encoder" = 'none' ] && [ "$audio_encoder" != 'none' ] && [ "$recording_audio" = 'true' ]
    then
        msg="'-v none' cannot be used with an '-a' argument different than 'none'"
        
        if [ "$audio_encoder_setted" = 'false' ]
        then
            msg="${msg}
                      (did you forget to select the audio encoder?)"
        fi
        
        exit_program "$msg"
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
            
            # special condition check
            # opus + mp4: requires ffmpeg 4.3 or greater (or git master N-97089-gca7a192d10 or greater)
            if printf '%s' "$audiocodecs_opus" | grep -q "^${audio_encoder}$" && [ "$format" = 'mp4' ]
            then
                if ! check_minimum_ffmpeg_version '4.3' '97089'
                then
                    msg="'opus' audio encoder in 'mp4' container format is not allowed with your ffmpeg
                      it's needed ffmpeg 4.3 or greater (or git master N-97089-gca7a192d10 or greater)"
                    
                    ffmpeg_version_error "$msg"
                fi
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
            
            # special condition checks
            # vp9 + mp4: requires ffmpeg 3.4 or greater (or git master N-86119-g5ff31babfc or greater)
            if printf '%s' "$videocodecs_vp9" | grep -q "^${video_encoder}$" && [ "$format" = 'mp4' ]
            then
                if ! check_minimum_ffmpeg_version '3.4' '86119'
                then
                    msg="support for 'vp9' video encoder in 'mp4' container format in your ffmpeg build is experimental
                      it's needed ffmpeg 3.4 or greater (or git master N-86119-g5ff31babfc or greater)"
                    
                    ffmpeg_version_error "$msg"
                fi
            
            # av1 + webm: requires ffmpeg 4.1 or greater (or git master N-91995-gcbe5c7ef38 or greater)
            elif printf '%s' "$videocodecs_av1" | grep -q "^${video_encoder}$" && [ "$format" = 'webm' ]
            then
                if ! check_minimum_ffmpeg_version '4.1' '91995'
                then
                    msg="your ffmpeg build does not support 'av1' video encoder in 'webm' container format
                      it's needed ffmpeg 4.1 or greater (or git master N-91995-gcbe5c7ef38 or greater)"
                    
                    ffmpeg_version_error "$msg"
                fi
            fi
            
        fi # end: [ "$format_setted" = 'true' ] || [ "$video_encoder_setted" = 'true' ]
        
    fi # end: [ "$saving_output" = 'true' ]
    
    # check for the lossless ffmpeg components when needed
    if [ "$streaming" = 'false' ] &&
       {
           [ "$one_step" = 'false' ] ||
           [ "$one_step_lossless" = 'true' ];
       }
    then
        check_lossless_component format
        check_lossless_component videocodec
    fi
    
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
                            exit_program "'arecord' was not found
                      please install 'arecord' (alsa-utils)"
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
            
            if [ "$audio_input_setted" = 'true' ]
            then
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
                            exit_program "'pactl' was not found after falling back to PulseAudio backend
                      please install 'pactl'"
                        fi
                        ;;
                esac
            else
                print_warn "auto setting audio input device to 'default'"
            fi
        
        # no ALSA ou PulseAudio support available in ffmpeg
        else
            component_error 'ALSA or PulseAudio' backend false
            
        fi # end: else clause of: if check_component alsa demuxer
        
        # check for valid audio input channels
        if [ "$audio_channels_setted" = 'true' ] &&
           { ! printf '%s' "$audio_input_channels" | grep -Eq '^[0-9]+$' || [ ! "$audio_input_channels" -gt '0' ]; }
        then
            exit_program "'${audio_input_channels}' is not a valid number of audio input channels"
        fi
        
        # set audio channel layout of audio input if needed
        if [ "$audio_input_channels" -eq '2' ]
        then
            audio_channel_layout='-channel_layout stereo'
        elif [ "$audio_input_channels" -gt '2' ]
        then
            unset -v audio_channel_layout
            audio_output_channels="$audio_input_channels"
        fi
        
        audio_input="-i ${audio_input}" # add ffmpeg '-i' option to audio input
        audio_input_channels="-channels ${audio_input_channels}" # add ffmpeg '-channels' option to audio input channels
        
        # audio encoder checks and settings
        [ "$audio_encoder" != 'none' ] && "audiocodec_settings_${audio_encoder}"
    else
        # adjust settings if user is not recording audio (video without audio stream)
        unset -v audio_input
        unset -v audio_input_channels
        unset -v audio_output_channels
        unset -v audio_channel_layout
        unset -v audio_input_options
        unset -v audio_encoder
        audio_record_codec='-an'
        audio_encode_codec='-an'
    fi # end: [ "$recording_audio" = 'true' ]
    
    # do not allow to use slow video encoders in a one step process (-1/--one-step)
    # (aom_av1 is still experimental and very slow in ffmpeg)
    if printf '%s' "$videocodecs_av1_slow" | grep -q "^${video_encoder}$"
    then
        exit_program "'${video_encoder}' cannot be used for a one step process (very slow in FFmpeg)"
    fi
    
    # settings for hardware encoders (-v/--video-encoder)
    if printf '%s' "$supported_videocodecs_hardware" | grep -q "^${video_encoder}$"
    then
        hwencoder='true'
        
        # set hwaccel
        case "$video_encoder" in
            *_nvenc)
                hwaccel='cuda'
                ;;
            *)
                hwaccel="$(printf '%s' "$video_encoder" | sed 's/.*_//')"
                ;;
        esac
        
        # set the hw device if user did not selected one with the -D/--hw-device option
        if [ "$hwdevice_setted" = 'false' ]
        then
            case "$hwaccel" in
                cuda)
                    hwdevice="$nvenc_default_hwdevice"
                    ;;
                qsv)
                    hwdevice="$qsv_default_hwdevice"
                    ;;
                vaapi)
                    hwdevice="$vaapi_default_hwdevice"
                    ;;
                *)
                    exit_program "invalid hwaccel '${hwaccel}' (this should not happen)"
                    ;;
            esac
        fi
    else
        # do not allow to use -D/--hw-device without setting a hardware video encoder
        if [ "$hwdevice_setted" = 'true' ]
        then
            exit_program '--hw-device (-D) option can be used only when a hardware video encoder is selected'
        fi
    fi
    
    # execute video encoder checks and settings
    [ "$video_encoder" != 'none' ] && "videocodec_settings_${video_encoder}"
    
    # do not allow to use -m option when -i is setted to 'none'
    if [ "$recording_audio" = 'false' ] && [ "$volume_factor_setted" = 'true' ]
    then
        exit_program "--volume-factor (-m) option cannot be used when '-i' is setted to 'none'"
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
                unset -v special_position
                
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
        [ "$wmark_font_setted"   = 'true' ] && exit_program "--wmark-font (-F) ${msg}"
        [ "$pngoptimizer_setted" = 'true' ] && exit_program "--png-optimizer (-g) ${msg}"
        unset -v msg
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
                unset -v special_position
                
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
        unset -v msg
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
