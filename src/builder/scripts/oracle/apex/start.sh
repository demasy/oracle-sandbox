#!/bin/bash
################################################################################
# Start Oracle APEX/ORDS
################################################################################

echo "🚀 Starting Oracle APEX/ORDS..."

# Check if ORDS is already running
if pidof -x '/opt/oracle/ords/bin/ords' > /dev/null 2>&1; then
    echo "ℹ️  ORDS is already running"
    exit 0
fi

# Verify ORDS binary exists
if [ ! -f /opt/oracle/ords/bin/ords ]; then
    echo "❌ Error: ORDS binary not found at /opt/oracle/ords/bin/ords"
    exit 1
fi

# Start ORDS in background (auto-discovers config in /opt/oracle/ords/config)
echo "Starting ORDS in background..."
cd /opt/oracle/ords/config 2>/dev/null || cd /opt/oracle/ords
/opt/oracle/ords/bin/ords serve --port 8080 > /var/log/ords.log 2>&1 &

# Wait for ORDS to start
sleep 5

# Verify ORDS is running
if pidof -x '/opt/oracle/ords/bin/ords' > /dev/null 2>&1; then
    echo "✅ Oracle APEX/ORDS started successfully"
    echo "🌐 ORDS available at: http://localhost:8080/ords/"
    exit 0
else
    echo "❌ Error: ORDS failed to start"
    echo "📋 Check logs: tail -50 /var/log/ords.log"
    tail -20 /var/log/ords.log
    exit 1
fi
