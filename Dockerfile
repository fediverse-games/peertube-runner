FROM node:25-slim

LABEL org.opencontainers.image.source=https://github.com/fediverse-games/peertube-runner-docker
LABEL org.opencontainers.image.description="Peertube Runner"
LABEL org.opencontainers.image.licenses=GPL-3.0-or-later


ENV DEBIAN_FRONTEND=noninteractive
ENV FFMPEG_THREADS=0
ENV FFMPEG_CONCURRENT_JOBS=2
ENV FFMPEG_NICE=-20
ENV PEERTUBE_CONFIG_DIR="/home/peertube/.config/peertube-runner-nodejs/default"
ENV PEERTUBE_CONFIG="config.toml"
ENV PEERTUBE_RUNNER_NAME=""
ENV PEERTUBE_URL=""
ENV PEERTUBE_RUNNER_TOKEN=""
ENV PEERTUBE_RUNNER_DESCRIPTION="Peertube Runner"
ENV PEERTUBE_TRANSCRIPTION_ENGINE="whisper-ctranslate2"
ENV PEERTUBE_TRANSCRIPTION_MODEL="small"
ENV PEERTUBE_TRANSCRIPTION_ENGINEPATH="/home/peertube/.local/pipx/venvs/whisper-ctranslate2/bin/whisper-ctranslate2"
ENV PEERTUBE_RUNNER_ADDITIONAL_ARGS=""

WORKDIR /home/peertube/

ENV HOME=/home/peertube

COPY entrypoint.sh /

RUN apt update \
    && apt install -y pipx ffmpeg --no-install-recommends \
    && apt clean && rm -rf /var/lib/apt/lists/* && pipx install whisper-ctranslate2 && pipx ensurepath && npm i @peertube/peertube-runner@0.3.0 && chmod +x /entrypoint.sh \
    && groupadd -r peertube && useradd -r -g peertube -d /home/peertube -s /bin/bash peertube \
    && mkdir -p /home/peertube/.config/peertube-runner-nodejs \
    && chown -R peertube:peertube /home/peertube

USER peertube

VOLUME [ "/home/peertube/.config/peertube-runner-nodejs/" ]

ENTRYPOINT ["/entrypoint.sh"]
