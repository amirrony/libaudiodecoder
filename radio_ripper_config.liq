# Radio Ripper Configuration
# Edit this file to customize your recording settings

# Stream Configuration
STREAM_URL = "http://your-radio-stream-url:8000/stream"
# Alternative examples:
# STREAM_URL = "http://streaming.radio.co:8000/listen"
# STREAM_URL = "https://streams.npr.org/stations/wamu/wamu"

# Output Settings
OUTPUT_DIR = "/tmp/recordings"
MAX_SIZE_MB = 100  # Maximum file size in MB

# Audio Quality Settings
AUDIO_FORMAT = "mp3"     # Options: mp3, flac, ogg, wav
BITRATE = 128            # For MP3: 64, 128, 192, 256, 320

# Programs to Record
# Add regex patterns that match the metadata of programs you want to record
# These patterns are matched against title, artist, and album metadata
PROGRAMS_TO_RECORD = [
  "Morning Show",           # Exact match
  "News.*Hour",            # "News" followed by anything, then "Hour"
  "Jazz.*Night",           # "Jazz" followed by anything, then "Night"
  "Classical.*Music",      # "Classical" followed by anything, then "Music"
  ".*Talk.*Show.*",        # Anything with "Talk" and "Show"
  "BBC.*World.*Service"    # BBC World Service variations
]

# Advanced Settings
BUFFER_SIZE = 5.0        # Buffer size in seconds
CHECK_INTERVAL = 30.0    # File size check interval in seconds
LOG_LEVEL = 3            # 1=error, 2=warning, 3=info, 4=debug

# Examples of more complex regex patterns:
# "^Morning.*"             # Programs starting with "Morning"
# ".*[Nn]ews.*"           # Case-insensitive news programs
# "BBC|NPR|CBC"           # Programs containing BBC, NPR, or CBC
# "[Jj]azz|[Bb]lues"     # Jazz or Blues programs (case variations)