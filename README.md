# MediaHandler
This was originally designed as a tool to convert the AAC audio of MP4 files to WAV for editing on Davinci Resolve Studio on Linux, keeping all of the files in their existing directories for organization, but it balloned to the point where it handles that, in addition to all of my Proxy needs, handling included LRV files and generating proxies where those are absent.

**WARNING: THIS IS ALWAYS A WIP, AND DESIGNED FOR MY PERSONAL USE AND WORKFLOW. IF YOU DECIDE TO USE IT, CREATE BACKUPS OF YOUR MEDIA, THIS TOOL COULD BE DESTRUCTIVE.**

If I have spare time I might consider making a more universal version, but this is not that version, I just needed this to work for my workflow.

# What this does
* Recursively searches for mp4 and lrv files in a given directory, preserving the directory structure
    * No need to put all of your input files into one directory for handling
* Replaces AAC audio in MP4 (H.264) files with WAV
* Moves .lrv files to ./Proxies and changes the extension to .mov
* Generates .mov Proxies for media without associated .lrv files and places them in ./Proxies
* If cancelled, finishes current media before exiting.
    * It is not suggested to force quit the script, it can result in lost media.

# Dependencies
* Zenity
    * `sudo apt install zenity`
    * This is for a prettier notification window. It could be stripped from the tool pretty easily if desired.

# What this doesn't do
* Handle files that aren't mp4 or lrv
* Preserve the original media
* So much other stuff that I haven't listed here

# Usage
* Clone into your directory with your media, then run the script. It will recursively process all of the media in the same folder as the MediaHandler folder, the folder above where the script is located.
