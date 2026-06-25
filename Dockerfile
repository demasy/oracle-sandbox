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

ARG SANDBOX_APP=/usr/sandbox/app
ARG SANDBOX_SYSTEM=${SANDBOX_APP}/system
ARG SANDBOX_ORACLE=${SANDBOX_APP}/oracle
ENV SANDBOX_APP=$SANDBOX_APP
ENV SANDBOX_SYSTEM=$SANDBOX_SYSTEM
ENV SANDBOX_ORACLE=$SANDBOX_ORACLE

ARG SRC_ORACLE_SQLCL
ARG SRC_ORACLE_APEX
ARG INSTALL_APEX
ENV SRC_ORACLE_SQLCL=$SRC_ORACLE_SQLCL
ENV SRC_ORACLE_APEX=$SRC_ORACLE_APEX
ENV INSTALL_APEX=$INSTALL_APEX

RUN mkdir -p ${SANDBOX_SYSTEM}/cli
RUN mkdir -p ${SANDBOX_SYSTEM}/utils
RUN mkdir -p ${SANDBOX_SYSTEM}/build
RUN mkdir -p ${SANDBOX_SYSTEM}/admin
RUN mkdir -p ${SANDBOX_SYSTEM}/setup
RUN mkdir -p ${SANDBOX_APP}/download
RUN mkdir -p ${SANDBOX_APP}/install/oracle
RUN mkdir -p ${SANDBOX_ORACLE}/admin
RUN mkdir -p ${SANDBOX_ORACLE}/apex
RUN mkdir -p ${SANDBOX_ORACLE}/mcp
RUN mkdir -p ${SANDBOX_ORACLE}/sqlcl
RUN mkdir -p ${SANDBOX_ORACLE}/sqlplus

COPY package*.json ./

WORKDIR ${SANDBOX_APP}

COPY ./app.js ./app.js
COPY ["LICENSE", "./"]


# Copy scripts to organized structure
COPY ./src/builder/system/cli/*.sh                       ${SANDBOX_SYSTEM}/cli/
COPY ./src/builder/system/cli/sandbox-completion.bash    ${SANDBOX_SYSTEM}/cli/
COPY ./src/builder/system/cli/sandbox-completion.zsh     ${SANDBOX_SYSTEM}/cli/
COPY ./src/builder/system/utils/*.sh                     ${SANDBOX_SYSTEM}/utils/
COPY ./src/builder/system/build/*.sh                     ${SANDBOX_SYSTEM}/build/
COPY ./src/builder/system/setup/*.sh                     ${SANDBOX_SYSTEM}/setup/

COPY ./src/builder/scripts/download/*.sh                 ${SANDBOX_APP}/download/
COPY ./src/builder/scripts/install/oracle/*.sh           ${SANDBOX_APP}/install/oracle/

COPY ./src/builder/scripts/oracle/admin/ddl/*.sh         ${SANDBOX_ORACLE}/admin/ddl/
COPY ./src/builder/scripts/oracle/admin/utils/*.sh       ${SANDBOX_ORACLE}/admin/utils/
COPY ./src/builder/scripts/oracle/admin/config/*.yaml    ${SANDBOX_ORACLE}/admin/config/
COPY ./src/builder/scripts/oracle/admin/monitoring/*.sql ${SANDBOX_ORACLE}/admin/monitoring/
COPY ./src/builder/scripts/oracle/apex/*.sh              ${SANDBOX_ORACLE}/apex/
COPY ./src/builder/scripts/oracle/mcp/*.sh               ${SANDBOX_ORACLE}/mcp/
COPY ./src/builder/scripts/oracle/sqlcl/*.sh             ${SANDBOX_ORACLE}/sqlcl/
COPY ./src/builder/scripts/oracle/sqlplus/*.sh           ${SANDBOX_ORACLE}/sqlplus/

# Set permissions for all scripts (recursively find all .sh files)
RUN find ${SANDBOX_APP} -type f -name '*.sh' -exec chmod +x {} \;

WORKDIR ${SANDBOX_APP}
RUN mkdir -p /opt/oracle

# Install Oracle components (Instant Client + SQLcl)
ENV TERM=xterm-256color
RUN ${SANDBOX_APP}/system/build/builder-startup.sh

# Fix terminal for interactive docker exec sessions (suppresses "(arg: N)" noise
# caused by macOS terminal sending bracketed-paste sequences on attach)
RUN echo '' >> /root/.bashrc \
  && echo '[ -z "$TERM" ] || [ "$TERM" = "dumb" ] && export TERM=xterm-256color' >> /root/.bashrc \
  && echo 'bind "set enable-bracketed-paste off" 2>/dev/null || true' >> /root/.bashrc

# Download APEX and ORDS using download-apex.sh script (conditional)
RUN if [ "$INSTALL_APEX" = "true" ]; then \
  ${SANDBOX_APP}/download/download-apex.sh; \
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
ARG SANDBOX_APP=/usr/sandbox/app
ARG SANDBOX_SYSTEM=${SANDBOX_APP}/system
ARG SANDBOX_ORACLE=${SANDBOX_APP}/oracle
ARG INSTALL_APEX
ENV INSTALL_APEX=${INSTALL_APEX}

COPY --from=sandbox-builder package*.json ./
COPY --from=sandbox-builder ${SANDBOX_APP} ${SANDBOX_APP}
COPY --from=sandbox-builder /opt/oracle /opt/oracle

RUN npm install oracledb --build-from-source --unsafe-perm

# Set permissions for all scripts in runtime stage (recursively find all .sh files)
RUN find ${SANDBOX_APP} -type f -name '*.sh' -exec chmod +x {} \;

RUN ${SANDBOX_SYSTEM}/setup/run.sh

EXPOSE 3000
EXPOSE 3001

HEALTHCHECK --interval=30s --timeout=5s --start-period=10s --retries=3 \
  CMD curl -f http://localhost:3000/health || exit 1

WORKDIR ${SANDBOX_APP}

USER sandbox

# Use startup script to handle initialization
CMD ["/usr/sandbox/app/system/build/startup.sh"]
