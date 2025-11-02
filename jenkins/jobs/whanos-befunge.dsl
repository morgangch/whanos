// Whanos Befunge base image build job
freeStyleJob('Whanos base images/whanos-befunge') {
    displayName('whanos-befunge')
    description('Build and push whanos-befunge base image to Docker registry')
    
    steps {
        shell('''#!/bin/bash
set -e

echo "Building whanos-befunge base image..."

# Navigate to images directory
cd ${WORKSPACE}/../../../images/befunge

# Build the base image
docker build -t whanos-befunge -f Dockerfile.base .

# Tag the image
docker tag whanos-befunge ${DOCKER_REGISTRY:-localhost:5000}/whanos-befunge:latest

# Push to registry
docker push ${DOCKER_REGISTRY:-localhost:5000}/whanos-befunge:latest

echo "✅ whanos-befunge base image built and pushed successfully!"
''')
    }
}
