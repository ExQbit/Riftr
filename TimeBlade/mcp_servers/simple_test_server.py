#!/usr/bin/env python3
import sys
import os
from datetime import datetime

LOG_FILE_PATH = "/Users/exqbitmac/TimeBlade/simple_test_launch.log"

# Ensure log file is writable and clear it
try:
    if os.path.exists(LOG_FILE_PATH):
        os.remove(LOG_FILE_PATH)
    with open(LOG_FILE_PATH, 'a') as f:
        f.write(f"Simple test server started at {datetime.now()}\n")
        f.write(f"Python Executable: {sys.executable}\n")
        f.write(f"Current Working Directory: {os.getcwd()}\n")
        f.write(f"Script __file__: {__file__}\n")
        f.write("Simple test server ran successfully.\n")
    # Simulate a server running for a bit then exiting for test purposes
    # In a real simple test, it might just exit. For MCP, it needs to keep running.
    # However, for this basic test, exiting is fine.
except Exception as e:
    # If we can't even write to the log, try to print to original stderr
    # though this might not be captured by the system either.
    print(f"SIMPLE TEST SERVER CRITICAL ERROR: {e}", file=sys.__stderr__)
    sys.exit(1)

sys.exit(0)
