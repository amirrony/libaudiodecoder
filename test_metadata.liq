#!/usr/bin/liquidsoap

# Metadata Test Script
# Use this to monitor stream metadata and test your recording patterns

# Load configuration
%include "radio_ripper_config.liq"

# Set up logging
set("log.level", 4)  # Debug level for detailed output
set("log.stdout", true)

# Test function to check if metadata would trigger recording
def test_should_record(m) =
  title = string.case(lower=true, m["title"])
  artist = string.case(lower=true, m["artist"])
  album = string.case(lower=true, m["album"])
  
  metadata_string = "#{title} #{artist} #{album}"
  
  # Check each pattern individually for detailed feedback
  matching_patterns = list.filter(fun(pattern) -> 
    lower_pattern = string.case(lower=true, pattern)
    string.match(pattern=lower_pattern, metadata_string)
  , PROGRAMS_TO_RECORD)
  
  (list.length(matching_patterns) > 0, matching_patterns)
end

# Metadata monitor function
def on_metadata_test(m) =
  print("=" * 60)
  print("METADATA RECEIVED:")
  print("  Title:  '#{m['title']}'")
  print("  Artist: '#{m['artist']}'")
  print("  Album:  '#{m['album']}'")
  print("")
  
  let (would_record, matching_patterns) = test_should_record(m)
  
  if would_record then
    print("✅ WOULD RECORD - Matching patterns:")
    list.iter(fun(pattern) -> print("    - #{pattern}"), matching_patterns)
    
    # Show what filename would be generated
    title = m["title"]
    clean_title = string.replace(pattern="[^a-zA-Z0-9_-]", fun(_) -> "_", title)
    time_info = time()
    timestamp = string.format("%04d%02d%02d_%02d%02d", 
      time_info.year, time_info.month, time_info.mday, 
      time_info.hour, time_info.min)
    filename = "#{clean_title}_#{timestamp}.#{AUDIO_FORMAT}"
    print("    Filename: #{filename}")
  else
    print("❌ WOULD NOT RECORD - No matching patterns")
  end
  
  print("")
  print("Tested patterns:")
  list.iter(fun(pattern) -> print("  - #{pattern}"), PROGRAMS_TO_RECORD)
  print("=" * 60)
  print("")
end

# Connect to stream
print("Connecting to stream: #{STREAM_URL}")
print("Monitoring metadata for pattern matching...")
print("Press Ctrl+C to stop")
print("")

try
  stream = input.http(STREAM_URL)
  stream = on_metadata(on_metadata_test, stream)
  output.dummy(stream)
with
  error ->
    print("Error connecting to stream: #{error}")
    print("Please check your STREAM_URL in radio_ripper_config.liq")
end