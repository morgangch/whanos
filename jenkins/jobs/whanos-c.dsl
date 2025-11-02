// Whanos C base image build job
freeStyleJob('Whanos base images/whanos-c') {
    displayName('whanos-c')
    description('Build and push whanos-c base image to Docker registry')
    
    steps {
        shell('''#!/bin/bash
set -e

echo "Building whanos-c base image..."

# Navigate to images directory
cd ${WORKSPACE}/../../../images/c

# Build the base image
docker build -t whanos-c -f Dockerfile.base .

# Tag the image
docker tag whanos-c ${DOCKER_REGISTRY:-localhost:5000}/whanos-c:latest

# Push to registry
docker push ${DOCKER_REGISTRY:-localhost:5000}/whanos-c:latest

echo "✅ whanos-c base image built and pushed successfully!"
''')
    }
}
