// Whanos Java base image build job
freeStyleJob('Whanos base images/whanos-java') {
    displayName('whanos-java')
    description('Build and push whanos-java base image to Docker registry')
    
    steps {
        shell('''#!/bin/bash
set -e

echo "Building whanos-java base image..."

# Navigate to images directory
cd ${WORKSPACE}/../../../images/java

# Build the base image
docker build -t whanos-java -f Dockerfile.base .

# Tag the image
docker tag whanos-java ${DOCKER_REGISTRY:-localhost:5000}/whanos-java:latest

# Push to registry
docker push ${DOCKER_REGISTRY:-localhost:5000}/whanos-java:latest

echo "✅ whanos-java base image built and pushed successfully!"
''')
    }
}
