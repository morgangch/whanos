// Whanos Python base image build job
freeStyleJob('Whanos base images/whanos-python') {
    displayName('whanos-python')
    description('Build and push whanos-python base image to Docker registry')
    
    steps {
        shell('''#!/bin/bash
set -e

echo "Building whanos-python base image..."

# Navigate to images directory
cd ${WORKSPACE}/../../../images/python

# Build the base image
docker build -t whanos-python -f Dockerfile.base .

# Tag the image
docker tag whanos-python ${DOCKER_REGISTRY:-localhost:5000}/whanos-python:latest

# Push to registry
docker push ${DOCKER_REGISTRY:-localhost:5000}/whanos-python:latest

echo "✅ whanos-python base image built and pushed successfully!"
''')
    }
}
