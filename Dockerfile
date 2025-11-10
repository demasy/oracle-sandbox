# Stage 1: Build Stage
FROM node:20.19.4-slim AS demasylabs-builder

RUN apt-get update && \
  apt-get install -y --no-install-recommends curl unzip ca-certificates && \
  rm -rf /var/lib/apt/lists/*

ARG SRC_ORACLE_SQLCL
ENV SRC_ORACLE_SQLCL=$SRC_ORACLE_SQLCL

RUN mkdir -p /usr/demasy/app

COPY package*.json ./

WORKDIR /usr/demasy/app

COPY ./app.js ./app.js
COPY ./src ./src
COPY ["LICENSE", "./"]

COPY ./libs/oracle/clients/instantclient_23_7 /opt/oracle/instantclient

RUN mkdir -p /usr/demasy/scripts && \
  curl -L -o /usr/demasy/scripts/connect.sh https://gist.githubusercontent.com/demasy/e913cdc3bf9897bc0374543d416d4d2d/raw/oracle-sqlcl-connect.sh && \
  chmod +x /usr/demasy/scripts/connect.sh

COPY ./src/scripts/diagnostics/healthcheck.sh /usr/demasy/admin/scripts/healthcheck.sh

RUN chmod +x /usr/demasy/admin/scripts/healthcheck.sh

WORKDIR /usr/demasy/scripts

RUN curl -L -o sqlcl.zip "$SRC_ORACLE_SQLCL" && \
  unzip sqlcl.zip -d /opt/oracle && \
  rm sqlcl.zip

FROM node:20.19.4-slim

RUN apt-get update && \
  apt-get upgrade -y && \
  apt-get install -y --no-install-recommends \
  curl \
  unzip \
  libaio1 \
  openjdk-17-jdk \
  ca-certificates \
  bash \
  iputils-ping \
  vim \
  nano \
  lsof \
  telnet \
  tcpdump \
  net-tools \
  htop \
  jq \
  openssl \
  && npm install -g nodemon && \
  rm -rf /var/lib/apt/lists/*

# Find and set Java home dynamically for both AMD64 and ARM64
RUN JAVA_HOME_CANDIDATE=$(find /usr/lib/jvm -name "java-17-openjdk*" -type d | head -1) && \
    echo "Found Java at: $JAVA_HOME_CANDIDATE" && \
    echo "export JAVA_HOME=$JAVA_HOME_CANDIDATE" >> /etc/environment && \
    echo "export PATH=\$JAVA_HOME/bin:\$PATH" >> /etc/environment

# Set JAVA_HOME dynamically based on architecture
ENV JAVA_HOME_DYNAMIC=/usr/lib/jvm/java-17-openjdk-arm64
ENV CLASSPATH="/opt/oracle/sqlcl/lib/*"

COPY --from=demasylabs-builder package*.json ./
COPY --from=demasylabs-builder /usr/demasy /usr/demasy
COPY --from=demasylabs-builder /opt/oracle /opt/oracle

RUN npm install oracledb --build-from-source --unsafe-perm

RUN chmod +x /usr/demasy/scripts/connect.sh
RUN chmod +x /usr/demasy/admin/scripts/healthcheck.sh

# Create symbolic links to Oracle tools and scripts
RUN ln -s /opt/oracle/instantclient/sqlplus /usr/local/bin/sqlplus

# Create a wrapper for SQLcl that detects Java path dynamically for any architecture
RUN echo '#!/bin/bash' > /usr/local/bin/sql && \
    echo 'export LD_LIBRARY_PATH=/opt/oracle/instantclient:$LD_LIBRARY_PATH' >> /usr/local/bin/sql && \
    echo 'DETECTED_JAVA_HOME=$(readlink -f /usr/bin/java | sed "s:/bin/java::")' >> /usr/local/bin/sql && \
    echo 'export JAVA_HOME="$DETECTED_JAVA_HOME"' >> /usr/local/bin/sql && \
    echo 'export PATH="$JAVA_HOME/bin:$PATH"' >> /usr/local/bin/sql && \
    echo 'cd /opt/oracle/sqlcl/bin && exec ./sql "$@"' >> /usr/local/bin/sql && \
    chmod +x /usr/local/bin/sql

RUN ln -s /usr/demasy/scripts/connect.sh /usr/local/bin/sqlcl
RUN ln -s /usr/demasy/scripts/connect.sh /usr/local/bin/oracle
RUN ln -s /usr/demasy/admin/scripts/healthcheck.sh /usr/local/bin/healthcheck

# Verify installation and test SQLcl
RUN echo "Testing Java installation..." && \
    java -version && \
    DETECTED_JAVA_HOME=$(readlink -f /usr/bin/java | sed 's:/bin/java::') && \
    echo "Detected Java home: $DETECTED_JAVA_HOME" && \
    echo "Testing SQLcl..." && \
    cd /opt/oracle/sqlcl/bin && \
    JAVA_HOME="$DETECTED_JAVA_HOME" ./sql -version

EXPOSE 3000

HEALTHCHECK --interval=30s --timeout=5s --start-period=10s --retries=3 \
  CMD curl -f http://localhost:3000/health || exit 1

WORKDIR /usr/demasy/app

CMD ["node", "app.js"]