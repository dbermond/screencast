#!/bin/sh
# shellcheck disable=SC2154

# error.sh - error messages for screencast
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
#            error messages             #
#########################################

# description:
#   print an error message regarding invalid command
#   line arguments, show notification and exit with error
# arguments:
#   $1 - command line option name (e.g.: "--fade (-e)")
# return value: not relevant
# return code (status): not relevant
command_error() {
    exit_program "${1} option requires an argument"
}

# description:
#   print an error message to stderr, a desktop notification
#   (if it is enabled) and exit with error
# arguments:
#   $1 - error message to print/notificate
# return value: not relevant
# return code (status): not relevant
exit_program() {
    print_error "$1"
    notify 'critical' "$expire_time_long" "$error_icon" "error: ${1}"
    exit 1
}

# description:
#   print an error message and show an error notification
#   about a not found ffmpeg component and exit the program
# arguments:
#   $1 - the not found ffmpeg component
#   $2 - ffmpeg component type ([audio/video] encoder, [audio/video] decoder, muxer, demuxer)
#   $3 - show suggestion to try a different component (true, false)
# return value: not relevant
# return code (status): not relevant
component_error() {
    print_error "the detected ffmpeg build has no support for '${1}' ${2}"
    printf '%s%s\n'   '                      ' \
                      "please install a ffmpeg build with support for '${1}' ${2}" >&2
                      
    notify 'critical' "$expire_time_long" "$error_icon" \
           "error: the detected ffmpeg build has no support for '${1}' ${2}"
    
    if [ "$3" =  'true' ] && printf '%s' "$2" | grep -q '.*encoder$'
    then
        printf '%s%s\n'   '                      ' \
                          "(or try a different ${2})" >&2
                          
    elif [ "$3" =  'true' ] && printf '%s' "$2" | grep -q 'muxer'
    then
        printf '%s%s\n'   '                      ' \
                          "(or try a different ${2}/format)" >&2
    fi
    
    exit 1
}

# description:
#   exit the program with the proper message/notifications if the detected ffmpeg version is unsupported
# arguments:
#   $1 - error message to print/notificate
# return value: not relevant
# return code (status): not relevant
ffmpeg_version_error() {
    msg="$1"
    
    if [ "$auto_filename" = 'true' ] && [ "$format_setted" = 'false' ]
    then
        msg="${msg}
                      (did you forget to select the container format?)"
    fi
    
    show_settings
    exit_program "$msg"
}
