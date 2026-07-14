#!/bin/bash
export DOCKER_USER="nareshvj04"
export TAG=$(git rev-parse --short HEAD)
BRANCH="${BRANCH_NAME:-${GIT_BRANCH:-$(git rev-parse --abbrev-ref HEAD)}}"

BRANCH="${BRANCH##*/}"

if [ "$BRANCH" = "main" ]; then
    REPO="prod"
else
    REPO="dev"
fi

echo "Building Docker image tracking tag: $TAG for $REPO repository..."
echo "Building Docker image tracking tag: $TAG..."
docker build -t $DOCKER_USER/$REPO:$TAG -t $DOCKER_USER/$REPO:latest .

