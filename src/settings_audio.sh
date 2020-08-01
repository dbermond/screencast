#!/bin/sh
# shellcheck disable=SC2034,SC2154

# settings_audio.sh - audio encoder settings for screencast
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
#         audio encoder settings        #
#########################################

# supported audio encoders (one per line for accurate grepping and easy deletion)
supported_audiocodecs_all="$(     printf 'aac\nopus\nvorbis\nmp3lame\nshine\nwma\nnone')"
supported_audiocodecs_lossless="$(printf 'pcm_s16le\nflac')"

# lossless audio encoder settings functions: make checks and settings for lossless audio encoder
#                                           (for the 1st step, lossless recording)
# arguments: none
# return value: not relevant
# return code (status): 0 - the detected ffmpeg build has support for the tested lossless audio_encoder
#                       1 - the detected ffmpeg build has no support for the tested lossless audio encoder
# sets special variable: $audio_record_codec - ffmpeg lossless audio codec option and settings
# note: the program will exit with error if the selected lossless audio encoder is not supported by the detected ffmpeg build
lossless_audiocodec_settings_pcm_s16le() {
    if check_component pcm_s16le encoder &&
       check_component pcm_s16le decoder
    then
        audio_record_codec='-codec:a pcm_s16le -ar 48000 -ac 2'
    else
        return 1
    fi
}

lossless_audiocodec_settings_flac() {
    if check_component flac encoder &&
       check_component flac decoder
    then
        audio_record_codec='-codec:a flac -b:a 320k -ar 48000 -ac 2'
    else
        return 1
    fi
}

# audio encoder settings functions: make checks and settings for the selected audio encoder
# arguments: none
# return value: none
# return code (status): not relevant
# sets special variable: $audio_encode_codec - ffmpeg audio codec option and settings
# note: the program will exit with error if the selected audio encoder is not supported by the detected ffmpeg build
audiocodec_settings_aac() {
    if check_component libfdk_aac encoder
    then
        if [ "$streaming" = 'true' ] 
        then
            audio_encode_codec='-codec:a libfdk_aac -b:a  96k -ar 44100 -ac 2'
        else
            audio_encode_codec='-codec:a libfdk_aac -b:a 128k -ar 44100 -ac 2'
        fi
    else
        check_component aac encoder || component_error 'libfdk_aac or aac' 'audio encoder' true
        
        if [ "$streaming" = 'true' ] 
        then
            audio_encode_codec='-codec:a aac -b:a  96k -ar 44100 -ac 2'
        else
            audio_encode_codec='-codec:a aac -b:a 128k -ar 44100 -ac 2'
        fi
    fi
}

audiocodec_settings_vorbis() {
    check_component libvorbis encoder || component_error libvorbis 'audio encoder' true
    audio_encode_codec='-codec:a libvorbis -qscale:a 4 -ar 44100 -ac 2'
}

audiocodec_settings_opus() {
    check_component libopus encoder || component_error libopus 'audio encoder' true
    audio_encode_codec='-codec:a libopus -b:a 128k -ar 48000 -ac 2'
}

audiocodec_settings_mp3lame() {
    check_component libmp3lame encoder || component_error libmp3lame 'audio encoder' true
    
    if [ "$streaming" = 'true' ] 
    then
        audio_encode_codec='-codec:a libmp3lame -b:a  96k -ar 44100 -ac 2'
    else
        audio_encode_codec='-codec:a libmp3lame -b:a 128k -ar 44100 -ac 2'
    fi
}

audiocodec_settings_shine() {
    check_component libshine encoder || component_error libshine 'audio encoder' true
    
    if [ "$streaming" = 'true' ] 
    then
        audio_encode_codec='-codec:a libshine -b:a  96k -ar 44100 -ac 2'
    else
        audio_encode_codec='-codec:a libshine -b:a 128k -ar 44100 -ac 2'
    fi
}

audiocodec_settings_wma() {
    check_component wmav2 encoder || component_error wmav2 'audio encoder' true
    audio_encode_codec='-codec:a wmav2 -b:a 128k -ar 44100 -ac 2'
}
