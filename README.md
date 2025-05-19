# MediaHandler
## Overview
This project converts audio from AAC to WAV (required for editing with Davinci Resolve Studio on Linux) and generates DNXHR_LB proxies for all MP4 files in a directory, scanned recursively.

**WARNING: THIS IS ALWAYS A WIP, AND DESIGNED FOR MY PERSONAL USE AND WORKFLOW. IF YOU DECIDE TO USE IT, CREATE BACKUPS OF YOUR MEDIA, THIS TOOL COULD BE DESTRUCTIVE.**

## What this does
* Recursively searches for mp4 files in a given directory, preserving the directory structure as it modifies the files
    * No need to put all of your input files into one directory for handling, keep your media organized into folders as you desire.
* Replaces AAC audio in MP4 files with WAV
* Generates Proxies for media and places them in ./Proxy
* Generates a semi-accurate progress bar based off of file size.
* If cancelled, finishes current media before exiting.
    * It is not suggested to force quit the script, it could result in lost media.

## What this doesn't do
* Handle files that aren't mp4
   * Could probably easily be modified to handle other media types, but this is all I need, so it's all the tool searches for.
* Preserve the original media
   * The video track should be preserved at original quality
   * The Audio track will be overwritten by the new WAV audio track
      * This should be a lossless conversion, unless I messed up my ffmpeg command
* Run automatically when detecting new media in a folder
   * You could set this sort of automatic folder scanning job up, but I would not suggest it and haven't tested it.
   * It's intended to be run manually after dumping footage from cameras and organizing it into directories.
* Transcode the MP4 video to something that can be edited with Davinci Resolve Free.
   * You'd just need to edit the ffmpeg command, but considering I have studio, I chose to save the time and skip transcoding the video.
* So much other stuff that I haven't listed here
   * Walk your dog
   * Edit the video for you
   * Repair your personal relationships

## Dependencies
* ffmpeg
   * Video Transcoding Tools
* ffprobe
   * Video stat checking tools
* Zenity
    * This is for a prettier notification window. It could be stripped from the tool pretty easily if desired.

## Parameters
* `-d` `--directory` REQUIRED - The directory to recursively scan for files.
    * Follow this with the directory you'd like to process (see examples)
    * Will scan all files in this directory and any sub directories.
* `-a` `--audio` OPTIONAL - Transcodes audio from AAC to WAV for all of the found files.
* `-p` `--proxies` OPTIONAL - Generates proxies for all of the found files.
* `-r` `--proxy_resolution` OPTIONAL - Defaults to 540
    * Sets the horizontal resolution to scale the proxies to.
    * Vertical resolution is automatically scaled to keep aspect ratio
* NOTE: Proxy Generation and Audio Transcoding WILL be handled in the order they're passed in.
    * E.g. if you pass in `-a -p` audio transcoding will happen for all files, then proxy generation will happen for all files.
    * E.g. if you pass in `-p -a` proxy generation will happen for all files, then audio trandcoding will happen for all files.
    * Generally you probably want to do Audio first, as if you do proxies first, they will have AAC audio.

## Examples
* These can be found in the Example folder

## Planned Features
**If there's something you'd like implemented that isn't listed here please suggest it or make a PR**
* There are no currently planned features.
