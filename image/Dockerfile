FROM ubuntu:noble
RUN apt-get update && apt-get install -y unminimize curl htop unzip
RUN yes | unminimize
RUN curl -fsSL https://openclaw.ai/install.sh | bash -s -- --no-onboard --no-prompt
COPY --chmod=755 ./init.sh /init.sh
