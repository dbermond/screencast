#!/bin/sh
# shellcheck disable=SC2154

# show.sh - show information for screencast
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
#               show info               #
#########################################

# get_list_format function:
#   format the supported componenets for use with show_list() in -l/--list option
# arguments:
#   $1 - variable with all supported components
# return value: the supported componenets formated for use with show_list() in -l/--list option
# return code (status): not relevant
get_list_format() {
    count='1'
    chars='25'
    (IFS='
'
    for item in $1
    do
        if [ "$count" -eq "$(printf '%s' "$1" | wc -w)" ]
        then
            ending_chars='0'
            unset -v separator
        else
            ending_chars='2'
            separator=', '
        fi
        
        chars="$((chars + "$(printf '%s' "$item" | wc -m)" + ending_chars))"
        
        if [ "$chars" -gt '80' ]
        then
            chars="$((25 + "$(printf '%s' "$item" | wc -m)" + ending_chars))"
            formated_components="$(printf '%s\n%s%s' "$formated_components" \
                '                         ' "${item}${separator}")"
        else
            formated_components="${formated_components}${item}${separator}"
        fi
        
        count="$((count + 1))"
    done
    
    printf '%s' "$formated_components")
    
    unset -v count
    unset -v chars
    unset -v item
    unset -v ending_chars
    unset -v formated_components
}

# show_header function: show program header
# arguments: $1 - the positional parameters passed with double quotes ("$@")
# return value: the program header
# return code (status): not relevant
show_header() {
    # give error if --version/-V is not the unique command line option
    if [ "$version_setted" = 'true' ]
    then
        if [ "$shift_count" -ne '0' ] || [ "$#" -ne '1' ]
        then
            exit_program '--version (-V) option can be used only alone'
        fi
    fi
    
    cat <<- __EOF__
	screencast ${screencast_version} - Copyright (c) 2015-$(date +%Y) Daniel Bermond
	Command line interface to record a X11 desktop
	${screencast_website}
__EOF__
}

# help function
# arguments: $1 - the positional parameters passed with double quotes ("$@")
# return value: the program help screen
# return code (status): not relevant
show_help() {
    # give error if --help/-h/-? is not the unique command line option
    if [ "$help_setted" = 'true' ]
    then
        if [ "$shift_count" -ne '0' ] || [ "$#" -ne '1' ]
        then
            exit_program '--help (-h) option can be used only alone'
        fi
    fi
    
    show_header "$@"
    
    cat <<- __EOF__
	
	Usage: screencast [options] <output>
	                  [options] -u
	                  [options] -L <URL>
	Options:
	  -s, --size=NxN            video size (resolution) [${video_size}]
	  -p, --position=N,N        recording position (screen XY topleft offsets) [${video_position}]
	  -d, --display=:N[.N]      X server display (and screen) number(s) [${display}]
	  -b, --border              tickness of the screen region border (0 disable) [${border}]
	  -S, --select-region       select with mouse the screen region to record
	  -r, --fps=N               video framerate (fps) [${video_rate}]
	  -f, --format=TYPE         container format (to use with -u) [${format}]
	  -i, --audio-input=NAME    audio input device [${audio_input}]
	  -a, --audio-encoder=NAME  audio encoder [${audio_encoder}]
	  -v, --video-encoder=NAME  video encoder [${video_encoder}]
	  -A, --vaapi-device=NODE   DRM render node [${vaapi_device}]
	  -e, --fade=TYPE           video fade effect [${fade}]
	  -m, --volume-factor=N     volume increase effect factor (1.0 disable) [${volume_factor}]
	  -w, --watermark=TEXT      enable and set text watermark effect [disabled]
	  -z, --wmark-size=NxN      watermark image size (resolution) [${watermark_size}]
	  -k, --wmark-position=N,N  watermark position (video XY topleft offsets,
	      --wmark-position=PRE    or a predefined special value) [${watermark_position}]
	  -c, --wmark-font=NAME     watermark font [${watermark_font}]
	  -W, --webcam              enable webcam overlay effect [disabled]
	  -I, --webcam-input=DEV    webcam input device [${webcam_input}]
	  -Z, --webcam-size=NxN     webcam video size (resolution) [${webcam_size}]
	  -P, --webcam-position=N,N webcam position (video XY topleft offsets,
	      --webcam-position=PRE   or a predefined special value) [${webcam_position}]
	  -R, --webcam-fps=N        webcam framerate (fps) [device default]
	  -L, --live-streaming=URL  enable live streaming, setting url to URL [disabled]
	  -1, --one-step            one step (record and encode at same time) [disabled]
	  -x, --fixed=N             fixed video length for N seconds (0 disable) [${fixed_length}]
	  -n, --no-notifications    disable desktop and sound notifications
	  -g, --png-optimizer=NAME  use png (watermark) optimizer and advdef [${pngoptimizer}]
	  -o, --output-dir=DIR      save videos to DIR (to use with -u) [local dir]
	  -t, --tmp-dir=DIR         use DIR for temporary files [${tmpdir}]
	  -K, --keep                keep the temporary video or the live streaming
	  -u, --auto-filename       auto choose output filename based on date/time
	  -l, --list                list arguments supported by these options
	  -h, --help                this help screen
	  -V, --version             version information
	
	For further help run 'man screencast'
__EOF__
}

