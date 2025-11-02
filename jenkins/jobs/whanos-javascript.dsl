// Whanos JavaScript base image build job
freeStyleJob('Whanos base images/whanos-javascript') {
    displayName('whanos-javascript')
    description('Build and push whanos-javascript base image to Docker registry')
    
    steps {
        shell('''#!/bin/bash
set -e

echo "Building whanos-javascript base image..."

# Navigate to images directory
cd ${WORKSPACE}/../../../images/javascript

# Build the base image
docker build -t whanos-javascript -f Dockerfile.base .

# Tag the image
docker tag whanos-javascript ${DOCKER_REGISTRY:-localhost:5000}/whanos-javascript:latest

# Push to registry
docker push ${DOCKER_REGISTRY:-localhost:5000}/whanos-javascript:latest

echo "✅ whanos-javascript base image built and pushed successfully!"
''')
    }
}
