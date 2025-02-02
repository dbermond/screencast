#!/bin/sh
# shellcheck disable=SC2154

# message.sh - messages for for screencast
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
# along with this program.  If not, see <https://www.gnu.org/licenses/>.

#########################################
#               messages                #
#########################################

# print functions
# description: print formated messages
# arguments:
#   $1 - message to print
# return value: the message to print
# return code (status): not relevant
print_good() {
    printf '%s\n' "${msg_header}${color_off} ${1}"
}

print_info() {
    printf '%s\n' "${msg_header}${color_bold} info:${color_off} ${1}"
}

print_warn() {
    printf '%s\n' "${msg_header}${color_yellow} warning:${color_off} ${1}"
}

print_error() {
    printf '%s\n' "${msg_header}${color_red} error:${color_off} ${1}" >&2
}

# description: show a desktop notification if setted to do so
# arguments:
#   $1 - urgency level (low, normal, critial)
#   $2 - duration in milliseconds
#   $3 - icon name
#   $4 - text message
# return value: none
# return code (status): not relevant
notify() {
    if [ "$notifications" = 'true' ]
    then
        notify-send --urgency="$1" --expire-time="$2" --icon="$3" \
            screencast "$(remove_spaces "$4")"
    fi
}

# description: print message and show notification when finished
# arguments: none
# return value: the printed message
# return code (status): not relevant
finish() {
    print_good 'finish'
    
    if [ -f "$finish_icon_oxygen" ]
    then
        finish_icon="$finish_icon_oxygen"
    else
        finish_icon="$finish_icon_generic"
    fi
    
    notify 'normal' "$expire_time_normal" "$finish_icon" 'finish'
    
    # play a sound after finish if requirements are present
    if [ "$notifications" = 'true' ] && [ -f "$finish_sound" ] && command -v ffplay >/dev/null 2>&1
    then
        ffplay -v quiet -nodisp -autoexit -volume "$ffplay_volume" "$finish_sound" >/dev/null 2>&1 &
    fi
    
    unset -v finish_icon
}
