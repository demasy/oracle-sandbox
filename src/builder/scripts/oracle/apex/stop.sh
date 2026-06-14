#!/bin/bash
################################################################################
# Stop Oracle APEX/ORDS
################################################################################

echo "🛑 Stopping Oracle APEX/ORDS..."

# Check if ORDS is running
if ! pidof -x '/opt/oracle/ords/bin/ords' > /dev/null 2>&1; then
    echo "ℹ️  ORDS is not currently running"
    exit 0
fi

# Kill ORDS process
echo "Terminating ORDS process..."
ORDS_PID=$(pidof -x '/opt/oracle/ords/bin/ords' | awk '{print $1}')
if [ -n "$ORDS_PID" ]; then
    kill $ORDS_PID
    sleep 2
    # Verify termination
    if kill -0 $ORDS_PID 2>/dev/null; then
        echo "⚠️  Force killing ORDS..."
        kill -9 $ORDS_PID
    fi
fi

echo "✅ Oracle APEX/ORDS stopped successfully"
