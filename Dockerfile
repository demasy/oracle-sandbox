# Stage 1: Build Stage
FROM node:20-bookworm-slim AS sandbox-builder

# Add robust retry logic for apt-get to handle transient network failures
# Use -o options for trusted repositories and allow unauthenticated packages
RUN apt-get update -o Acquire::AllowDownsideGradedSecurityCertificates=true -o Acquire::Retries=5 || true && \
  apt-get install -y -o Acquire::AllowDownsideGradedSecurityCertificates=true -o APT::Get::AllowUnauthenticated=true -o Acquire::Retries=5 ca-certificates && \
  apt-get update && \
  apt-get upgrade -y -o Acquire::Retries=5 && \
  apt-get install -y --no-install-recommends -o Acquire::Retries=5 curl unzip && \
  rm -rf /var/lib/apt/lists/*

ARG SRC_ORACLE_SQLCL
ARG SRC_ORACLE_APEX
ARG INSTALL_APEX
ENV SRC_ORACLE_SQLCL=$SRC_ORACLE_SQLCL
ENV SRC_ORACLE_APEX=$SRC_ORACLE_APEX
ENV INSTALL_APEX=$INSTALL_APEX

RUN mkdir -p /usr/sandbox/app/cli
RUN mkdir -p /usr/sandbox/app/system/utils
RUN mkdir -p /usr/sandbox/app/system/build
RUN mkdir -p /usr/sandbox/app/system/admin
RUN mkdir -p /usr/sandbox/app/system/download
RUN mkdir -p /usr/sandbox/app/system/install
RUN mkdir -p /usr/sandbox/app/oracle/admin
RUN mkdir -p /usr/sandbox/app/oracle/apex
RUN mkdir -p /usr/sandbox/app/oracle/mcp
RUN mkdir -p /usr/sandbox/app/oracle/sqlcl
RUN mkdir -p /usr/sandbox/app/oracle/sqlplus

COPY package*.json ./

WORKDIR /usr/sandbox/app

COPY ./app.js ./app.js
COPY ["LICENSE", "./"]

# Copy scripts to organized structure
COPY ./src/builder/scripts/cli/*.sh                 /usr/sandbox/app/cli/
COPY ./src/builder/scripts/cli/sandbox-completion.bash /usr/sandbox/app/cli/
COPY ./src/builder/scripts/cli/sandbox-completion.zsh  /usr/sandbox/app/cli/
COPY ./src/builder/scripts/system/utils/*.sh        /usr/sandbox/app/system/utils/
COPY ./src/builder/scripts/system/build/*.sh        /usr/sandbox/app/system/build/
COPY ./src/builder/scripts/system/admin/*.sh        /usr/sandbox/app/system/admin/
COPY ./src/builder/scripts/system/download/*.sh     /usr/sandbox/app/system/download/
COPY ./src/builder/scripts/system/install/*.sh      /usr/sandbox/app/system/install/
COPY ./src/builder/scripts/oracle/admin/ddl/*.sh    /usr/sandbox/app/oracle/admin/ddl/
COPY ./src/builder/scripts/oracle/admin/utils/*.sh  /usr/sandbox/app/oracle/admin/utils/
COPY ./src/builder/scripts/oracle/admin/config/*.yaml /usr/sandbox/app/oracle/admin/config/
COPY ./src/builder/scripts/oracle/admin/monitoring/*.sql /usr/sandbox/app/oracle/admin/monitoring/
COPY ./src/builder/scripts/oracle/apex/*.sh         /usr/sandbox/app/oracle/apex/
COPY ./src/builder/scripts/oracle/mcp/*.sh          /usr/sandbox/app/oracle/mcp/
COPY ./src/builder/scripts/oracle/sqlcl/*.sh        /usr/sandbox/app/oracle/sqlcl/
COPY ./src/builder/scripts/oracle/sqlplus/*.sh      /usr/sandbox/app/oracle/sqlplus/

# Set permissions for all scripts (recursively find all .sh files)
RUN find /usr/sandbox/app -type f -name '*.sh' -exec chmod +x {} \;

WORKDIR /usr/sandbox/app
RUN mkdir -p /opt/oracle

# Install Oracle components (Instant Client + SQLcl)
ENV TERM=xterm-256color
RUN /usr/sandbox/app/system/build/builder-startup.sh

# Fix terminal for interactive docker exec sessions (suppresses "(arg: N)" noise
# caused by macOS terminal sending bracketed-paste sequences on attach)
RUN echo '' >> /root/.bashrc \
 && echo '[ -z "$TERM" ] || [ "$TERM" = "dumb" ] && export TERM=xterm-256color' >> /root/.bashrc \
 && echo 'bind "set enable-bracketed-paste off" 2>/dev/null || true' >> /root/.bashrc

# Download APEX and ORDS using download-apex.sh script (conditional)
RUN if [ "$INSTALL_APEX" = "true" ]; then \
      /usr/sandbox/app/system/download/download-apex.sh; \
    else \
      echo "Skipping APEX/ORDS download (INSTALL_APEX=$INSTALL_APEX)"; \
    fi

FROM node:20-bookworm-slim

RUN apt-get update -o Acquire::AllowDownsideGradedSecurityCertificates=true -o Acquire::Retries=5 || true && \
  apt-get install -y -o Acquire::AllowDownsideGradedSecurityCertificates=true -o APT::Get::AllowUnauthenticated=true -o Acquire::Retries=5 ca-certificates && \
  apt-get update && \
  apt-get upgrade -y -o Acquire::Retries=5 && \
  apt-get install -y --no-install-recommends -o Acquire::Retries=5 \
  curl \
  unzip \
  libaio1 \
  openjdk-17-jdk \
  bash \
  iputils-ping \
  vim \
  nano \
  lsof \
  telnet \
  tcpdump \
  net-tools \
  procps \
  htop \
  jq \
  openssl \
  && rm -rf /var/lib/apt/lists/*

# Find and set Java home dynamically for both AMD64 and ARM64
RUN JAVA_HOME_CANDIDATE=$(find /usr/lib/jvm -name "java-17-openjdk*" -type d | head -1) && \
    echo "Found Java at: $JAVA_HOME_CANDIDATE" && \
    echo "export JAVA_HOME=$JAVA_HOME_CANDIDATE" >> /etc/environment && \
    echo "export PATH=\$JAVA_HOME/bin:\$PATH" >> /etc/environment

# Set JAVA_HOME dynamically based on architecture
ENV JAVA_HOME_DYNAMIC=/usr/lib/jvm/java-17-openjdk-arm64
ENV CLASSPATH="/opt/oracle/sqlcl/lib/*"
ENV HOST=0.0.0.0
ENV PATH="/usr/sandbox/app/bin:${PATH}"

# Pass build argument to runtime environment
ARG INSTALL_APEX
ENV INSTALL_APEX=${INSTALL_APEX}

COPY --from=sandbox-builder package*.json ./
COPY --from=sandbox-builder /usr/sandbox/app /usr/sandbox/app
COPY --from=sandbox-builder /opt/oracle /opt/oracle

RUN npm install oracledb --build-from-source --unsafe-perm

# Set permissions for all scripts in runtime stage (recursively find all .sh files)
RUN find /usr/sandbox/app -type f -name '*.sh' -exec chmod +x {} \;

RUN /usr/sandbox/app/system/admin/setup.sh

EXPOSE 3000
EXPOSE 3001

HEALTHCHECK --interval=30s --timeout=5s --start-period=10s --retries=3 \
  CMD curl -f http://localhost:3000/health || exit 1

WORKDIR /usr/sandbox/app

USER sandbox

# Use startup script to handle initialization
CMD ["/usr/sandbox/app/system/build/startup.sh"]
