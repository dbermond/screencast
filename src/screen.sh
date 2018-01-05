#!/bin/sh
# shellcheck disable=SC2154,SC2034

# screen.sh - screen related routines for screencast
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
#                screen                 #
#########################################

# dimension_msg function: create an error/warning message to use with
#                         a given inappropriate video dimension
# arguments: $1 - a string denoting the given dimension (width/height)
# return value: a string with the created message
# return code (status): not relevant
dimension_msg() {
    get_videocodecs_for_nonmulti8_msg
    
    if printf '%s' "$msg_speedloss_videocodecs" | grep -q "^${video_encoder}$"
    then
        msg='(this can lead to a speedloss)'
        
    elif printf '%s' "$msg_requirement_videocodecs" | grep -q "^${video_encoder}$"
    then
        msg="(${video_encoder} requirement)"
    fi
    
    case "$1" in
        width)
            printf '%s' "video width '${video_width}' is not a multiple of 8 ${msg}"
            ;;
        height)
            printf '%s' "video height '${video_height}' is not a multiple of 8 ${msg}"
            ;;
        # no need to exit since it's usually called from a subshell
        *)
            printf '%s' "dimension_msg(): invalid \$1 '${1}'"
            ;;
    esac
    
    unset msg
}

# check_dimension function: check if a given dimension is a multiple of 8
# arguments:  $1 - the given dimension (the actual variable value)
# return value: none
# return code (status): 0 - the dimension is a multiple of 8
#                       1 - the dimension is not a multiple of 8
check_dimension() {
    dimension_value="$1"
    
    # the dimension will be a multiple of 8 if the remainder is 0
    [ "$((dimension_value % 8))" = '0' ]
}

# adjust_dimension function: change a given dimension to the immediately higher
#                            number that is a multiple of 8
# arguments: $1 - a string denoting the given dimension (width/height)
# return value = not relevant
# return code (status): not relevant
adjust_dimension() {
    dimension="$1"
    
    # get the dimension value denoted by the string in $dimension
    case "$dimension" in
        width)
            dimension_value="$video_width"
            ;;
        height)
            dimension_value="$video_height"
            ;;
        *)
            exit_program "adjust_dimension(): invalid dimension '${dimension}'"
            ;;
    esac
    
    # obtain the next multiple of 8 number
    remainder="$((dimension_value % 8))"
    to_reach="$((8 - remainder))"
    new_dimension_value="$((dimension_value + to_reach))"
    
    print_warn "$(dimension_msg "$dimension") and was changed to '${new_dimension_value}'"
    
    # change the given dimension to the new value
    case "$dimension" in
        width)
            video_width="$new_dimension_value"
            ;;
        height)
            video_height="$new_dimension_value"
            ;;
    esac
}

# check_screen function: check for valid video size and position in relation to the current screen size
#                        (will exit with error if any problem is encountered)
# arguments: none
# return value: not relevant
# return code (status): not relevant
# note: needs $video_width, $video_position_x, $video_height and $video_position_y
check_screen() {
    screen_size="$(xdpyinfo | grep 'dimensions' | head -n1 | awk '{ print $2 }')"
    screen_width="$( printf '%s' "$screen_size" | awk -F'x' '{ printf $1 }')"
    screen_height="$(printf '%s' "$screen_size" | awk -F'x' '{ printf $2 }')"
    
    if [ "$((video_width + video_position_x))" -gt "$screen_width"  ] 
    then
        exit_program 'recording area is out of screen bounds
                      (video width + position X is greater than the current screen width)'
    fi
    
    if [ "$((video_height + video_position_y))" -gt "$screen_height" ] 
    then
        exit_program 'recording area is out of screen bounds
                      (video height + position Y is greater than the current screen height)'
    fi
}

# get_region function: select with mouse the screen region to record
#                      (will exit with error if region selection is canceled)
# arguments: none
# return value: not relevant
# return code (status): not relevant
# note: sets $video_size and $video_position
get_region() {
    print_good 'please select with mouse a screen region to record...'
    print_info 'single click to select a window, click and drag to select a region'
    print_info 'use arrow keys to fine tune when dragging, right click or any other keystroke to cancel'
    
    screen_region="$(slop -o -f '%x %y %w %h')" || exit_program 'screen region was not selected'
    
    if ! printf '%s' "$screen_region" | grep -Eq '^([0-9]+[[:space:]]){3}[0-9]+$'
    then
        exit_program 'slop returned wrong values'
    fi
    
    video_position_x="$(printf '%s' "$screen_region" | awk '{ printf $1 }')"
    video_position_y="$(printf '%s' "$screen_region" | awk '{ printf $2 }')"
    video_width="$(     printf '%s' "$screen_region" | awk '{ printf $3 }')"
    video_height="$(    printf '%s' "$screen_region" | awk '{ printf $4 }')"
    
    # change video width and height if not a multiple of 8
    check_dimension "$video_width"  || adjust_dimension 'width'
    check_dimension "$video_height" || adjust_dimension 'height'
    
    video_size="${video_width}x${video_height}"
    video_position="${video_position_x},${video_position_y}"
}
