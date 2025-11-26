#!/bin/bash
################################################################################
# Setup Saved SQLcl Connection for MCP
# Creates the demasylabs-ai-conn saved connection with credentials
################################################################################

echo "Setting up saved SQLcl connection..."

# Remove old connection data if exists
rm -f /root/.sqlcl/connections.json 2>/dev/null

# Create the saved connection
/opt/oracle/sqlcl/bin/sql /nolog <<EOSQL
CONNECT demasylabs_ai/Demasy1986@//192.168.1.110:1521/FREEPDB1
CONN -save demasylabs-ai-conn -savepwd
EXIT
EOSQL

echo "Saved connection 'demasylabs-ai-conn' created successfully"