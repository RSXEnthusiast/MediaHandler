# MediaHandler
## Overview
This project converts the audio from AAC to WAV and generates DNXHR_SQ 720p proxies for all MP4 files in a directory recursively.

**WARNING: THIS IS ALWAYS A WIP, AND DESIGNED FOR MY PERSONAL USE AND WORKFLOW. IF YOU DECIDE TO USE IT, CREATE BACKUPS OF YOUR MEDIA, THIS TOOL COULD BE DESTRUCTIVE.**

If I have spare time I might consider making a more universal version, but this is not that version, I just needed this to work for my workflow.

## What this does
* Recursively searches for mp4 files in a given directory, preserving the directory structure as it modifies the files
    * No need to put all of your input files into one directory for handling, keep your media organized into folders as you desire.
* Replaces AAC audio in MP4 (H.264) files with WAV
* Generates Proxies for media and places them in ./Proxy
* If cancelled, finishes current media before exiting.
    * It is not suggested to force quit the script, it could result in lost media.

## Dependencies
* Zenity
    * `sudo apt install zenity`
    * This is for a prettier notification window. It could be stripped from the tool pretty easily if desired.

## What this doesn't do
* Handle files that aren't mp4
   * Could probably easily be modified to handle other media types, but this is all I need, so it's all the tool searches for.
* Preserve the original media
   * The video track should be preserved at original quality
   * The Audio track will be overwritten by the new WAV audio track
      * This should be a lossless conversion, unless I messed up my ffmpeg command
* Run automatically when detecting new media
   * You could set this cron job up, but I would not suggest it and haven't tested it.
   * It's intended to be run after dumping footage from cameras and organizing it into directories.
* So much other stuff that I haven't listed here
   * Walk your dog
   * Edit the video for you
   * Repair your personal relationships

## Usage
* Clone into your directory with your media, then run the script. It will recursively process all of the media in the same folder as the MediaHandler folder, `../*` from the script, aka the folder above where the script is located.
* Eg.
   * I have a project directory called PROJECT containing four folders, each containing media for a specific camera angle. PROJECT is in a foldernamed VIDEO_PROJECTS
   * I'd clone into the VIDEO_PROJECTS folder, so VIDEO_PROJECTS would contain the folders PROJECT and MediaHandler.
   * The script would recursively scan for all media in the VIDEO_PROJECTS folder.
   * If you only wanted to convert media in the PROJECT folder, instead of all media in the VIDEO_PROJECTS folder, you'd need to clone into the PROJECT folder instead.