# show_list function: print a list of arguments supported by this program
# arguments: $1 - the positional parameters passed with double quotes ("$@")
# return value: the described list
# return code (status): not relevant
show_list() {
    # give error if --list/-l is not the unique command line option
    if [ "$list_setted" = 'true' ]
    then
        if [ "$shift_count" -ne '0' ] || [ "$#" -ne '1' ]
        then
            exit_program '--list (-l) option can be used only alone'
        fi
    fi
    
    show_header "$@"
    get_supported_fade
    get_supported_pngoptmz
    
    list_wmark_position='topleft, topright, bottomleft, bottomright
                         (or the respective aliases tl, tr, bl, br)'
                         
    list_webcam_position="$list_wmark_position"
    
    cat <<- __EOF__
	
	Supported arguments:
	  -f, --format           $(get_list_format "$supported_formats_all")
	
	  -a, --audio-encoder    $(get_list_format "$supported_audiocodecs_all")
	
	  -v, --video-encoder    $(get_list_format "$supported_videocodecs_all")
	
	  -e, --fade             $(get_list_format "$supported_fade")
	
	  -k, --wmark-position   $(printf '%s' "$list_wmark_position")
	
	  -P, --webcam-position  $(printf '%s' "$list_webcam_position")
	
	  -g, --png-optimizer    $(get_list_format "$supported_pngoptmz")
	
	  note: selecting vorbis or opus audio encoders actually uses the higher
	        quality libvorbis and libopus encoders respectively.
	
	  note: the container formats mkv and nut support a combination of all audio
	        and video encoders. Restrictions apply to other container formats.
__EOF__
}

# show_settings function: show information about some program settings
# arguments: none
# return value: program settings information
# return code (status): not relevant
show_settings() {
    [ "$video_encoder" = "$video_encoder_default" ] && [ "$video_encoder_setted" = 'false' ] && video_outstr='(default)'
    [ "$audio_encoder" = "$audio_encoder_default" ] && [ "$audio_encoder_setted" = 'false' ] && audio_outstr='(default)'
    [ "$format"        = "$format_default"        ] && [ "$format_setted"        = 'false' ] &&
        [ "$auto_filename" = 'true'  ] && format_outstr='(default)'
    
    if printf '%s' "$videocodecs_vaapi" | grep -q "^${video_encoder}$"
    then
        video_outstr="(${vaapi_device})"
    fi
    
    [ "$fade" != 'none' ] && effects="fade-${fade}"
    
    if [ "$watermark" = 'true' ]
    then
        effects="${effects:+"${effects}, watermark"}"
        effects="${effects:-watermark}"
    fi
    
    if [ "$webcam_overlay" = 'true' ]
    then
        effects="${effects:+"${effects}, webcam overlay"}"
        effects="${effects:-webcam overlay}"
    fi
    
    if [ "$volume_increase" = 'true' ]
    then
        effects="${effects:+"${effects}, volume (${volume_factor})"}"
        effects="${effects:-"volume (${volume_factor})"}"
    fi
    
    effects="${effects:-none}"
    
    print_good "${color_bold:-}video encoder   :${color_off:-} ${video_encoder} ${video_outstr:-}"
    print_good "${color_bold:-}audio encoder   :${color_off:-} ${audio_encoder} ${audio_outstr:-}"
    
    [ "$saving_output" = 'true' ] && print_good "${color_bold:-}container format:${color_off:-} ${format} ${format_outstr:-}"
    
    print_good "${color_bold:-}effects         :${color_off:-} ${effects}"
}

# show_warnings function: show warnings that should appear right after show_settings()
# arguments: none
# return value: program early warnings
# return code (status): not relevant
show_warnings() {
    # warn: user chosen a possible unplayable combinantion of audio/video encoder and container format
    if printf '%s' "$possible_unplayable_formats" | grep -q "^${format}$"
    then
        msg="on '${format}' container format may not be playable in some players"
        
        if printf '%s' "$possible_unplayable_audiocodecs" | grep -q "^${audio_encoder}$"
        then
            print_warn "'${audio_encoder}' audio encoder ${msg}"
        fi
        
        if printf '%s' "$possible_unplayable_videocodecs" | grep -q "^${video_encoder}$"
        then
            print_warn "'${video_encoder}' video encoder ${msg}"
        fi
        
        unset -v msg
    fi
    
    if [ "$auto_filename" = 'false' ]
    then
        # warn: output file already exists
        [ -f "${savedir}/${output_file}" ] &&
            print_warn "output file '${output_file}' already exists, overwriting without prompt"
            
        # warn: lossless output file already exists
        lossless_video="${output_file%.*}-lossless.${rec_extension}"
        
        [ "$streaming"  = 'false' ] && [ "$one_step" = 'false'  ] &&
        [ "$keep_video" = 'true'  ] && [ -f "${tmpdir}/${lossless_video}" ] &&
            print_warn "lossless output file '${lossless_video}' already exists, overwriting without prompt"
            
        unset -v lossless_video
    fi
    
    if [ "$streaming" = 'true' ]
    then
        # warn: a possible output file already exists (if user specifies a local file in -L/--live-streaming option)
        [ -f "$streaming_url" ] && print_warn "output file '${streaming_url}' already exists, overwriting without prompt"
        
        # warn: using a software-based video encoder in live streaming
        if printf '%s' "$supported_videocodecs_software" | grep -q "^${video_encoder}$"
        then
            print_warn 'using a software-based video encoder in live streaming is not recommended
                        (can cause buffer problems that may lead to packet loss)'
        fi
    else
        # warn: using a software-based video encoders in a one step process
        if [ "$one_step" = 'true' ]
        then
            if printf '%s' "$supported_videocodecs_software" | grep -q "^${video_encoder}$"
            then
                print_warn 'using a software-based video encoder in a one step process is not recommended
                        (can cause buffer problems that may lead to packet loss)'
            fi
        fi
    fi
}
