# MediaHandler
Handles the Media I Record for Editing with Davinci Resolve Studio on Linux.

WARNING: THIS IS ALWAYS A WIP, AND DESIGNED FOR MY PERSONAL USE AND WORKFLOW. CREATE BACKUPS BEFORE RUNNING, IF YOU DECIDE TO USE IT.
If I have spare time I might consider making a more universal version, but this is not that version.

# This project does a few things to handle media for editing with Resolve Studio on Linux.
* Recursively searches for media in a directory.
* Replaces AAC audio in MP4 (H.264) files with WAV
* Moves .lrv files to ./Proxies and changes the extension to .mov
* Generates .mov Proxies for media without associated .lrv files and places them in ./Proxies

# Usage
* Clone into your directory with your media. It will recursively process all of the media in the same folder as the MediaHandler folder.
