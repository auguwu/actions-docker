FROM ghcr.io/auguwu/coder-images/dotnet

ARG RUNNER_VERSION

# Switch to `root` user so we can install packages
USER root

# Upgrade all the base packages
ENV DEBIAN_FRONTEND=noninteractive
RUN apt update && apt upgrade -y

# Install Python and other necessities.
RUN apt install -y --no-install-recommends tini jq build-essential libssl-dev libffi-dev python3 python3-venv python3-dev python3-pip

# Create a directory where the Actions Runner will be installed in and let the `noel` user actually install it
# and run its dependencies
RUN mkdir -p /opt/github/actions-runner && chown -R noel:noel /opt/github/actions-runner

# Now, let's build it! ...and switch back to the `noel` user
RUN set -eux; \
  arch="$(dpkg --print-architecture)"; \
  case "${arch}" in \
    aarch64|arm64) \
      GITHUB_ACTIONS_RUNNER_URL="https://github.com/actions/runner/releases/download/v${RUNNER_VERSION}/actions-runner-linux-arm64-${RUNNER_VERSION}.tar.gz"; \
      ;; \
    x86_64|amd64) \
      GITHUB_ACTIONS_RUNNER_URL="https://github.com/actions/runner/releases/download/v${RUNNER_VERSION}/actions-runner-linux-x64-${RUNNER_VERSION}.tar.gz"; \
      ;; \
  esac; \
  curl -L ${GITHUB_ACTIONS_RUNNER_URL} | tar xfz - -C /opt/github/actions-runner --strip-components=1 --no-same-owner; 

RUN /opt/github/actions-runner/bin/installdependencies.sh
COPY start.sh /opt/github/actions-runner/bin/start-service.sh
RUN chmod +x /opt/github/actions-runner/bin/start-service.sh

USER noel

ENTRYPOINT ["/opt/github/actions-runner/bin/start-service.sh"]
