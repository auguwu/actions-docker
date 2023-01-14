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
RUNNER_NAME=""
if [ -z "${GITHUB_RUNNER_NAME:-}" ]; then
  echo "[actions-runner] Setting default runner name to actions-runner-$HOSTNAME"
  RUNNER_NAME="actions-runner-$HOSTNAME"
else
  echo "[actions-runner] Runner name is now [$GITHUB_RUNNER_NAME]"
  RUNNER_NAME=$GITHUB_RUNNER_NAME
fi

ORGANIZATION=${GITHUB_ORGANIZATION}
ACCESS_TOKEN=${GITHUB_ACCESS_TOKEN}
REGISTRATION_TOKEN=$(curl -sX POST -H "Authorization: token ${ACCESS_TOKEN}" https://api.github.com/orgs/${ORGANIZATION}/actions/runners/registration-token | jq .token --raw-output)

echo "[actions-runner:$ORGANIZATION@$RUNNER_NAME] Runner registration was a success, now setting up runner..."

mkdir -p $HOME/_work
cd /opt/github/actions-runner

# Setup the runner
./config.sh --unattended --replace         \
  --url https://github.com/${ORGANIZATION} \
  --token ${REGISTRATION_TOKEN}            \
  --disableupdate                          \
  --name ${RUNNER_NAME}                    \
  --runnergroup ""                         \
  --work "$HOME/_work"

echo "[actions-runner:$ORGANIZATION@$RUNNER_NAME] The runner should be configured now!"

function cleanup() {
  echo "[actions-runner:$ORGANIZATION@$RUNNER_NAME] Destroying runner..."
  ./config.sh remove --token ${REGISTRATION_TOKEN}
}

trap 'cleanup; exit 130' INT
trap 'cleanup; exit 143' TERM

./run.sh & wait $!
