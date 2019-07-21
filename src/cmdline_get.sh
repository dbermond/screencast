#!/bin/sh
# shellcheck disable=SC2034

# cmdline_get.sh - get command line for screencast
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
#           get command line            #
#########################################

# get_cmd_line function: get command line arguments and adjust related variables
# arguments: $1 - the positional parameters passed with double quotes ("$@")
# return value: none
# return code (status): not relevant
# sets special variables: $shift_count - how many shifts were executed
get_cmd_line() {
    shift_count='0' # counts how many 'shift' commands were executed
    
    while :
    do
        # since this is a very long case statement only the first block will
        # be commented. almost all other blocks follows the same sequence/logic
        # and comments will be inserted only for what is different.
        case "$1" in
            # short option and long option without '='
            -s|--size)
                # search for an argument
                if [ -n "$2" ] 
                then
                    # errors out if no argument was entered after the option
                    # (will check for a leading '-' in the next parameter,
                    #  meaning that another option was found)
                    if printf '%.1s\n' "$2" | grep -q '-'
                    then
                        command_error '--size (-s)'
                    else
                        video_size="$2"
                        video_size_setted='true'
                        shift && shift_count="$((shift_count + 1))"
                    fi
                # errors out if no argument is found
                else
                    command_error '--size (-s)'
                fi
                ;;
            # long option with '='
            --size=?*)
                video_size="${1#*=}" # assign value after '='
                video_size_setted='true'
                ;;
            # errors out if a long option with '=' has nothing following '='
            --size=)
                command_error '--size (-s)'
                ;;
            
            -p|--position)
                if [ -n "$2" ] 
                then
                    if printf '%.1s\n' "$2" | grep -q '-'
                    then
                        command_error '--position (-p)'
                    else
                        video_position="$2"
                        video_posi_setted='true'
                        shift && shift_count="$((shift_count + 1))"
                    fi
                else
                    command_error '--position (-p)'
                fi
                ;;
            --position=?*)
                video_position="${1#*=}"
                video_posi_setted='true'
                ;;
            --position=)
                command_error '--position (-p)'
                ;;
            
            -d|--display)
                if [ -n "$2" ] 
                then
                    if printf '%.1s\n' "$2" | grep -q '-'
                    then
                        command_error '--display (-d)'
                    else
                        display="$2"
                        display_setted='true'
                        shift && shift_count="$((shift_count + 1))"
                    fi
                else
                    command_error '--display (-d)'
                fi
                ;;
            --display=?*)
                display="${1#*=}"
                display_setted='true'
                ;;
            --display=)
                command_error '--display (-d)'
                ;;
            
            -b|--border)
                if [ -n "$2" ] 
                then
                    if printf '%.1s\n' "$2" | grep -q '-'
                    then
                        command_error '--border (-b)'
                    else
                        border="$2"
                        border_setted='true'
                        shift && shift_count="$((shift_count + 1))"
                    fi
                else
                    command_error '--border (-b)'
                fi
                ;;
            --border=?*)
                border="${1#*=}"
                border_setted='true'
                ;;
            --border=)
                command_error '--border (-b)'
                ;;
            
            -S|--select-region) # option without argument
                select_region='true'
                ;;
            
            -r|--fps)
                if [ -n "$2" ] 
                then
                    if printf '%.1s\n' "$2" | grep -q '-'
                    then
                        command_error '--fps (-r)'
                    else
                        video_rate="$2"
                        video_rate_setted='true'
                        shift && shift_count="$((shift_count + 1))"
                    fi
                else
                    command_error '--fps (-r)'
                fi
                ;;
            --fps=?*)
                video_rate="${1#*=}"
                video_rate_setted='true'
                ;;
            --fps=)
                command_error '--fps (-r)'
                ;;
            
            -f|--format)
                if [ -n "$2" ] 
                then
                    if printf '%.1s\n' "$2" | grep -q '-'
                    then
                        command_error '--format (-f)'
                    else
                        format="$2"
                        format_setted='true'
                        shift && shift_count="$((shift_count + 1))"
                    fi
                else
                    command_error '--format (-f)'
                fi
                ;;
            --format=?*)
                format="${1#*=}"
                format_setted='true'
                ;;
            --format=)
                command_error '--format (-f)'
                ;;
            
            -i|--audio-input)
                if [ -n "$2" ] 
                then
                    if printf '%.1s\n' "$2" | grep -q '-'
                    then
                        command_error '--audio-input (-i)'
                    else
                        audio_input="${2}"
                        audio_input_setted='true'
                        shift && shift_count="$((shift_count + 1))"
                    fi
                else
                    command_error '--audio-input (-i)'
                fi
                ;;
            --audio-input=?*)
                audio_input="${1#*=}"
                audio_input_setted='true'
                ;;
            --audio-input=)
                command_error '--audio-input (-i)'
                ;;
            
            -a|--audio-encoder)
                if [ -n "$2" ] 
                then
                    if printf '%.1s\n' "$2" | grep -q '-'
                    then
                        command_error '--audio-encoder (-a)'
                    else
                        audio_encoder="$2"
                        audio_encoder_setted='true'
                        shift && shift_count="$((shift_count + 1))"
                    fi
                else
                    command_error '--audio-encoder (-a)'
                fi
                ;;
            --audio-encoder=?*)
                audio_encoder="${1#*=}"
                audio_encoder_setted='true'
                ;;
            --audio-encoder=)
                command_error '--audio-encoder (-a)'
                ;;
            
            -v|--video-encoder)
                if [ -n "$2" ] 
                then
                    if printf '%.1s\n' "$2" | grep -q '-'
                    then
                        command_error '--video-encoder (-v)'
                    else
                        video_encoder="$2"
                        video_encoder_setted='true'
                        shift && shift_count="$((shift_count + 1))"
                    fi
                else
                    command_error '--video-encoder (-v)'
                fi
                ;;
            --video-encoder=?*)
                video_encoder="${1#*=}"
                video_encoder_setted='true'
                ;;
            --video-encoder=)
                command_error '--video-encoder (-v)'
                ;;
            
            -A|--vaapi-device)
                if [ -n "$2" ] 
                then
                    if printf '%.1s\n' "$2" | grep -q '-'
                    then
                        command_error '--vaapi-device (-A)'
                    else
                        vaapi_device="$2"
                        vaapi_device_setted='true'
                        shift && shift_count="$((shift_count + 1))"
                    fi
                else
                    command_error '--vaapi-device (-A)'
                fi
                ;;
            --vaapi-device=?*)
                vaapi_device="${1#*=}"
                vaapi_device_setted='true'
                ;;
            --vaapi-device=)
                command_error '--vaapi-device (-A)'
                ;;
            
            -e|--fade)
                if [ -n "$2" ] 
                then
                    if printf '%.1s\n' "$2" | grep -q '-'
                    then
                        command_error '--fade (-e)'
                    else
                        fade="$2"
                        fade_setted='true'
                        shift && shift_count="$((shift_count + 1))"
                    fi
                else
                    command_error '--fade (-e)'
                fi
                ;;
            --fade=?*)
                fade="${1#*=}"
                fade_setted='true'
                ;;
            --fade=)
                command_error '--fade (-e)'
                ;;
            
            -m|--volume-factor)
                if [ -n "$2" ] 
                then
                    if printf '%.1s\n' "$2" | grep -q '-'
                    then
                        command_error '--volume-factor (-u)'
                    else
                        volume_factor="$2"
                        volume_factor_setted='true'
                        shift && shift_count="$((shift_count + 1))"
                    fi
                else
                    command_error '--volume-factor (-m)'
                fi
                ;;
            --volume-factor=?*)
                volume_factor="${1#*=}"
                volume_factor_setted='true'
                ;;
            --volume-factor=)
                command_error '--volume-factor (-m)'
                ;;
            
            -w|--watermark)
                if [ -n "$2" ] 
                then
                    if printf '%.1s\n' "$2" | grep -q '-'
                    then
                        command_error '--watermark (-w)'
                    else
                        watermark_text="$2"
                        watermark='true'
                        shift && shift_count="$((shift_count + 1))"
                    fi
                else
                    command_error '--watermark (-w)'
                fi
                ;;
            --watermark=?*)
                watermark_text="${1#*=}"
                watermark='true'
                ;;
            --watermark=)
                command_error '--watermark (-w)'
                ;;
            
            -z|--wmark-size)
                if [ -n "$2" ] 
                then
                    if printf '%.1s\n' "$2" | grep -q '-'
                    then
                        command_error '--wmark-size (-z)'
                    else
                        watermark_size="$2"
                        wmark_size_setted='true'
                        shift && shift_count="$((shift_count + 1))"
                    fi
                else
                    command_error '--wmark-size (-z)'
                fi
                ;;
            --wmark-size=?*)
                watermark_size="${1#*=}"
                wmark_size_setted='true'
                ;;
            --wmark-size=)
                command_error '--wmark-size (-z)'
                ;;
            
            -k|--wmark-position)
                if [ -n "$2" ] 
                then
                    if printf '%.1s\n' "$2" | grep -q '-'
                    then
                        command_error '--wmark-position (-k)'
                    else
                        watermark_position="$2"
                        wmark_posi_setted='true'
                        shift && shift_count="$((shift_count + 1))"
                    fi
                else
                    command_error '--wmark-position (-k)'
                fi
                ;;
            --wmark-position=?*)
                watermark_position="${1#*=}"
                wmark_posi_setted='true'
                ;;
            --wmark-position=)
                command_error '--wmark-position (-k)'
                ;;
            
            -c|--wmark-font)
                if [ -n "$2" ] 
                then
                    if printf '%.1s\n' "$2" | grep -q '-'
                    then
                        command_error '--wmark-font (-c)'
                    else
                        watermark_font="$2"
                        wmark_font_setted='true'
                        shift && shift_count="$((shift_count + 1))"
                    fi
                else
                    command_error '--wmark-font (-c)'
                fi
                ;;
            --wmark-font=?*)
                watermark_font="${1#*=}"
                wmark_font_setted='true'
                ;;
            --wmark-font=)
                command_error '--wmark-font (-c)'
                ;;
            
            -W|--webcam) # option without argument
                webcam_overlay='true'
                ;;
            
            -I|--webcam-input)
                if [ -n "$2" ] 
                then
                    if printf '%.1s\n' "$2" | grep -q '-'
                    then
                        command_error '--webcam-input (-I)'
                    else
                        webcam_input="${2}"
                        webcam_input_setted='true'
                        shift && shift_count="$((shift_count + 1))"
                    fi
                else
                    command_error '--webcam-input (-I)'
                fi
                ;;
            --webcam-input=?*)
                webcam_input="${1#*=}"
                webcam_input_setted='true'
                ;;
            --webcam-input=)
                command_error '--webcam-input (-I)'
                ;;
            
            -Z|--webcam-size)
                if [ -n "$2" ] 
                then
                    if printf '%.1s\n' "$2" | grep -q '-'
                    then
                        command_error '--webcam-size (-Z)'
                    else
                        webcam_size="$2"
                        webcam_size_setted='true'
                        shift && shift_count="$((shift_count + 1))"
                    fi
                else
                    command_error '--webcam-size (-Z)'
                fi
                ;;
            --webcam-size=?*)
                webcam_size="${1#*=}"
                webcam_size_setted='true'
                ;;
            --webcam-size=)
                command_error '--webcam-size (-Z)'
                ;;
            
            -P|--webcam-position)
                if [ -n "$2" ] 
                then
                    if printf '%.1s\n' "$2" | grep -q '-'
                    then
                        command_error '--webcam-position (-P)'
                    else
                        webcam_position="$2"
                        webcam_posi_setted='true'
                        shift && shift_count="$((shift_count + 1))"
                    fi
                else
                    command_error '--webcam-position (-P)'
                fi
                ;;
            --webcam-position=?*)
                webcam_position="${1#*=}"
                webcam_posi_setted='true'
                ;;
            --webcam-position=)
                command_error '--webcam-position (-P)'
                ;;
            
            -R|--webcam-fps)
                if [ -n "$2" ] 
                then
                    if printf '%.1s\n' "$2" | grep -q '-'
                    then
                        command_error '--webcam-fps (-R)'
                    else
                        webcam_rate="$2"
                        webcam_rate_setted='true'
                        shift && shift_count="$((shift_count + 1))"
                    fi
                else
                    command_error '--webcam-fps (-R)'
                fi
                ;;
            --webcam-fps=?*)
                webcam_rate="${1#*=}"
                webcam_rate_setted='true'
                ;;
            --webcam-fps=)
                command_error '--webcam-fps (-R)'
                ;;
            
            -L|--live-streaming)
                if [ -n "$2" ] 
                then
                    if printf '%.1s\n' "$2" | grep -q '-'
                    then
                        command_error '--live-streaming (-L)'
                    else
                        streaming_url="$2"
                        streaming='true'
                        shift && shift_count="$((shift_count + 1))"
                    fi
                else
                    command_error '--live-streaming (-L)'
                fi
                ;;
            --live-streaming=?*)
                streaming_url="${1#*=}"
                streaming='true'
                ;;
            --live-streaming=)
                command_error '--live-streaming (-L)'
                ;;
            
            -x|--fixed)
                if [ -n "$2" ] 
                then
                    if printf '%.1s\n' "$2" | grep -q '-'
                    then
                        command_error '--fixed (-x)'
                    else
                        fixed_length="$2"
                        fixed_length_setted='true'
                        shift && shift_count="$((shift_count + 1))"
                    fi
                else
                    command_error '--fixed (-x)'
                fi
                ;;
            --fixed=?*)
                fixed_length="${1#*=}"
                fixed_length_setted='true'
                ;;
            --fixed=)
                command_error '--fixed (-x)'
                ;;
            
            -1|--one-step)  # option without argument
                one_step='true'
                ;;
            
            -n|--no-notifications)  # option without argument
                notifications='false'
                ;;
            
            -g|--png-optimizer)
                if [ -n "$2" ] 
                then
                    if printf '%.1s\n' "$2" | grep -q '-'
                    then
                        command_error '--png-optimizer (-g)'
                    else
                        pngoptimizer="$2"
                        pngoptimizer_setted='true'
                        shift && shift_count="$((shift_count + 1))"
                    fi
                else
                    command_error '--png-optimizer (-g)'
                fi
                ;;
            --png-optimizer=?*)
                pngoptimizer="${1#*=}"
                pngoptimizer_setted='true'
                ;;
            --png-optimizer=)
                command_error '--png-optimizer (-g)'
                ;;
            
            -o|--output-dir)
                if [ -n "$2" ] 
                then
                    if printf '%.1s\n' "$2" | grep -q '-'
                    then
                        command_error '--output-dir (-o)'
                    else
                        savedir="${2%/}" # remove ending '/' if present
                        outputdir_setted='true'
                        shift && shift_count="$((shift_count + 1))"
                    fi
                else
                    command_error '--output-dir (-o)'
                fi
                ;;
            --output-dir=?*)
                savedir="${1#*=}"
                savedir="${savedir%/}" # remove ending '/' if present
                outputdir_setted='true'
                ;;
            --output-dir=)
                command_error '--output-dir (-o)'
                ;;
            
            -t|--tmp-dir)
                if [ -n "$2" ] 
                then
                    if printf '%.1s\n' "$2" | grep -q '-'
                    then
                        command_error '--tmp-dir (-t)'
                    else
                        tmpdir="${2%/}" # remove ending '/' if present
                        tmpdir_setted='true'
                        shift && shift_count="$((shift_count + 1))"
                    fi
                else
                    command_error '--tmp-dir (-t)'
                fi
                ;;
            --tmp-dir=?*)
                tmpdir="${1#*=}"
                tmpdir="${tmpdir%/}" # remove ending '/' if present
                tmpdir_setted='true'
                ;;
            --tmp-dir=)
                command_error '--tmp-dir (-t)'
                ;;
            
            -K|--keep) # option without argument
                keep_video='true'
                ;;
            
            -u|--auto-filename) # option without argument
                auto_filename='true'
                ;;
            
            -l|--list)  # option without argument
                list_setted='true'
                show_list "$@"
                exit 0
                ;;
            
            -h|-\?|--help)  # option without argument
                help_setted='true'
                show_help "$@"
                exit 0
                ;;
            
            -V|--version)  # option without argument
                version_setted='true'
                show_header "$@"
                exit 0
                ;;
            
            --)   # check for the end of options marker '--'
                shift && shift_count="$((shift_count + 1))"
                break
                ;;
            
            -?*=?*) # unknown option with '=', handle argument also with '='
                exit_program "unknown option '${1%%=*}'"
                ;;
            
            -?*=) # unknown option with '='
                exit_program "unknown option '${1%=*}'"
                ;;
            
            -?*)
                exit_program "unknown option '${1}'"
                ;;
            
            *)    # no more options left
                break
        esac
        shift && shift_count="$((shift_count + 1))"
    done
}
