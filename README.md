screencast
==========

- [DESCRIPTION](#description)
- [USAGE](#usage)
- [OPTIONS](#options)
    - [`-s, --size=NxN`](#-s---sizenxn)
    - [`-p, --position=N,N`](#-p---positionnn)
    - [`-S, --select-region`](#-s---select-region)
    - [`-r, --fps=N`](#-r---fpsn)
    - [`-f, --format=TYPE`](#-f---formattype)
    - [`-i, --audio-input=NAME`](#-i---audio-inputname)
    - [`-a, --audio-encoder=NAME`](#-a---audio-encodername)
    - [`-v, --video-encoder=NAME`](#-v---video-encodername)
    - [`-A, --vaapi-device=NODE`](#-a---vaapi-devicenode)
    - [`-e, --fade=TYPE`](#-e---fadetype)
    - [`-m, --volume-factor=N`](#-m---volume-factorn)
    - [`-w, --watermark=TEXT`](#-w---watermarktext)
    - [`-z, --wmark-size=NxN`](#-z---wmark-sizenxn)
    - [`-k, --wmark-position=N,N`](#-k---wmark-positionpre---wmark-positionnn)
    - &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;[`--wmark-position=PRE`](#-k---wmark-positionpre---wmark-positionnn)
    - [`-c, --wmark-font=NAME`](#-c---wmark-fontname)
    - [`-W, --webcam`](#-w---webcam)
    - [`-I, --webcam-input=DEV`](#-i---webcam-inputdev)
    - [`-Z, --webcam-size=NxN`](#-z---webcam-sizenxn)
    - [`-P, --webcam-position=N,N`](#-p---webcam-positionpre---webcam-positionnn)
    - &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;[`--webcam-position=PRE`](#-p---webcam-positionpre---webcam-positionnn)
    - [`-R, --webcam-fps=N`](#-r---webcam-fpsn)
    - [`-L, --live-streaming=URL`](#-l---live-streamingurl)
    - [`-1, --one-step`](#-1---one-step)
    - [`-x, --fixed=N`](#-x---fixedn)
    - [`-n, --no-notifications`](#-n---no-notifications)
    - [`-g, --png-optimizer=NAME`](#-g---png-optimizername)
    - [`-o, --output-dir=DIR`](#-o---output-dirdir)
    - [`-t, --tmp-dir=DIR`](#-t---tmp-dirdir)
    - [`-K, --keep`](#-k---keep)
    - [`-u, --auto-filename`](#-u---auto-filename)
    - [`-l, --list`](#-l---list)
    - [`-h, --help`](#-h---help)
    - [`-V, --version`](#-v---version)
- [EXAMPLES](#examples)
- [INSTALLATION](#installation)
- [REQUIREMENTS](#requirements)
- [REMARKS](#remarks)
- [LIMITATIONS](#limitations)
- [LINKS](#links)
- [AUTHOR](#author)
- [COPYRIGHT](#copyright)
- [LICENSE](#license)

------------------------------------------------------------------------

## DESCRIPTION
**screencast** is a command line interface to record a X11 desktop using FFmpeg, having support for offline recording and live streaming. It's designed to make desktop recording a simple task, eliminating the somewhat complex FFmpeg command line arguments and the need of multiple commands. It uses predefined encoder settings that should be suitable for most needs. The default settings provides a quick and affordable way to record the desktop and is YouTube ready, letting the user to be focused on just specifying the desired video size (resolution) and position. If the user doesn't want to stick with the default settings, it is possible to choose among a set of supported encoders and container formats.

**screencast** not only provides an easy way to record your desktop, but it also has options to automatically add some effects to the recordings, like video fade-in / fade-out, text watermarking, webcam overlay and volume increase.

## USAGE
```
$ screencast [options] <output>
$ screencast [options] -u
$ screencast [options] -L <URL>
```

The specified output filename must have an extension which in turn must be a supported container format.

## OPTIONS
- Options usage notes:
    - The default setting will be used for any option that is not specified. You do not need to specify an option if you want to use its default value.
    - Long options can be used with spaces or an equal sign (`=`). For example, `--fade in` is the same as `--fade=in`.
    - Short options cannot be combined in UNIX style. For example, `$ screencast -unx60` cannot be used and should be entered as `$ screencast -u -n -x 60`.

#### `-s, --size=NxN`

The video size. This is actually the video resolution (width x height). Combined with [`-p`](#-p---positionnn) option it will define a rectangular desktop area that will be recorded. This rectangular area must be inside of the current screen size/resolution (cannot be out of screen bounds).

Both the width and height specified in video size must a multiple of 8. This is a requirement for `x265`, `kvazaar`, `theora`, `vp8` and `vp9` video encoders. For `x264`, `h264_nvenc` and `hevc_nvenc` video encoders this is actually not required, but it will avoid speedloss with them.

default: `640x480`

#### `-p, --position=N,N`

The screen position defining from where the recording will take place. These are X and Y offsets from the screen top left corner. Combined with [`-s`](#-s---sizenxn) option it will define a rectangular desktop area that will be recorded. This rectangular area must be inside of the current screen size/resolution (cannot be out of screen bounds).

default: `0,0` (screen top left corner)

#### `-S, --select-region`

Select with mouse the screen region to record. Use a single mouse click to select an entire window. Click and drag with mouse to select a region. When dragging, use the arrow keys to fine tune. Right click or any other keystroke to cancel. The [`-s`](#-s---sizenxn) and [`-p`](#-p---positionnn) options cannot be used with this option.

The selected width and height must be a multiple of 8 (please see the [`-s`](#-s---sizenxn) option for details). It's hard to select a screen region that matches this need with the currently used tool. To overcome this, if the width and height of the selected region does not meet this requirement they will be automatically changed to the immediately higher number that comply with this criteria. Note that if these newly changed values are out of screen bounds **screencast** will not be able to record and will exit with error.

#### `-r, --fps=N`

Video framerate (frames per second - fps).

default: `25`

#### `-f, --format=TYPE`

Container format of the output video. This option can be used only with the [`-u`](#-u---auto-filename) option (if you want to specify a container format when using automatic output filename choosing). This option cannot be used when entering an output filename. When not using the [`-u`](#-u---auto-filename) option, the container format needs to be specified directly in the output filename.

default: `mp4`

supported types: `mp4`, `mov`, `mkv`, `webm`, `ogg`, `ogv`, `flv`, `nut`, `wmv`, `asf`, `avi`

#### `-i, --audio-input=NAME`

ALSA audio input device name. Make sure to have a working ALSA configuration, for example, by a having properly configured `~/.asoundrc` file. To determine possible ALSA input device names please see the [FFmpeg ALSA capture guide](https://trac.ffmpeg.org/wiki/Capture/ALSA).

- Some special values that can be used:
    - `none`: audio will be disabled (video without audio, only video stream will be present)
    - `default`: the default ALSA device
    - `pulse`: the default PulseAudio device

default: `default`

**note**: the default audio recording backend used by **screencast** is ALSA. If your FFmpeg build has no support for ALSA, it will fallback to use the PulseAudio backend (a warning message will be displayed), and in this case you can use this option to specify a PulseAudio input source name. To determine possible PulseAudio input source names you can use the `pactl` utility (`$ pactl list sources`).

#### `-a, --audio-encoder=NAME`

Audio encoder that will be used to encode the recorded audio. When setted to `none` the audio will be disabled (video without audio, only video stream will be present).

default: `aac`

supported types: `aac`, `opus`, `vorbis`, `mp3lame`, `shine`, `wma`, `none`

#### `-v, --video-encoder=NAME`

Video encoder that will be used to encode the recorded video. If using a hardware accelerated video encoder please make sure that you have a graphics card that supports the specified encoder. Note that hardware accelerated video encoders have additional requirements: NVENC requires NVIDIA drivers to be installed, VAAPI requires libva and libdrm to be installed and QSV requires Intel Media SDK to be installed.

default: `x264`

- supported types:
    - `x264`, `h264_nvenc`, `h264_vaapi`, `h264_qsv`, `x265`, `kvazaar`, `hevc_nvenc`, `hevc_vaapi`, `hevc_qsv`, `vp8`, `vp8_vaapi`, `vp9`, `vp9_vaapi`, `theora`, `wmv`

#### `-A, --vaapi-device=NODE`

DRM render node (VAAPI device) that will be used to encode the recorded video. This option can be used only when specifying a VAAPI hardware accelerated video encoder with the [`-v`](#-v---video-encodername) option and cannot be used when selecting other video encoders. Please make sure that the specified DRM render node is the right one.

default: `/dev/dri/renderD128`

#### `-e, --fade=TYPE`

Enable video fade effect, setting the fade type to *TYPE*. When setted to `none` the recorded video will have no fade effect.

default: `none`

supported types: `in`, `out`, `both`, `none`

#### `-m, --volume-factor=N`

Volume increase effect factor. This will increase the volume of the recorded audio. Usually, audio volume is low with default settings, even if you increse your microphone capture volume. Use this to give your videos a better hearing experience, letting your viewers fell more confortable to watch it whithout needing to rise their sound volume.

It works as a percentage factor. For example, a value of `1.5` will increase volume by 50% and a value of `2.0` will double volume. It is also possible to set a volume decrease effect, although this is not recommended since for this you can simply decrease your microphone recording volume (for example, a value of `0.5` will decrease volume by 50%).

This option can be used only when the [`-i`](#-i---audio-inputname) and [`-a`](#-a---audio-encodername) options are not setted to `none`. When setted to `1.0` or `0.0` this effect is disabled.

default: `1.0` (disabled)

#### `-w, --watermark=TEXT`

Enable text watermark effect, setting the text to *TEXT*. Although it is a text, it is generated as a PNG image so it can be integrated in the video.

default: disabled

#### `-z, --wmark-size=NxN`

Set text watermark size (resolution). Note that the generated image will be trimmed to remove the unneeded transparent areas. As a result, the actual PNG image that will be added to the video will have a slightly smaller size than the one specified here. This option can be used only with the [`-w`](#-w---watermarktext) option.

default: `255x35`

#### `-k, --wmark-position=PRE, --wmark-position=N,N`

Set text watermark position inside the video. This option can be used only with the [`-w`](#-w---watermarktext) option.

- It accepts two types of values:
    - `NxN`: X and Y offsets from the video top left corner (not from the screen)
    - `PRE`: a predefined special value

supported predefined special values: `topleft`/`tl`, `topright`/`tr`, `bottomleft`/`bl`, `bottomright`/`br`

default: `bottomright`

#### `-c, --wmark-font=NAME`

Set text watermark font to *NAME*. This option can be used only with the [`-w`](#-w---watermarktext) option.

default: `Arial`

**note**: if the default or setted font is not installed it will be auto chosen

#### `-W, --webcam`

Enable webcam overlay effect. Before recording with webcam you can adjust your webcam settings like brightness, contrast and gamma correction with the `v4l2-ctl` utility (use `$ v4l2-ctl -L` to show available values and `$ v4l2-ctl -c <option>=<value>` to set values).

default: disabled

#### `-I, --webcam-input=DEV`

Webcam input device, usually in the form of `/dev/videoN`. To list video capture devices on your system you can use the `v4l2-ctl` utility (`$ v4l2-ctl --list-devices`). This option can be used only with the [`-W`](#-w---webcam) option.

default: `/dev/video0`

#### `-Z, --webcam-size=NxN`

Set webcam video size (resolution). To get a list of supported resolutions for your webcam device you can execute `$ ffmpeg -f v4l2 -list_formats all -i <device>` or use the `v4l2-ctl` utility (`$ v4l2-ctl --list-formats-ext`). This option can be used only with the [`-W`](#-w---webcam) option.

default: `320x240`

#### `-P, --webcam-position=PRE, --webcam-position=N,N`

Set the webcam overlay position inside the video. This option can be used only with the [`-W`](#-w---webcam) option.

- It accepts two types of values:
    - `NxN`: X and Y offsets from the video top left corner (not from the screen)
    - `PRE`: a predefined special value

supported predefined special values: `topleft`/`tl`, `topright`/`tr`, `bottomleft`/`bl`, `bottomright`/`br`

default: `topright`

#### `-R, --webcam-fps=N`

Set webcam framerate (fps). To get a list of supported framerates for your webcam device you can use the `v4l2-ctl` utility (`$ v4l2-ctl --list-formats-ext`). This option can be used only with the [`-W`](#-w---webcam) option.

default: device default

#### `-L, --live-streaming=URL`

Do a live streaming to the server address specified in *URL*. Please make sure to have a working connection to the specified server address and sufficient upload bandwidth to send the data. Note that the higher the video size (resolution) and framerate (fps), the higher will be the needed upload bandwidth. Use the [`-K`](#-k---keep) option if you want to save a local copy of the live streamed video. It uses a one step process (record and encode at the same time). **screencast** will record offline when this option is not specified. It has been tested only with the [YouTube](https://www.youtube.com/) live streaming service. It is recommended to use a hardware accelerated video encoder with this option.

- Some restrictions apply:
    - can be used only with audio encoders: `aac`, `mp3lame` and `shine`
    - can be used only with video encoders: `x264`, `h264_nvenc`, `h264_vaapi` and `h264_qsv`
    - can be used only with container formats (when saving the live streamed video with [`-K`](#-k---keep) option): `mp4`, `mov`, `mkv`, `flv`, `nut`, `wmv`, `asf` and `avi`
    - cannot be used with fade effect ([`-e`](#-e---fadetype) option)
    - must be recorded with audio ([`-i`](#-i---audio-inputname) and [`-a`](#-a---audio-encodername) options cannot be setted to `none`)

default: disabled

#### `-1, --one-step`

Enable recording in a one step process (record and encode at the same time, without a second encoding step). It will produce a larger video filesize, take less time and require less CPU power when compared to recording in two steps (CPU power comparison is when not using a hardware accelerated encoder). Regarding to filesize and CPU power, this option affects only the `x264`, `x265` and `kvazaar` software-based video encoders. This option cannot be used with fade effect ([`-e`](#-e---fadetype) option). This option is worth to be used with a hardware accelerated encoder, like the NVENC or VAAPI ones, or when using CPU-intensive tasks accompanied by one of the affected software-based encoders that were mentioned (and not needing the fade effect). You do not need to specify this option when doing a live streaming ([`-L`](#-l---live-streamingurl) option) because it already works in a one step process. Note that the default **screencast** behavior is to record in a two step process (1st step: lossless recording. 2nd step: encoding). **This option can cause audio problems. It is not recommended to use it with software-based video encoders.**

default: disabled

#### `-x, --fixed=N`

Set the video to have a fixed length of *N* seconds. When setted to `0` this is disabled, meaning a indefinite video length that will be recorded until the user stops it by presing the **q** key in the terminal window.

default: `0` (disabled)

#### `-n, --no-notifications`

Disable desktop notifications. Desktop notifications are shown by default, allowing a better visual control of the recording. Use this option to disable them.

#### `-g, --png-optimizer=NAME`

Use PNG optimizer *NAME* and *advdef* (advancecomp) in the PNG image generated by the [`-w`](#-w---watermarktext) option that will be used as a text watermark. This option is useful when you want to use a big text watermark in a big video, allowing the video to be a bit smaller. Not really needed if using the default watermark settings with a small text. When setted to `none`, PNG optimization is disabled. This option can be used only with the [`-w`](#-w---watermarktext) option.

default: `none`

supported ones: `truepng`, `pingo`, `optipng`, `opt-png`, `none`

#### `-o, --output-dir=DIR`

Set the output video to be saved in *DIR*. This option can be used only with the [`-u`](#-u---auto-filename) option (if you want to specify a save directory when using automatic output filename choosing). This option cannot be used when entering an output filename. When not using the [`-u`](#-u---auto-filename) option, the output directory needs to be specified directly in the output filename.

default: the local directory

#### `-t, --tmp-dir=DIR`

Set temporary files to be placed in *DIR*. By default, the `/tmp` directory will be used for temporary files, which usually is a ramdisk filesystem in most systems. You may want to change it if you have limited RAM and/or are recording very long videos. Make sure to have enough free space in the specified directory.

default: `/tmp`

#### `-K, --keep`

When recording offline it will keep (don't delete) the temporary video. When doing a live streaming it will keep (save) the live streamed video.

#### `-u, --auto-filename`

Auto choose output filename based on date and time. The output filename will have the following format:

screencast-YEAR-MONTH-DAY_HOUR.MINUTE.SECOND.FORMAT

#### `-l, --list`

List arguments supported by these options.

#### `-h, --help`

Help screen.

#### `-V, --version`

Show program version information.

## EXAMPLES
- Use all default settings, specifying filename of the output video:

    - `$ screencast myvideo.mp4`

- Use default settings for a 1280x720 video from screen positon 200,234 (with auto chosen output filename, default `mp4` format):

    - `$ screencast -u -s 1280x720 -p 200,234 `

- Changing just the container format without specifying encoders will make it to auto choose them if needed. In this case, the `webm` format will produce a video with `opus` and `vp9` encoders:

    - `$ screencast /home/user/webmvideos/myvideo.webm`

- Use hardware accelerated video encoders:

    - NVENC HEVC:
    
        - `$ screencast -u -v hevc_nvenc`
    
    - VAAPI VP9 using the defafult DRM render node (/dev/dri/renderD128):
    
        - `$ screencast -u -v vp9_vaapi`
    
    - VAAPI H.264 using the defafult DRM render node (/dev/dri/renderD128):
    
        - `$ screencast -u -v h264_vaapi`
    
    - VAAPI H.264 using the DRM render node /dev/dri/renderD129:
    
        - `$ screencast -u -v h264_vaapi -A /dev/dri/renderD129`
    
- Live streaming:

    - Live streaming only, without saving a local output video:
    
        - `$ screencast -L <URL> -v h264_vaapi
    
    - Live streaming and also saving a copy to a local output video (with auto chosen output filename, default `mp4` format):
    
        - `$ screencast -L <URL> -v h264_nvenc -K -u

- 1280x720 video from screen positon 200,234 , 30 fps, `mp3lame` audio encoder, `x265` video encoder, `mkv` container format, fade-in video effect, volume increase effect of 50%, small text watermark effect in bottom right video corner (using the default values for watermark size, position and font) and webcam overlay effect at top right video corner (using the default values for webcam input, size position and framerate):

    - `$ screencast -s 1280x720 -p 200,234 -r 30 -a mp3lame -v x265 -e in -m 1.5 -w www.mysitehere.com -W myvideo.mkv`

**NOTE**:
When not using the [`-x`](#-x---fixedn) option, press the **q** key in terminal window to end the recording.

## INSTALLATION
Make the **screencast** file executable and copy it to a directory that is in your *PATH*.

Copy the *screencast.1* man page file to your user commands man page directory, usually at `/usr/share/man/man1`. For convenience, firstly compress the man page with *gzip*.

You can acomplish this by doing:

```
$ chmod +x screencast
$ sudo mv screencast /usr/local/bin
$ gzip -9 -n screencast.1
$ sudo mv screencast.1.gz /usr/share/man/man1
```

## REQUIREMENTS
- The minimum requirements are a POSIX-compatible shell, a running X session, a recent *FFmpeg* version and *xdpyinfo*. It's advised to use *FFmpeg* version git master. *FFmpeg* needs to be compiled with support for x11grab (libxcb) and the desired encoders and muxers. When recording offline, *FFmpeg* needs to be compiled with support for ffv1 encoder, ffv1 decoder and matroska muxer (**screencast** will try to auto-fallback to ffvhuff or huffyuv encoder/decoder if ffv1 is not supported and to nut muxer if matroska is not supported, but ffv1 and matroska are preferred). When live streaming, *FFmpeg* needs to compiled with support for flv muxer. You can see a *FFmpeg* compilation guide and **screencast** packages at the [LINKS](#links) section.

- When recording audio ([`-i`](#-i---audio-inputname) and [`-a`](#-a---audio-encodername) options not setted to `none`), *FFmpeg* must have been compiled with support for ALSA demuxer (**screencast** will try to auto-fallback to PulseAudio demuxer if ALSA is not supported, but ALSA is preferred). *arecord* (alsa-utils) will be required for ALSA when specifying a short or long ALSA input device name with the [`-i`](#-i---audio-inputname) option. If the PulseAudio demuxer is being used in the described auto-fallback situation, *pactl* will be required when specifying a PulseAudio input source name with with the [`-i`](#-i---audio-inputname) option. When using webcam overlay effect ([`-W`](#-w---webcam)option), *FFmpeg* must have been compiled with support for Video4Linux2.

- *notify-send* (libnotify) is needed for desktop notifications. Note that desktop notifications are enabled by default. They can be disabled by using the [`-n`](#-n---no-notifications) option, eliminating the need of *notify-send*. Running **screencast** in a system without *notify-send* and without using the [`-n`](#-n---no-notifications) option will result in error.

- **screencast** will try to play a notification sound when the encoding process is finished. For this, it will use *paplay* (from PulseAudio) and a sound file from the freedesktop sound theme (usually a package called *sound-theme-freedesktop* in most Linux distributions). Although not a requirement, they are recommended to be installed for a better user experience.

- Other requirements are needed according to additional options that may be specified by the user:

    - *slop* is needed for selecting the screen region with mouse ([`-S`](#-s---select-region) option).

    - *FFprobe* and *bc* are needed for video fade effect ([`-e`](#-e---fadetype) option).

    - *ImageMagick* is needed for text watermark effect ([`-w`](#-w---watermarktext) option). Both IM6 and IM7 are supported, but IM7 is preferred.

    - At least one supported PNG optimizer and *advdef* (advancecomp) are needed for PNG (watermark) optimization ([`-g`](#-g---png-optimizername) option).

## REMARKS
- **screencast** is written in pure POSIX shell code and has been tested in bash, dash, yash, ksh and zsh.

- When recording offline, the default **screencast** behavior is to use a two step process: firstly the audio and video are recorded to a lossless format, and at a second step it is encoded to produce the final output video. That's why you see a desktop notification saying '*encoding...*'. This mechanism produces a better video, avoids problems and allows to use fade effect. When live streaming or when using the [`-1`](#-1---one-step)/[`--one-step`](#-1---one-step) option, **screencast** uses a one step process, with recording and encoding at the same time.

- When using `aac` audio encoder (which is the default setting), **screencast** will check if the detected FFmpeg build has support for libfdk\_aac and use it if present, otherwise it will use the FFmpeg built-in AAC audio encoder. Make sure to have a recent FFmpeg version as older versions do not support the built-in AAC audio encoder without being experimental, or do not support it at all.

- FFmpeg encoder names have the 'lib' prefix removed for simplicity. For example, libx264 is called `x264` in this program.

- For vorbis and opus audio, FFmpeg has both an external library encoder (named '*libvorbis*' and '*libopus*' encoders) and a native built-in encoder (named '*vorbis*' and '*opus*' encoders). Although the `vorbis` and `opus` audio encoders are mentioned in the options, it is made this way just for simplicity as stated right above. When the user selects the `vorbis` or `opus` audio encoder, **screencast** uses respectively the FFmpeg libvorbis or libopus encoder, which has a much superior quality than the FFmpeg native built-in vorbis and opus encoders.

- The `mkv` and `nut`container formats are the only ones that support a combination of all audio and video encoders. All other container formats have restrictions. **screencast** will exit with error if an unsupported encoder is chosen for a given container format. For example, you cannot use the `aac` audio encoder with `webm` container format.

- When using the `mp4` container format, the moov atom will be automatically moved to the beginning of the output video file. This is the same as running *qt-faststart* in the output video and is useful for uploading to streaming websites like [YouTube](https://www.youtube.com/).

- The default settings for container format and audio/video encoders will produce a video that is ready to be uploaded to [YouTube](https://www.youtube.com/).

## LIMITATIONS
**screencast** currently records only display `0` and screen `0` (`DISPLAY` value of `:0.0` - or `:0`), which is sufficient for single monitor environments. It may not produce the expected results when using a multi-monitor environment depending on your settings.

It has been reported that **screencast** does not work under Wayland.

## LINKS
- FFmpeg:
    - [Homepage](https://www.ffmpeg.org/)
    - [Compilation guide](https://trac.ffmpeg.org/wiki/CompilationGuide/)
    - [Arch Linux (AUR package) version git master with all libs including libfdk_aac](https://aur.archlinux.org/packages/ffmpeg-full-git/)

- **screencast** packages:
    - [Arch Linux (AUR package, release version)](https://aur.archlinux.org/packages/screencast/)
    - [Arch Linux (AUR package, git master version)](https://aur.archlinux.org/packages/screencast-git/)

## AUTHOR
Daniel Bermond

[https://github.com/dbermond/screencast/](https://github.com/dbermond/screencast/)

## COPYRIGHT
Copyright © 2015-2017 Daniel Bermond

## LICENSE
GNU General Public License as published by the Free Software Foundation, either version 2 of the License, or (at your option) any later version.

For details see the file COPYING or visit:
[http://www.gnu.org/licenses/](http://www.gnu.org/licenses/)

------------------------------------------------------------------------
