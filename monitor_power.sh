#!/bin/bash
echo "Monitoring power status... (Press Ctrl+C to stop)"
echo "Bit 0: Under-voltage detected"
echo "Bit 1: Arm frequency capped"
echo "Bit 2: Currently throttled"
echo "Bit 3: Soft temperature limit active"
echo "Bit 16: Under-voltage has occurred"
echo "Bit 17: Arm frequency capping has occurred"
echo "Bit 18: Throttling has occurred"
echo "Bit 19: Soft temperature limit has occurred"

while true; do
    vcgencmd get_throttled
    sleep 1
done
