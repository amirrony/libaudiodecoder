# Radio Program Ripper for Liquidsoap

This project provides Liquidsoap scripts for automatically recording specific radio programs from online streams based on metadata matching.

## Features

✅ **Metadata-based recording**: Only programs matching your specified patterns are recorded  
✅ **Unique filenames**: Each recording gets a timestamp-based filename (YYYYMMDD_HHMM)  
✅ **File size limits**: Automatic stopping when files reach maximum size  
✅ **No unwanted recordings**: Programs that don't match are ignored completely  
✅ **Multiple audio formats**: Support for MP3, FLAC, OGG, and WAV  
✅ **Robust error handling**: Comprehensive logging and graceful error recovery  
✅ **Easy configuration**: Separate config file for simple customization  

## Files Included

- `radio_ripper.liq` - Basic version of the ripper script
- `radio_ripper_advanced.liq` - Enhanced version with better error handling
- `radio_ripper_config.liq` - Configuration file for easy customization

## Requirements

### Install Liquidsoap

**Ubuntu/Debian:**
```bash
sudo apt update
sudo apt install liquidsoap
```

**macOS (with Homebrew):**
```bash
brew install liquidsoap
```

**From source:** Visit [Liquidsoap website](https://www.liquidsoap.info/) for compilation instructions.

### Verify Installation
```bash
liquidsoap --version
```

## Quick Start

1. **Edit the configuration file** (`radio_ripper_config.liq`):
   ```liquidsoap
   # Set your radio stream URL
   STREAM_URL = "http://your-radio-stream-url:8000/stream"
   
   # Set output directory
   OUTPUT_DIR = "/home/user/recordings"
   
   # Add programs to record (regex patterns)
   PROGRAMS_TO_RECORD = [
     "Morning Show",
     "News.*Hour",
     "Jazz.*Night"
   ]
   ```

2. **Run the script:**
   ```bash
   liquidsoap radio_ripper_advanced.liq
   ```

3. **Monitor the logs** to see when recordings start/stop.

## Configuration Options

### Stream Settings
```liquidsoap
STREAM_URL = "http://your-stream-url"  # Your radio stream URL
```

### Output Settings
```liquidsoap
OUTPUT_DIR = "/path/to/recordings"     # Where to save recordings
MAX_SIZE_MB = 100                      # Maximum file size in MB
```

### Audio Quality
```liquidsoap
AUDIO_FORMAT = "mp3"                   # mp3, flac, ogg, wav
BITRATE = 128                          # For MP3: 64, 128, 192, 256, 320
```

### Programs to Record
Define regex patterns that match against the stream's metadata (title, artist, album):

```liquidsoap
PROGRAMS_TO_RECORD = [
  "Morning Show",                      # Exact match
  "News.*Hour",                        # "News" + anything + "Hour"
  ".*Jazz.*",                          # Anything containing "Jazz"
  "BBC|NPR|CBC",                       # Any of these networks
  "^Talk.*Show$",                      # Starts with "Talk", ends with "Show"
  "[Cc]lassical.*[Mm]usic"            # Case variations
]
```

### Advanced Settings
```liquidsoap
BUFFER_SIZE = 5.0                      # Stream buffer in seconds
CHECK_INTERVAL = 30.0                  # File size check interval
LOG_LEVEL = 3                          # 1=error, 2=warning, 3=info, 4=debug
```

## Filename Format

Recordings are saved with this naming pattern:
```
ProgramName_YYYYMMDD_HHMM.format
```

Examples:
- `Morning_Show_20241219_0800.mp3`
- `Jazz_Night_20241219_2100.flac`
- `BBC_World_Service_20241220_0600.mp3`

## How It Works

1. **Stream Connection**: Connects to your radio stream URL
2. **Metadata Monitoring**: Listens for metadata changes (song/program information)
3. **Pattern Matching**: Checks if current metadata matches any of your target programs
4. **Recording Control**: 
   - Starts recording when a matching program begins
   - Stops recording when the program ends or file size limit is reached
   - Ignores non-matching programs completely
5. **File Management**: Creates unique filenames and monitors file sizes

## Usage Examples

### Example 1: NPR Programs
```liquidsoap
STREAM_URL = "https://streams.npr.org/stations/wamu/wamu"
PROGRAMS_TO_RECORD = [
  "Morning Edition",
  "All Things Considered", 
  "Fresh Air",
  ".*News.*"
]
```

### Example 2: Jazz Station
```liquidsoap
STREAM_URL = "http://jazz-stream.example.com:8000"
PROGRAMS_TO_RECORD = [
  "Jazz.*Morning",
  "Smooth.*Jazz",
  ".*Blue.*Note.*",
  "Kind.*of.*Blue"
]
```

### Example 3: Multiple Formats
```liquidsoap
# High quality for classical music
AUDIO_FORMAT = "flac"

PROGRAMS_TO_RECORD = [
  ".*Classical.*",
  ".*Symphony.*",
  ".*Opera.*",
  ".*Chamber.*Music.*"
]
```

## Running the Script

### Foreground (for testing)
```bash
liquidsoap radio_ripper_advanced.liq
```

### Background (production)
```bash
nohup liquidsoap radio_ripper_advanced.liq > /dev/null 2>&1 &
```

### As a Service (systemd)
Create `/etc/systemd/system/radio-ripper.service`:
```ini
[Unit]
Description=Radio Program Ripper
After=network.target

[Service]
Type=simple
User=your-username
WorkingDirectory=/path/to/scripts
ExecStart=/usr/bin/liquidsoap radio_ripper_advanced.liq
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
```

Then:
```bash
sudo systemctl enable radio-ripper
sudo systemctl start radio-ripper
sudo systemctl status radio-ripper
```

## Monitoring and Logs

The script creates detailed logs in:
- Console output (when running in foreground)
- `OUTPUT_DIR/radio_ripper.log` (log file)

### Log Messages to Watch For:
- `Recording started: filename.mp3` - Recording began
- `Recording stopped: filename.mp3` - Recording ended
- `File reached maximum size limit` - Size limit hit
- `Metadata changed` - New program/song detected

## Troubleshooting

### No Recordings Created
1. Check if stream URL is accessible: `curl -I "http://your-stream-url"`
2. Verify metadata patterns match actual stream metadata
3. Check output directory permissions
4. Review logs for error messages

### Recordings Stop Unexpectedly
1. Check network connection stability
2. Verify stream doesn't have connection limits
3. Monitor system disk space
4. Check if file size limit is too small

### Audio Quality Issues
1. Adjust bitrate settings for MP3
2. Try different audio formats (FLAC for lossless)
3. Check if stream provides higher quality

### Pattern Matching Issues
1. Monitor actual metadata with verbose logging
2. Test regex patterns with online regex testers
3. Use case-insensitive patterns: `[Mm]orning.*[Ss]how`

## Tips and Best Practices

1. **Test patterns first**: Run with high log level to see actual metadata
2. **Use specific patterns**: Avoid overly broad patterns that match everything
3. **Monitor disk space**: Set appropriate file size limits
4. **Regular cleanup**: Implement log rotation and old file cleanup
5. **Network stability**: Use wired connection for reliable streams
6. **Backup important recordings**: The script doesn't handle duplicates

## Legal Considerations

- Ensure you have rights to record the streams
- Respect copyright and broadcasting licenses
- Some streams may prohibit recording
- Use recordings for personal/educational purposes only

## Support

For issues with:
- **Liquidsoap syntax**: Check [Liquidsoap documentation](https://www.liquidsoap.info/doc.html)
- **Stream connections**: Verify stream URL and network connectivity
- **Audio quality**: Consult audio encoding documentation
- **Regex patterns**: Use online regex testers and references