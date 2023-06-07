ARG BASE_URL="https://github.com/slurmorg/build-containers-trusted/raw/main/"
ARG GPG_KEY_FILE="key.gpg"
ARG ROOTFS_FILE="rootfs.tar.gz"
ARG MAVEN_FILE="apache-maven-3.9.1-bin.tar.gz"
ARG TOMCAT_FILE="apache-tomcat-10.1.7.tar.gz"

# FILE URLS
ARG GPG_KEY_URL="$BASE_URL/$GPG_KEY_FILE"
ARG ROOTFS_URL="$BASE_URL$ROOTFS_FILE"
ARG MAVEN_URL="$BASE_URL/$MAVEN_FILE"
ARG TOMCAT_URL="$BASE_URL/$TOMCAT_FILE"

# DIGEST URLS
ARG ROOTFS_DIGEST="$ROOTFS_URL.sha512"
ARG MAVEN_DIGEST="$MAVEN_URL.sha512"
ARG TOMCAT_DIGEST="$TOMCAT_URL.sha512"

# ASC URLS
ARG ROOTFS_ASC="$ROOTFS_DIGEST.asc"
ARG MAVEN_ASC="$MAVEN_DIGEST.asc"
ARG TOMCAT_ASC="$TOMCAT_DIGEST.asc"

FROM bellsoft/alpaquita-linux-gcc@sha256:21078034b252905a53809fa6407e5834a2e94f21ab6bd5de59d16f640c2f7338 as verifier
ARG BASE_URL
ARG GPG_KEY_FILE
ARG ROOTFS_FILE
ARG MAVEN_FILE
ARG TOMCAT_FILE

# FILE URLS
ARG GPG_KEY_URL
ARG ROOTFS_URL
ARG MAVEN_URL
ARG TOMCAT_URL

# DIGEST URLS
ARG ROOTFS_DIGEST
ARG MAVEN_DIGEST
ARG TOMCAT_DIGEST

# ASC URLS
ARG ROOTFS_ASC
ARG MAVEN_ASC
ARG TOMCAT_ASC

RUN apk --no-cache add gnupg

WORKDIR /app

RUN echo "$GPG_KEY_FILE"
RUN curl -LJO ${GPG_KEY_URL} --output ${GPG_KEY_FILE}
RUN curl -LJO $ROOTFS_URL --output $ROOTFS_FILE
RUN curl -LJO $MAVEN_URL --output $MAVEN_FILE
RUN curl -LJO $TOMCAT_URL --output $TOMCAT_FILE

RUN curl -LJO $ROOTFS_DIGEST --output "$ROOTFS_FILE.sha512"
RUN curl -LJO $MAVEN_DIGEST --output "$MAVEN_FILE.sha512"
RUN curl -LJO $TOMCAT_DIGEST --output "$TOMCAT_FILE.sha512"

RUN curl -LJO $ROOTFS_ASC --output "$ROOTFS_FILE.sha512.asc"
RUN curl -LJO $MAVEN_ASC --output "$MAVEN_FILE.sha512.asc"
RUN curl -LJO $TOMCAT_ASC --output "$TOMCAT_FILE.sha512.asc"

RUN set -eo pipefail
RUN gpg --dry-run --import --import-options import-show $GPG_KEY_FILE | grep 70092656FB28DBB76C3BB42E89619023B6601234
RUN gpg --import $GPG_KEY_FILE

RUN sha512sum -c $ROOTFS_FILE.sha512 || exit 1
RUN sha512sum -c $MAVEN_FILE.sha512 || exit 1
RUN sha512sum -c $TOMCAT_FILE.sha512 || exit 1

RUN gpg --verify $ROOTFS_FILE.sha512.asc || exit 1
RUN gpg --verify $MAVEN_FILE.sha512.asc || exit 1
RUN gpg --verify $TOMCAT_FILE.sha512.asc || exit 1

RUN mkdir rootfs && tar -zxf $ROOTFS_FILE -C rootfs
RUN mkdir maven  && tar -zxf $MAVEN_FILE  --strip-components=1 -C maven
RUN mkdir tomcat && tar -zxf $TOMCAT_FILE --strip-components=1 -C tomcat

FROM scratch as base

ENV LANG=en_US.UTF-8
ENV LANGUAGE=en_US.UTF-8:en
ENV JAVA_HOME=/usr/lib/jvm/jdk-17.0.6-bellsoft-x86_64

COPY --from=verifier /app/rootfs /

FROM base as builder

COPY --from=verifier  /app/maven /opt/bin/maven

RUN ls /opt/bin/maven
ENV PATH=/usr/lib/jvm/jdk-17.0.6-bellsoft-x86_64/bin:/opt/bin/maven/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
ENV MAVEN_HOME=/opt/bin/maven

WORKDIR /app
COPY pom.xml .
COPY src src
RUN mvn verify

FROM base as final

ENV CATALINA_HOME=/opt/bin/tomcat

COPY --from=verifier /app/tomcat /opt/bin/tomcat
RUN rm -rf $CATALINA_HOME/webapps/manager/ ; rm -rf $CATALINA_HOME/webapps/examples/ ; rm -rf $CATALINA_HOME/webapps/host-manager/ ; rm -rf $CATALINA_HOME/webapps/ROOT/
COPY --from=builder /app/target/api.war /opt/bin/tomcat/webapps/ROOT.war

ENV PATH=/usr/lib/jvm/jdk-17.0.6-bellsoft-x86_64/bin:/opt/bin/tomcat/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin

RUN ls -l /opt/bin/tomcat/webapps

EXPOSE 8080

CMD ["catalina.sh", "run"]