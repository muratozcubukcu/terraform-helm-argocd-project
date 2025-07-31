#!/bin/bash

set -e

echo "🚀 Building and pushing Terrahelm webapp"

# Configuration
IMAGE_NAME="muratozcubukcu/terrahelm-webapp"
VERSION="latest"
DOCKERFILE_PATH="app/Dockerfile"
BUILD_CONTEXT="app"

# Build the Docker image
echo "📦 Building Docker image..."
docker build -t ${IMAGE_NAME}:${VERSION} -f ${DOCKERFILE_PATH} ${BUILD_CONTEXT}

# Tag with timestamp for versioning
TIMESTAMP=$(date +%Y%m%d-%H%M%S)
docker tag ${IMAGE_NAME}:${VERSION} ${IMAGE_NAME}:${TIMESTAMP}

echo "✅ Built images:"
echo "  ${IMAGE_NAME}:${VERSION}"
echo "  ${IMAGE_NAME}:${TIMESTAMP}"

# Push to registry (optional - uncomment if you want to push)
read -p "Push to Docker Hub? (y/n): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo "📤 Pushing to Docker Hub..."
    docker push ${IMAGE_NAME}:${VERSION}
    docker push ${IMAGE_NAME}:${TIMESTAMP}
    echo "✅ Images pushed successfully!"
else
    echo "⏭️  Skipped pushing to Docker Hub"
fi

echo ""
echo "📋 To use the timestamped version, update your values:"
echo "  app.image: ${IMAGE_NAME}:${TIMESTAMP}"
echo ""
echo "🔧 To test locally:"
echo "  docker run -p 3000:3000 -e POSTGRES_HOST=localhost ${IMAGE_NAME}:${VERSION}"