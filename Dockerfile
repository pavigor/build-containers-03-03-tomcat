ARG BASE_URL="https://github.com/slurmorg/build-containers-trusted/blob/main/"
ARG GPG_KEY_FILE="key.gpg"
ARG ROOTFS_FILE="rootfs.tar.gz"
ARG MAVEN_FILE="apache-maven-3.9.1-bin.tar.gz"
ARG TOMCAT_FILE="apache-tomcat-10.1.7.tar.gz"

# FILE URLS
ARG GPG_KEY_URL="$BASE_URL/$GPG_KEY_FILE"
ARG ROOTFS_URL="$BASE_URL/$ROOTFS_FILE"
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




FROM scratch as builder



FROM scratch