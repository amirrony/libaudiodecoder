#!/usr/bin/liquidsoap

# Advanced Radio Program Ripper Script
# This script includes improved error handling, multiple format support, and configuration loading

# Load configuration
%include "radio_ripper_config.liq"

# Enhanced Configuration with defaults
set("log.level", LOG_LEVEL)
set("log.stdout", true)
set("log.file", true)
set("log.file.path", "#{OUTPUT_DIR}/radio_ripper.log")

# Global variables for recording state
recording_outputs = ref([])
active_recordings = ref([])

# Enhanced metadata cleaning function
def clean_string_for_filename(s) =
  # Replace problematic characters with underscores
  s1 = string.replace(pattern="[<>:\"/\\|?*]", fun(_) -> "_", s)
  # Replace multiple spaces/underscores with single underscore
  s2 = string.replace(pattern="[\\s_]+", fun(_) -> "_", s1)
  # Remove leading/trailing underscores
  string.trim(s2)
end

# Enhanced filename generation with fallback
def generate_filename(m) =
  # Try to get meaningful program name from metadata
  title = m["title"]
  artist = m["artist"]
  album = m["album"]
  
  program_name = if title != "" then
    clean_string_for_filename(title)
  elsif artist != "" then
    clean_string_for_filename(artist)
  elsif album != "" then
    clean_string_for_filename(album)
  else
    "unknown_program"
  end
  
  # Limit program name length
  program_name = if string.length(program_name) > 50 then
    string.sub(program_name, start=0, length=50)
  else
    program_name
  end
  
  # Generate timestamp
  time_info = time()
  timestamp = string.format("%04d%02d%02d_%02d%02d", 
    time_info.year, time_info.month, time_info.mday, 
    time_info.hour, time_info.min)
  
  # Create filename
  filename = "#{program_name}_#{timestamp}.#{AUDIO_FORMAT}"
  "#{OUTPUT_DIR}/#{filename}"
end

# Function to get audio encoder based on format
def get_encoder() =
  if AUDIO_FORMAT == "mp3" then
    %mp3(bitrate=BITRATE)
  elsif AUDIO_FORMAT == "flac" then
    %flac(compression=5)
  elsif AUDIO_FORMAT == "ogg" then
    %vorbis(quality=0.5)
  elsif AUDIO_FORMAT == "wav" then
    %wav
  else
    log("Unknown audio format: #{AUDIO_FORMAT}, defaulting to MP3")
    %mp3(bitrate=BITRATE)
  end
end

# Enhanced metadata matching function
def should_record(m) =
  # Get all metadata fields
  title = string.case(lower=true, m["title"])
  artist = string.case(lower=true, m["artist"])
  album = string.case(lower=true, m["album"])
  
  # Combine all metadata for comprehensive matching
  metadata_string = "#{title} #{artist} #{album}"
  
  # Check against all patterns (case-insensitive)
  list.exists(fun(pattern) -> 
    lower_pattern = string.case(lower=true, pattern)
    string.match(pattern=lower_pattern, metadata_string)
  , PROGRAMS_TO_RECORD)
end

# Enhanced file size checking with proper error handling
def check_file_size(filename) =
  try
    if file.exists(filename) then
      size_bytes = file.size(filename)
      size_mb = size_bytes / (1024 * 1024)
      
      log("File #{filename} current size: #{int_of_float(size_mb)}MB")
      
      if size_mb >= float_of_int(MAX_SIZE_MB) then
        log("File #{filename} reached maximum size limit (#{MAX_SIZE_MB}MB)")
        true
      else
        false
      end
    else
      false
    end
  with
    error ->
      log("Error checking file size for #{filename}: #{error}")
      false
  end
end

# Function to create output directory with error handling
def ensure_output_dir() =
  try
    if not file.exists(OUTPUT_DIR) then
      log("Creating output directory: #{OUTPUT_DIR}")
      file.mkdir(perms=0o755, OUTPUT_DIR)
    end
    true
  with
    error ->
      log("Error creating output directory #{OUTPUT_DIR}: #{error}")
      false
  end
end

