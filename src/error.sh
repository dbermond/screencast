#!/bin/sh

# error.sh - error messages for screencast
#
# Copyright (c) 2015-2018 Daniel Bermond < yahoo.com: danielbermond >
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

# command_error function: print an error message regarding invalid command
#                         line arguments, show notification and exit with error
# arguments: $1 - command line option name (e.g.: "--fade (-e)")
# return value: not relevant
# return code (status): not relevant
command_error() {
    msg='option requires an argument'
    print_error "${1} ${msg}"
    notify 'critical' '5000' 'dialog-error' "error: ${1} ${msg}"
    exit 1
}

# exit_program: print an error message to stderr, a desktop notification
#               (if it is enabled) and exit with error
# arguments: $1 - error message to print/notificate
# return value: not relevant
# return code (status): not relevant
exit_program() {
    print_error "${1}"
    notify 'critical' '5000' 'dialog-error' "error: ${1}"
    exit 1
}

# component_error function: print an error message and show an error notification
#                           about a not found ffmpeg component and exit the program
# arguments: $1 - the not found ffmpeg component
#            $2 - ffmpeg component type
#                 ([audio/video ]encoder, [audio/video ]decoder, muxer, demuxer)
#            $3 - show suggestion to try a different component (true, false)
# return value: not relevant
# return code (status): not relevant
component_error() {
    print_error "the detected ffmpeg build has no support for '${1}' ${2}"
    printf '%s%s\n'   '                      ' \
                      "please install a ffmpeg build with support for '${1}' ${2}" >&2
                      
    notify 'critical' '5000' 'dialog-error' \
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

# recording_error function: exit the program with the proper message/notifications if a recording error has occurred
# arguments: none
# return value: not relevant
# return code (status): not relevant
recording_error() {
    print_error 'recording error!'
    notify 'critical' '5000' 'dialog-error' 'recording error!'
    exit 1
}

# encoding_error function: exit the program with the proper message/notifications if an encoding error has occurred
# arguments: none
# return value: not relevant
# return code (status): not relevant
encoding_error() {
    print_error 'encoding error!'
    notify 'critical' '5000' 'dialog-error' 'encoding error!'
    exit 1
}
