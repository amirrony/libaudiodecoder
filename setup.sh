#!/bin/bash

# Radio Ripper Setup Script

echo "Radio Program Ripper Setup"
echo "=========================="
echo

# Check if liquidsoap is installed
if ! command -v liquidsoap &> /dev/null; then
    echo "❌ Liquidsoap is not installed."
    echo "Please install it first:"
    echo "  Ubuntu/Debian: sudo apt install liquidsoap"
    echo "  macOS: brew install liquidsoap"
    echo
    exit 1
else
    echo "✅ Liquidsoap found: $(liquidsoap --version | head -1)"
fi

# Make scripts executable
chmod +x *.liq
echo "✅ Made scripts executable"

# Create default recordings directory
mkdir -p /tmp/recordings
echo "✅ Created default recordings directory: /tmp/recordings"

# Show next steps
echo
echo "Setup complete! Next steps:"
echo "1. Edit radio_ripper_config.liq with your stream URL and preferences"
echo "2. Test your patterns: ./test_metadata.liq"
echo "3. Run the ripper: ./radio_ripper_advanced.liq"
echo
echo "Files created:"
echo "  - radio_ripper.liq (basic version)"
echo "  - radio_ripper_advanced.liq (recommended)"
echo "  - radio_ripper_config.liq (configuration)"
echo "  - test_metadata.liq (for testing patterns)"
echo "  - RADIO_RIPPER_README.md (documentation)"
echo
echo "For detailed instructions, see RADIO_RIPPER_README.md"