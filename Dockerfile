FROM ubuntu:xenial

ENV DEBIAN_FRONTEND=noninteractive \
    TERM=xterm

ENV NODEJS_VERSION=12.15.0 \
    IONIC_VERSION=6.0.1 \
    ANGULAR_VERSION=9.0.1 \
    GRADLE_VERSION=6.5.1 \
    ANDROID_BUILD_TOOLS_VERSION=29.0.0 \
    ANDROID_APIS="android-29"

ENV ANDROID_SDK_URL="https://dl.google.com/android/repository/sdk-tools-linux-4333796.zip" \
    ANT_HOME="/usr/share/ant" \
    MAVEN_HOME="/usr/share/maven" \
    GRADLE_HOME="/usr/share/gradle-$GRADLE_VERSION" \
    ANDROID_HOME="/opt/android"

ARG BUILD_DATE
ARG BUILD_VERSION
ARG VCS_REF

LABEL maintainer="Profiz<contato@profiz.com>" \
  org.label-schema.build-date=$BUILD_DATE \
  org.label-schema.version=$BUILD_VERSION \
  org.label-schema.vcs-ref=$VCS_REF \
  org.label-schema.schema-version="1.0.0-rc1" \
  org.label-schema.vcs-url="https://github.com/profiz/docker-ionic.git" \
  org.label-schema.name="profiz/ionic" \
  org.label-schema.vendor="Profiz" \
  org.label-schema.description="Docker image used to build Ionic applications in Profiz"

# Global Dependencies
RUN buildDeps='software-properties-common'; \
  set -x && \
  apt-get update && apt-get upgrade -y && apt-get install -y $buildDeps --no-install-recommends && \
  apt-get update -y && \
  apt-get install -y curl git ca-certificates bzip2 openssh-client wget unzip --no-install-recommends

# Java/JDK
RUN add-apt-repository ppa:openjdk-r/ppa -y && \
  apt-get install -y openjdk-8-jdk && \
  java -version

ENV JAVA_HOME=/usr/lib/jvm/java-8-openjdk-amd64
ENV PATH=$PATH:$JAVA_HOME

# Android
WORKDIR /opt

ENV PATH=$PATH:$ANDROID_HOME/tools:$ANDROID_HOME/platform-tools:$ANDROID_HOME/build-tools/$ANDROID_BUILD_TOOLS_VERSION:$ANT_HOME/bin:$MAVEN_HOME/bin:$GRADLE_HOME/bin

RUN dpkg --add-architecture i386

RUN apt-get install -y maven ant

RUN mkdir $GRADLE_HOME
RUN wget -P $GRADLE_HOME/.. https://services.gradle.org/distributions/gradle-$GRADLE_VERSION-bin.zip
RUN unzip -d $GRADLE_HOME/.. $GRADLE_HOME/../gradle-$GRADLE_VERSION-bin.zip

RUN mkdir $ANDROID_HOME && cd $ANDROID_HOME && \
    wget -O android.zip ${ANDROID_SDK_URL} && \
    unzip android.zip && rm android.zip

RUN chmod a+x -R $ANDROID_HOME && \
    chown -R root:root $ANDROID_HOME && \
    echo y | android update sdk -a -u -t --use-sdk-wrapper platform-tools,${ANDROID_APIS},build-tools-${ANDROID_BUILD_TOOLS_VERSION}

# NodeJS
WORKDIR /opt/node
RUN curl -sL https://nodejs.org/dist/v${NODEJS_VERSION}/node-v${NODEJS_VERSION}-linux-x64.tar.gz | tar xz --strip-components=1
ENV NODE_HOME=/opt/node/bin
ENV PATH=$PATH:$NODE_HOME

# Python
WORKDIR /tmp
RUN apt-get install python3-pip -y

# Ionic
RUN apt-get install -y && \
    npm i -g --unsafe-perm @ionic/cli@${IONIC_VERSION} && \
    ionic --no-interactive config set -g daemon.updates false

# Angular
RUN npm i -g --unsafe-perm @angular/cli@${ANGULAR_VERSION}
RUN ng analytics off

# Clean
RUN rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* && \
  apt-get autoremove -y && apt-get clean