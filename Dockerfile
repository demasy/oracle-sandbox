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
  lsof && \
  rm -rf /var/lib/apt/lists/*
 
ENV JAVA_HOME=/usr/lib/jvm/java-17-openjdk-amd64
ENV PATH="$JAVA_HOME/bin:$PATH"
ENV CLASSPATH="/opt/oracle/sqlcl/lib/*"

COPY --from=demasylabs-builder package*.json ./
COPY --from=demasylabs-builder /usr/demasy /usr/demasy
COPY --from=demasylabs-builder /opt/oracle /opt/oracle

RUN npm install oracledb --build-from-source --unsafe-perm

RUN chmod +x /usr/demasy/scripts/connect.sh
 
RUN ln -s /opt/oracle/sqlcl/bin/sql /usr/local/bin/sql
RUN ln -s /usr/demasy/scripts/connect.sh /usr/local/bin/sqlcl
RUN ln -s /usr/demasy/scripts/connect.sh /usr/local/bin/oracle

EXPOSE 3000

HEALTHCHECK --interval=30s --timeout=5s --start-period=10s --retries=3 \
  CMD curl -f http://localhost:3000/health || exit 1

WORKDIR /usr/demasy/app

CMD ["node", "app.js"]