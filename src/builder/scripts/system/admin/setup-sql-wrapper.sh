#!/bin/bash
# setup-sql-wrapper.sh — Write the /usr/local/bin/sql entry point for SQLcl.
# Detects JAVA_HOME at runtime via readlink so the same wrapper works on both
# AMD64 and ARM64 without hardcoding an architecture-specific JVM path.

cat > /usr/local/bin/sql << 'EOF'
#!/bin/bash
export LD_LIBRARY_PATH=/opt/oracle/instantclient:$LD_LIBRARY_PATH
DETECTED_JAVA_HOME=$(readlink -f /usr/bin/java | sed "s:/bin/java::")
export JAVA_HOME="$DETECTED_JAVA_HOME"
export PATH="$JAVA_HOME/bin:$PATH"
cd /opt/oracle/sqlcl/bin && exec ./sql "$@"
EOF

chmod +x /usr/local/bin/sql
