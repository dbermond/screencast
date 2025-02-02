#!/bin/sh
# shellcheck disable=SC2086,SC2154,SC2317

# system.sh - system related functions for screencast
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
#                system                 #
#########################################

# description: execute cleanup routines after program termination
# arguments: none
# return value: none
# return code (status): not relevant
cleanup() {
    # delete temporary PNG (waterwark) image
    [ "$watermark" = 'true' ] && rm -f "${tmpdir}/screencast-tmpimage-${rndstr_png}.png"
    
    if [ "$streaming" = 'false' ] && [ "$one_step" = 'false' ] && [ -n "$ff_output" ]
    then
        # rename temporary (lossless) video to a better name if user selected to keep it (--keep/-K)
        # and move it to $savedir
        if [ "$keep_video" = 'true' ]
        then
            if [ "$auto_filename" = 'true' ]
            then
                tmpvideo="${tmpdir}/screencast-lossless-${rndstr_video}.${rec_extension}"
                tmpvideo_newname="${savedir}/screencast-lossless-${current_time}.${rec_extension}"
            else
                tmpvideo="${tmpdir}/screencast-lossless-${rndstr_video}.${rec_extension}"
                tmpvideo_newname="${savedir}/${output_file%.*}-lossless.${rec_extension}"
            fi
            
            if [ -f "$tmpvideo" ]
            then
                filesize="$(du -k "$tmpvideo" | awk '{ print $1 }')"
                
                if [ "$filesize" -eq '0' ]
                then
                    # delete zero-sized tmpvideo file in case some unexpected error occurred
                    rm -f "$tmpvideo"
                else
                    mv -f "$tmpvideo" "$tmpvideo_newname"
                fi
            fi
        # delete temporary (lossless) video if not saving it
        else
            rm -f "${tmpdir}/screencast-lossless-${rndstr_video}.${rec_extension}"
        fi
    fi
    
    # delete zero-sized output file in case some unexpected error occurred
    if [ -f "${savedir}/${output_file}" ]
    then
        filesize="$(du -k "${savedir}/${output_file}" | awk '{ print $1 }')"
        
        [ "$filesize" -eq '0' ] && rm -f "${savedir}/${output_file}"
    fi
}

# description: check if required programs are installed
# arguments: none
# return value: not relevant
# return code (status): not relevant
check_requirements() {
    for requirement in notify-send ffmpeg xdpyinfo slop ffprobe \
                       convert magick "$pngoptimizer" advdef
    do
        # skip disabled components (unnecessary checks)
        if {
               [ "$requirement"   = 'slop'  ] &&
               [ "$select_region" = 'false' ];
           } ||
           {
               [ "$requirement" = 'ffprobe' ] &&
               [ "$fade" = 'none' ];
           } ||
           {
               {
                   [ "$requirement" = 'convert' ] ||
                   [ "$requirement" = 'magick'  ];
               } &&
               [ "$watermark" = 'false' ];
           } ||
           {
               [ "$requirement"  = "$pngoptimizer" ] &&
               [ "$pngoptimizer" = 'none'          ];
           } ||
           {
               [ "$requirement"  = 'advdef' ] &&
               [ "$pngoptimizer" = "none"   ];
           } ||
           {
               [ "$requirement"   = 'notify-send' ] &&
               [ "$notifications" = 'false'       ];
           }
        then
            continue
        fi
        
        case "$requirement" in
            notify-send)
                unset -v request_string
                installname="${requirement} (libnotify) (or use '-n')"
                ;;
            ffmpeg)
                unset -v request_string
                installname='ffmpeg (version git master preferred)'
                ;;
            ffprobe)
                request_string='video fade effect was requested but '
                installname='ffprobe (ffmpeg) (version git master preferred)'
                ;;
            convert|magick)
                request_string='text watermark was requested but '
                installname='ImageMagick (IM7 preferred)'
                ;;
            slop)
                request_string='screen region selection was requested but '
                installname="$requirement"
                ;;
            "$pngoptimizer")
                request_string='png optimization was requested but '
                installname="$requirement"
                ;;
            advdef)
                request_string='png optimization was requested but '
                installname="${requirement} (advancecomp)"
                ;;
            *)
                unset -v request_string
                installname="$requirement"
                ;;
        esac
        
        if ! command -v "$requirement" >/dev/null 2>&1
        then
            if [ "$requirement"  = 'magick' ]
            then
                # in this case IM6 was found because 'convert' goes first
                magick() {
                    convert "$@"
                }
                continue
            else
                msg="${request_string}'${requirement}' was not found"
                print_error "$msg"
                printf '%s%s\n' '                      ' \
                          "please install ${installname}" >&2
                [ "$requirement" != 'notify-send' ] &&
                    notify 'critical' "$expire_time_long" "$error_icon" "$msg"
                exit 1
            fi
        fi
    done
    
    unset -v requirement
    unset -v installname
}

