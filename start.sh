#!/bin/bash

if [ -z "${GITHUB_ORGANIZATION:-}" ]; then
  echo "[actions-runner] You must set the \`GITHUB_ORGANIZATION\` environment variable"
  exit 1
fi

if [ -z "${GITHUB_ACCESS_TOKEN:-}" ]; then
  echo "[actions-runner] You must set the \`GITHUB_ACCESS_TOKEN\` environment variable"
  exit 1
fi

HOSTNAME=$(cat /etc/hostname)
ORGANIZATION=${GITHUB_ORGANIZATION}
ACCESS_TOKEN=${GITHUB_ACCESS_TOKEN}
RUNNER_NAME=${GITHUB_RUNNER_NAME:-"actions-runner-$HOSTNAME"}
REGISTRATION_TOKEN=$(curl -sX POST -H "Authorization: token ${ACCESS_TOKEN}" https://api.github.com/orgs/${ORGANIZATION}/actions/runners/registration-token | jq .token --raw-output)

echo "[actions-runner] I have setup the runner's registration token with the $ORGANIZATION organization and with runner name $RUNNER_NAME"

mkdir -p $HOME/_work
cd /opt/github/actions-runner

# Setup the runner
./config.sh --unattended --replace         \
  --url https://github.com/${ORGANIZATION} \
  --token ${REGISTRATION_TOKEN}            \
  --disableupdate                          \
  --name actions-runner                    \
  --runnergroup ""                         \
  --work "$HOME/_work"

echo "[actions-runner:$RUNNER_NAME@$ORGANIZATION] The runner should be configured now!"

function cleanup() {
  echo "[actions-runner] Destroying runner..."
  ./config.sh remove --token ${REGISTRATION_TOKEN}
}

trap 'cleanup; exit 130' INT
trap 'cleanup; exit 143' TERM

./run.sh & wait $!
