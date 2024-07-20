#!/usr/bin/env bash

# Script to add and get Helm chart

set -euo pipefail

CHART_REPO=${CHART_REPO:-"elastic"}
CHART_REPO_URL=${CHART_REPO_URL:-"https://helm.elastic.co"}
CHART_ECK_VER=${CHART_VERSION:-"0.11.0"}

echo "Adding ECK Helm chart"
helm repo add "${CHART_REPO}" "${CHART_REPO_URL}"
helm repo update
cd charts
helm pull "${CHART_REPO}/eck-elasticsearch" --version "${CHART_ECK_VER}" --untar=false
helm pull "${CHART_REPO}/eck-kibana" --version "${CHART_ECK_VER}" --untar=false
helm pull "${CHART_REPO}/eck-beats" --version "${CHART_ECK_VER}" --untar=false
helm pull "${CHART_REPO}/eck-apm-server" --version "${CHART_ECK_VER}" --untar=false