# description:
#   remove two or more consecutive spaces from a string, making them to be a single space
# arguments:
#   $1 - the string to modify
# return value: a modified string
# return code (status): not relevant
remove_spaces() {
    printf '%s' "$1" | sed 's/[[:space:]]\{1,\}/ /g'
}

# description: delete multiple lines from a variable
# arguments:
#   $1 - variable to delete the multiple lines from
#   $2 - the multiple lines to be deleted
# return value: the variable at $1 with the multiple line deleted
# return code (status): not relevant
del_multiline() {
    var="$1"
    
    while read -r line
    do
        var="$(printf '%s' "$var" | sed "/^${line}$/d")"
    done <<- __EOF__
		$(printf '%s' "$2")
__EOF__
    
    printf '%s\n' "$var"
    
    unset -v line
    unset -v var
}

# description: check if specified nvidia gpu device is valid for FFmpeg (-D/--hw-device)
# arguments: none
# return value: not relevant
# return code (status):
#   0 - a valid nvidia gpu device was specified
# note:
#   it will make the program exit with error if an invalid nvidia gpu device was selected
check_nvidia_gpu_device() {
    if ! printf '%s' "$hwdevice" | grep -Eq '^[0-9]+$'
    then
        exit_program "'${hwdevice}' is not a valid NVIDIA GPU number"
    fi
}

# description: check if specified qsv device is valid for FFmpeg (-D/--hw-device)
# arguments: none
# return value: not relevant
# return code (status):
#   0 - a valid qsv device was specified
# note:
#   it will make the program exit with error if an invalid qsv device was selected
check_qsv_device() {
    case "$hwdevice" in
        hw|hw2|hw3|hw4|hw_any|auto|auto_any|sw)
            :
            ;;
        *)
            exit_program "'${hwdevice}' is not a valid QSV device"
            ;;
    esac
}

# description: check if specified DRM render node (vaapi device) exists (-D/--hw-device)
# arguments: none
# return value: not relevant
# return code (status):
#   0 - a valid DRM render node (vaapi device) exists
# note:
#   it will make the program exit with error if an invalid DRM render node
#   (vaapi device) was selected
check_vaapi_device() {
    [ -c "$hwdevice" ] || exit_program "'${hwdevice}' is not a valid DRM render node (VAAPI device) on this system"
}

# description: check if specified vulkan device is valid for FFmpeg (-D/--hw-device)
# arguments: none
# return value: not relevant
# return code (status):
#   0 - a valid vulkan device was specified
# note:
#   it will make the program exit with error if an invalid vulkan device was selected
check_vulkan_device() {
    if ! printf '%s' "$hwdevice" | grep -Eq '^[0-9]+$'
    then
        exit_program "'${hwdevice}' is not a valid Vulkan device number"
    fi
}

# description: check for a valid ALSA input device long name
# arguments: none
# return value: none
# return code (status):
#   0 - a valid ALSA input device long name was entered
#   1 - an invalid ALSA input device long name was entered
# note: it will make the program exit with error user selects the 'null' input device
check_alsa_long_name() {
    arecord="$(arecord -L)"
    
    # check if user has entered allowed variations of long device name
    if ! printf '%s' "$arecord" | grep -q  "^${audio_input}$"  &&
       ! printf '%s' "$arecord" | grep -Eq "^${audio_input}:?" &&
       ! printf '%s' "$arecord" | grep -Eq "^${audio_input%:*}:(CARD=)?${audio_input#*:}"
    then
        return 1
    fi
}

