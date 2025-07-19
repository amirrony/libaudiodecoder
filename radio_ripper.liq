#!/usr/bin/liquidsoap

# Radio Program Ripper Script
# This script rips specific programs from a radio stream based on metadata matching

# Configuration
set("log.level", 3)
set("log.stdout", true)

# Stream URL - replace with your radio stream URL
STREAM_URL = "http://your-radio-stream-url:8000/stream"

# Output directory for recordings
OUTPUT_DIR = "/tmp/recordings"

# Maximum file size in MB (adjust as needed)
MAX_SIZE_MB = 100

# Programs to record - add your program names/patterns here
# These are regex patterns that will be matched against metadata
PROGRAMS_TO_RECORD = [
  "Morning Show",
  "News.*Hour",
  "Jazz.*Night", 
  "Classical.*Music"
]

# File format settings
AUDIO_FORMAT = "mp3"
BITRATE = 128

# Utility function to check if current metadata matches any program we want to record
def should_record(m) =
  title = m["title"]
  artist = m["artist"] 
  album = m["album"]
  
  # Combine all metadata fields for matching
  metadata_string = "#{title} #{artist} #{album}"
  
  # Check if any of our target programs match
  list.exists(fun(pattern) -> 
    string.match(pattern=pattern, metadata_string)
  , PROGRAMS_TO_RECORD)
end

# Function to generate unique filename with timestamp
def generate_filename(m) =
  title = m["title"]
  # Clean title for filename (remove special characters)
  clean_title = string.replace(pattern="[^a-zA-Z0-9_-]", fun(_) -> "_", title)
  
  # Get current timestamp
  time_info = time()
  year = string_of_int(time_info.year)
  month = string.format("%02d", time_info.month)
  day = string.format("%02d", time_info.mday) 
  hour = string.format("%02d", time_info.hour)
  min = string.format("%02d", time_info.min)
  
  # Create filename: ProgramName_YYYYMMDD_HHMM.format
  filename = "#{clean_title}_#{year}#{month}#{day}_#{hour}#{min}.#{AUDIO_FORMAT}"
  "#{OUTPUT_DIR}/#{filename}"
end

# Function to check file size and stop recording if limit exceeded
def check_file_size(filename) =
  try
    # Get file size in MB
    size_bytes = file.size(filename)
    size_mb = size_bytes / (1024 * 1024)
    
    if size_mb >= MAX_SIZE_MB then
      log("File #{filename} reached maximum size limit (#{MAX_SIZE_MB}MB), stopping recording")
      true
    else
      false
    end
  with
    _ -> false
  end
end

# Create output directory if it doesn't exist
def ensure_output_dir() =
  if not file.exists(OUTPUT_DIR) then
    log("Creating output directory: #{OUTPUT_DIR}")
    file.mkdir(OUTPUT_DIR)
  end
end

# Initialize output directory
ensure_output_dir()

# Main stream source
radio_stream = input.http(STREAM_URL)

# Add buffer to handle network issues
radio_stream = buffer(radio_stream)

# Variable to track current recording state
current_recording = ref(none())
current_filename = ref("")

# Function to start recording
def start_recording(m) =
  filename = generate_filename(m)
  current_filename := filename
  
  log("Starting recording: #{filename}")
  log("Metadata - Title: #{m['title']}, Artist: #{m['artist']}")
  
  # Create the file output
  output.file(
    %mp3(bitrate=BITRATE),
    filename,
    radio_stream,
    fallible=true,
    on_start={log("Recording started: #{filename}")},
    on_stop={log("Recording stopped: #{filename}")}
  )
  
  current_recording := some(filename)
end

# Function to stop recording
def stop_recording() =
  match !current_recording with
  | some(filename) ->
    log("Stopping recording: #{filename}")
    current_recording := none()
    current_filename := ""
  | none() -> ()
  end
end

# Metadata change handler
def on_metadata_change(m) =
  log("Metadata changed - Title: #{m['title']}, Artist: #{m['artist']}, Album: #{m['album']}")
  
  should_rec = should_record(m)
  currently_recording = match !current_recording with | some(_) -> true | none() -> false end
  
  if should_rec and not currently_recording then
    # Start new recording
    start_recording(m)
  elsif not should_rec and currently_recording then
    # Stop current recording
    stop_recording()
  elsif currently_recording then
    # Check file size if we're currently recording
    filename = !current_filename
    if filename != "" and check_file_size(filename) then
      stop_recording()
    end
  end
end

# Attach metadata handler
radio_stream = on_metadata(on_metadata_change, radio_stream)

# Regular file size check for ongoing recordings (every 30 seconds)
def periodic_size_check() =
  match !current_recording with
  | some(filename) ->
    if check_file_size(filename) then
      stop_recording()
    end
  | none() -> ()
  end
end

# Schedule periodic size checks
add_timeout(30.0, periodic_size_check)

# Output to soundcard (optional - comment out if you don't want audio playback)
# output.alsa(radio_stream)

# Keep the script running
output.dummy(radio_stream)

# Log startup message
log("Radio Ripper started")
log("Stream URL: #{STREAM_URL}")
log("Output directory: #{OUTPUT_DIR}")
log("Maximum file size: #{MAX_SIZE_MB}MB")
log("Programs to record: #{string.concat(separator=', ', PROGRAMS_TO_RECORD)}")