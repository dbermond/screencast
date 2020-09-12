#!/bin/sh
# shellcheck disable=SC2034,SC2154

# start.sh - screencast program start
#
# Copyright (c) 2015-2020 Daniel Bermond < gmail.com: danielbermond >
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
#            program start              #
#########################################

trap 'cleanup' EXIT HUP INT QUIT ABRT TERM # signal handling

# check for color output support
if command -v tput >/dev/null 2>&1
then
    color_off="$(tput sgr0)"
    color_bold="${color_off}$(tput bold)"
    color_blue="${color_bold}$(tput setaf 4)"
    color_yellow="${color_bold}$(tput setaf 3)"
    color_red="${color_bold}$(tput setaf 1)"
fi

# message header (colored, will fallback to non-colored if no color support)
msg_header="${color_blue}[ ${color_bold}screencast${color_blue} ]"

# enable some options if the executing shell is zsh
if [ -n "$ZSH_VERSION" ]
then
    command -v setopt >/dev/null 2>&1 || exit_program 'script appears to be running in zsh but setopt was not found'
    setopt SH_WORD_SPLIT # enable variable word splitting
fi

get_cmd_line "$@"
shift "$shift_count" # destroy all arguments except a possible output filename

show_header
print_good 'initializing'

# check if a X session is running
[ -z "$DISPLAY" ] && exit_program 'it seems that a X session is not running'

check_pngoptimizer
check_requirements

# prepartions for various checks: get the components supported by the detected ffmpeg build
ffmpeg_formats="$(ffmpeg -formats -v quiet)" # muxers   and demuxers (formats)
ffmpeg_codecs="$( ffmpeg -codecs  -v quiet)" # encoders and decoders

# check if the detected ffmpeg build has support for basic screen recording format
check_component x11grab demuxer || component_error x11grab demuxer false

check_cmd_line "$@"
show_settings
show_warnings

# select with mouse the screen region to record if chosen by user
[ "$select_region" = 'true' ] && get_region && check_screen

# common settings for all recording ways
set_webcam
fix_pass_duration
ff_audio_options="${audio_input_options} ${audio_input}"
ff_video_options="${video_input_options} ${border_options} -framerate ${video_rate} -video_size ${video_size} -i ${display}+${video_position}"

# do a live streaming if chosen by user (-L/--live-streaming)
if [ "$streaming" = 'true' ]
then
    live_streaming

# record offline if live streaming is not chosen by user
else
    if [ "$one_step" = 'true' ]
    then
        record_offline_one_step
    else
        record_offline_two_steps
    fi
fi