# description: check for a valid ALSA input device short name
# arguments: none
# return value: none
# return code (status):
#   0 - a valid ALSA input device short name was entered
#   1 - an invalid ALSA input device short name was entered
check_alsa_short_name() {
    arecord="$(arecord -l)"
    
    # format: [plug]hw:card
    if printf '%s' "$audio_input" | grep -Eq '^(plug)?+hw:[0-9]+$'
    then
        alsa_card="$(printf '%s' "$audio_input" | sed 's/.*hw://')"
        
        if ! printf '%s' "$arecord" | grep -q "card[[:space:]]${alsa_card}:"
        then
            return 1
        fi
        
    # format: [plug]hw:card,device
    elif printf '%s' "$audio_input" | grep -Eq '^(plug)?+hw:[0-9],[0-9]+$'
    then
        alsa_card="$(  printf '%s' "$audio_input" | sed 's/.*hw://;s/,.*//')"
        alsa_device="$(printf '%s' "$audio_input" | sed 's/.*hw://;s/.*,//')"
        
        if ! printf '%s' "$arecord" | grep "card[[:space:]]${alsa_card}:" | grep -q "device[[:space:]]${alsa_device}:"
        then
            return 1
        fi
        
    # format: [plug]hw:card,device,subdevice
    elif printf '%s' "$audio_input" | grep -Eq '^(plug)?+hw:[0-9],[0-9]+,[0-9]+$'
    then
        alsa_card="$(     printf '%s' "$audio_input" | sed 's/.*hw://;s/,.*//')"
        alsa_device="$(   printf '%s' "$audio_input" | sed 's/.*hw://;s/[0-9]\{1,\},//;s/,.*//')"
        alsa_subdevice="$(printf '%s' "$audio_input" | sed 's/.*hw://;s/[0-9]\{1,\},//;s/.*,//')"
        
        if printf '%s' "$arecord" | grep "card[[:space:]]${alsa_card}:" | grep -q "device[[:space:]]${alsa_device}:"
        then
            # find line number of specified card and device
            card_line="$(printf '%s' "$arecord" | sed -n "/card[[:space:]]${alsa_card}:.*device[[:space:]]${alsa_device}:.*/=")"
            
            # find how many subdevices this card/device have
            # ($card_line + 1 to match Subdevices: 1/1, Subdevices: 2/2, ...)
            subdevices="$(printf '%s' "$arecord" | sed -n "$((card_line + 1))p" | sed 's@.*/@@')"
            
            [ "$subdevices" = '1' ] && subdevices='0' # no need to extend line range if there is only one subdevice
            
            # grep for subdevice number in specific line range after $card_line
            if ! printf '%s' "$arecord" | sed -n "$((card_line + 2)),$((card_line + 2 + subdevices))p" | grep -q "Subdevice[[:space:]]#${alsa_subdevice}:"
            then
                return 1
            fi
        else
            return 1
        fi
    else
        return 1
    fi
}

# description:
#   check for valid output and tmp directories (-o and -t)
#   (will exit with error if any problem is encountered)
# arguments:
#   $1 - the directory to check
# return value: not relevant
# return code (status): not relevant
check_dir() {
    # check if the entered $savedir/$tmpdir already exists
    if [ -e "$1" ]
    then
        # check if the entered $savedir/$tmpdir is a directory
        if [ -d "$1" ]
        then
            # check if the entered $savedir/$tmpdir has write permission
            if [ ! -w "$1" ]
            then
                case "$1" in
                    "$savedir")
                        msg='output'
                        ;;
                    "$tmpdir")
                        msg='temporary files'
                        ;;
                esac
                exit_program "no write permission for ${msg} directory '${1}'"
            fi
        else
            exit_program "'${1}' is not a directory"
        fi
    # create the entered $savedir/$tmpdir if it does not exists
    else
        [ "$1" = "$tmpdir" ] && mode='-m 700'
        
        # shellcheck disable=SC2174
        if ! mkdir -p $mode "$1"
        then
            case "$1" in
                "$savedir")
                    msg='output'
                    ;;
                "$tmpdir")
                    msg='temporary files'
                    ;;
            esac
            exit_program "failed to create ${msg} directory '${1}'"
        fi
    fi
}

# description: generate a random string
# arguments:
#   $1 - desired string length
# return value: a random string
# return code (status): not relevant
randomstr() {
    if [ -c '/dev/urandom' ]
    then
        LC_CTYPE='C' tr -dc '[:alnum:]' < /dev/urandom 2>/dev/null | head -c"$1"
        
    elif command -v shuf >/dev/null 2>&1
    then
        alphanum="a b c d e f g h i j k l m n o p q r s t u v w x y z \
                  A B C D E F G H Y J K L M N O P Q R S T U V W X Y Z \
                  0 1 2 3 4 5 6 7 8 9"
        shuf -ez -n"$1" $alphanum
        unset -v alphanum
        
    elif command -v openssl >/dev/null 2>&1
    then
        openssl rand -hex "$1" | cut -c-"$1"
        
    elif command -v pwgen >/dev/null 2>&1
    then
        pwgen -cns "$1" 1

    else
        print_good 'generating random string with legacy method' >&2
        rnd="$(awk 'BEGIN { srand(); printf "%d\n", (rand() * 10^8) }')"
        
        while [ "$(printf '%s' "$rnd" | wc -m)" -lt "$1" ]
        do
            sleep 1
            rnd="${rnd}$(awk 'BEGIN { srand(); printf "%d\n", (rand() * 10^8) }')"
        done
        
        printf '%s' "$rnd" | cut -c-"$1"
        unset -v rnd
    fi
}
