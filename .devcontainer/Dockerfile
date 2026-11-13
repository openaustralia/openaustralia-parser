# Dev-only image for running the parser and its specs in Docker (see compose.yaml). It matches the openaustralia
# production server the parser runs on: Ubuntu 22.04 (jammy) with Ruby built by ruby-build, as rbenv does there (the
# infrastructure repo's ruby_versions for openaustralia). buildpack-deps is the base the official Ruby images use.
FROM buildpack-deps:jammy

ARG RUBY_VERSION=3.4.9
RUN git clone --depth 1 https://github.com/rbenv/ruby-build.git /tmp/ruby-build \
    && /tmp/ruby-build/bin/ruby-build "$RUBY_VERSION" /usr/local \
    && rm -rf /tmp/ruby-build

# Gems live in /usr/local/bundle, as in the official Ruby images, which is where compose.yaml's bundle volume goes
# UTF-8 like production; the official Ruby images set this, buildpack-deps doesn't
ENV LANG=C.UTF-8
ENV GEM_HOME=/usr/local/bundle BUNDLE_APP_CONFIG=/usr/local/bundle BUNDLE_SILENCE_ROOT_WARNING=1
ENV PATH=/usr/local/bundle/bin:$PATH

# rmagick and mysql2 native extensions, plus a mysql client for poking at the database
RUN apt-get update && apt-get install -y --no-install-recommends \
      libmagickwand-dev \
      default-libmysqlclient-dev \
      default-mysql-client \
    && rm -rf /var/lib/apt/lists/*

# Run as a non-root "deploy" user, so files the parser and specs write into the bind-mounted checkout belong to you
# rather than root. The bundle and rblib volumes take their ownership from these directories when first created.
# On Linux, set UID and GID in .env if your own ids (`id -u`, `id -g`) aren't 1000.
# Leave them unset on macOS: Docker Desktop maps file ownership on bind mounts itself, and macOS's gid 20 clashes with
# an existing group in the image.
ARG UID=1000
ARG GID=1000
RUN groupadd --gid "$GID" deploy \
    && useradd --uid "$UID" --gid deploy -m deploy \
    && mkdir -p /usr/local/bundle /rblib /app \
    && chown deploy:deploy /usr/local/bundle /rblib /app
USER deploy

WORKDIR /app