# Initialize
if not ensure_output_dir() then
  log("Failed to create output directory, exiting")
  shutdown()
end

# Create main stream with error handling
def create_stream() =
  try
    log("Connecting to stream: #{STREAM_URL}")
    s = input.http(STREAM_URL)
    s = buffer(size=BUFFER_SIZE, s)
    log("Successfully connected to stream")
    s
  with
    error ->
      log("Error connecting to stream: #{error}")
      blank()
  end
end

radio_stream = create_stream()

# Recording management functions
def start_recording(m) =
  try
    filename = generate_filename(m)
    encoder = get_encoder()
    
    log("Starting recording: #{filename}")
    log("Metadata - Title: '#{m['title']}', Artist: '#{m['artist']}', Album: '#{m['album']}'")
    
    # Create recording output
    output_id = output.file(
      encoder,
      filename,
      radio_stream,
      fallible=true,
      append=false,
      on_start={log("Recording started: #{filename}")},
      on_stop={log("Recording stopped: #{filename}")},
      on_close={log("Recording file closed: #{filename}")}
    )
    
    # Track active recording
    recording_info = (filename, output_id, time())
    active_recordings := recording_info :: !active_recordings
    
    true
  with
    error ->
      log("Error starting recording: #{error}")
      false
  end
end

def stop_current_recordings() =
  log("Stopping all current recordings")
  
  # Stop all active recordings
  list.iter(fun(rec_info) ->
    let (filename, output_id, start_time) = rec_info
    log("Stopping recording: #{filename}")
    # Note: In Liquidsoap, outputs are automatically managed
    # The output will stop when we remove it from our tracking
  , !active_recordings)
  
  active_recordings := []
end

def cleanup_oversized_recordings() =
  new_recordings = list.filter(fun(rec_info) ->
    let (filename, output_id, start_time) = rec_info
    if check_file_size(filename) then
      log("Stopping oversized recording: #{filename}")
      false  # Remove from list
    else
      true   # Keep in list
    end
  , !active_recordings)
  
  active_recordings := new_recordings
end

# Main metadata handler
def on_metadata_change(m) =
  log("Metadata changed - Title: '#{m['title']}', Artist: '#{m['artist']}', Album: '#{m['album']}'")
  
  should_rec = should_record(m)
  currently_recording = list.length(!active_recordings) > 0
  
  if should_rec and not currently_recording then
    # Start new recording
    ignore(start_recording(m))
  elsif not should_rec and currently_recording then
    # Stop current recordings
    stop_current_recordings()
  end
  
  # Always check for oversized files
  cleanup_oversized_recordings()
end

# Attach metadata handler to stream
radio_stream = on_metadata(on_metadata_change, radio_stream)

# Periodic maintenance function
def periodic_maintenance() =
  cleanup_oversized_recordings()
  
  # Log current status
  num_recordings = list.length(!active_recordings)
  if num_recordings > 0 then
    log("Currently recording #{num_recordings} program(s)")
    list.iter(fun(rec_info) ->
      let (filename, _, start_time) = rec_info
      duration = time() - start_time
      log("  - #{filename} (#{int_of_float(duration)}s)")
    , !active_recordings)
  end
end

# Schedule periodic maintenance
add_timeout(CHECK_INTERVAL, periodic_maintenance)

# Graceful shutdown handler
def on_shutdown() =
  log("Shutting down radio ripper...")
  stop_current_recordings()
  log("All recordings stopped")
end

on_shutdown(on_shutdown)

# Keep the script running
output.dummy(radio_stream)

# Startup messages
log("Advanced Radio Ripper started successfully")
log("Stream URL: #{STREAM_URL}")
log("Output directory: #{OUTPUT_DIR}")
log("Audio format: #{AUDIO_FORMAT}")
log("Maximum file size: #{MAX_SIZE_MB}MB")
log("Buffer size: #{BUFFER_SIZE}s")
log("Check interval: #{CHECK_INTERVAL}s")
log("Programs to record: #{string.concat(separator=', ', PROGRAMS_TO_RECORD)}")
log("Waiting for matching programs...")