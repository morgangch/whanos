// Link a Git repository to Whanos
freeStyleJob('link-project') {
    displayName('link-project')
    description('Link a Git repository to Whanos - creates a new project job that auto-builds and deploys')
    
    parameters {
        stringParam('REPOSITORY_URL', '', 'Git repository URL (HTTPS or SSH)')
        stringParam('DISPLAY_NAME', '', 'Project display name')
        choiceParam('BRANCH', ['main', 'master', 'develop'], 'Branch to monitor')
        stringParam('GIT_CREDENTIALS', '', 'Git credentials ID (if private repo, optional)')
    }
    
    steps {
        dsl {
            text('''
freeStyleJob("Projects/${DISPLAY_NAME}") {
    displayName("${DISPLAY_NAME}")
    description("Whanos automated build and deployment for ${REPOSITORY_URL}")
    
    scm {
        git {
            remote {
                url("${REPOSITORY_URL}")
                if (binding.variables.containsKey('GIT_CREDENTIALS') && GIT_CREDENTIALS) {
                    credentials("${GIT_CREDENTIALS}")
                }
            }
            branch("${BRANCH}")
        }
    }
    
    triggers {
        scm('* * * * *')
    }
    
    wrappers {
        environmentVariables {
            env('DISPLAY_NAME', '${DISPLAY_NAME}')
            env('DOCKER_REGISTRY', 'registry:5000')
        }
    }
    
    steps {
        shell(\'\'\'#!/bin/bash
set -e

# Debug: Print all environment variables related to job
echo "=== Environment Debug ==="
echo "JOB_NAME: ${JOB_NAME}"
echo "JOB_BASE_NAME: ${JOB_BASE_NAME}"
echo "DISPLAY_NAME env var: ${DISPLAY_NAME:-NOT_SET}"
echo "========================"

# Extract project name from JOB_NAME (format: Projects/ProjectName)
PROJECT_NAME=$(echo "${JOB_NAME}" | sed 's|Projects/||' | sed 's|/.*||')
IMAGE_NAME=$(echo "${PROJECT_NAME}" | tr '[:upper:]' '[:lower:]' | tr -cs '[:alnum:]-' '-' | sed 's/-$//')
IMAGE_TAG=${BUILD_NUMBER}
LANGUAGE=""

echo "Project Name: ${PROJECT_NAME}"
echo "Image Name: ${IMAGE_NAME}"
echo "Image Tag: ${IMAGE_TAG}"
echo ""

echo "╔═══════════════════════════════════════════╗"
echo "║     🐋 Whanos Build Pipeline Started     ║"
echo "╚═══════════════════════════════════════════╝"

# Detect language
echo "🔍 Detecting project language..."

if [ -f "Makefile" ]; then
    LANGUAGE="c"
    echo "✅ Detected: C (Makefile found)"
elif [ -f "app/pom.xml" ]; then
    LANGUAGE="java"
    echo "✅ Detected: Java (app/pom.xml found)"
elif [ -f "package.json" ]; then
    LANGUAGE="javascript"
    echo "✅ Detected: JavaScript (package.json found)"
elif [ -f "requirements.txt" ]; then
    LANGUAGE="python"
    echo "✅ Detected: Python (requirements.txt found)"
elif [ -f "app/main.bf" ]; then
    LANGUAGE="befunge"
    echo "✅ Detected: Befunge (app/main.bf found)"
else
    echo "❌ Could not detect project language"
    exit 1
fi

# Build Docker image
echo "🔨 Building Docker image for ${LANGUAGE}..."

if [ -f "Dockerfile" ]; then
    echo "📄 Using custom Dockerfile with whanos-${LANGUAGE} base"
    docker pull ${DOCKER_REGISTRY}/whanos-${LANGUAGE}:latest || true
    docker build -t ${IMAGE_NAME}:${IMAGE_TAG} .
else
    echo "📄 Using standalone Dockerfile for ${LANGUAGE}"
    
    # Get standalone Dockerfile from images directory
    STANDALONE_DOCKERFILE="/var/jenkins_home/whanos-images/${LANGUAGE}/Dockerfile.standalone"
    
    if [ ! -f "${STANDALONE_DOCKERFILE}" ]; then
        echo "❌ Standalone Dockerfile not found for ${LANGUAGE}"
        exit 1
    fi
    
    docker build -t ${IMAGE_NAME}:${IMAGE_TAG} -f ${STANDALONE_DOCKERFILE} .
fi

# Tag and push
docker tag ${IMAGE_NAME}:${IMAGE_TAG} ${DOCKER_REGISTRY}/${IMAGE_NAME}:${IMAGE_TAG}
docker tag ${IMAGE_NAME}:${IMAGE_TAG} ${DOCKER_REGISTRY}/${IMAGE_NAME}:latest
docker push ${DOCKER_REGISTRY}/${IMAGE_NAME}:${IMAGE_TAG}
docker push ${DOCKER_REGISTRY}/${IMAGE_NAME}:latest

echo "✅ Image built and pushed: ${DOCKER_REGISTRY}/${IMAGE_NAME}:${IMAGE_TAG}"

# Deploy to Kubernetes if whanos.yml exists
if [ -f "whanos.yml" ]; then
    echo "📦 Deploying to Kubernetes..."
    
    # Read whanos.yml configuration
    DEPLOYMENT="deployment: true"
    if grep -q "deployment:" whanos.yml; then
        DEPLOYMENT=$(grep "deployment:" whanos.yml | head -1)
    fi
    
    if echo "${DEPLOYMENT}" | grep -q "true"; then
        REPLICAS=$(grep "replicas:" whanos.yml 2>/dev/null | head -1 | awk '{print $2}' || echo "1")
        PORT=$(grep "port:" whanos.yml 2>/dev/null | head -1 | awk '{print $2}' || echo "80")
        
        echo "Deploying with ${REPLICAS} replicas on port ${PORT}"
        
        # Apply Kubernetes deployment
        cat <<EOF | kubectl apply -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: ${IMAGE_NAME}
  namespace: default
spec:
  replicas: ${REPLICAS}
  selector:
    matchLabels:
      app: ${IMAGE_NAME}
  template:
    metadata:
      labels:
        app: ${IMAGE_NAME}
    spec:
      containers:
      - name: ${IMAGE_NAME}
        image: ${DOCKER_REGISTRY}/${IMAGE_NAME}:${IMAGE_TAG}
        ports:
        - containerPort: ${PORT}
---
apiVersion: v1
kind: Service
metadata:
  name: ${IMAGE_NAME}
  namespace: default
spec:
  selector:
    app: ${IMAGE_NAME}
  ports:
  - port: ${PORT}
    targetPort: ${PORT}
  type: ClusterIP
EOF
        
        echo "✅ Deployed to Kubernetes"
    else
        echo "ℹ️  Deployment disabled in whanos.yml"
    fi
else
    echo "ℹ️  No whanos.yml found - build only (no deployment)"
fi

echo "╔═══════════════════════════════════════════╗"
echo "║     🎉 Build Completed Successfully!     ║"
echo "╚═══════════════════════════════════════════╝"
\'\'\')
    }
}
''')
            removeAction('DELETE')
            removeViewAction('DELETE')
        }
        
        shell('''#!/bin/bash
echo "✅ Project '${DISPLAY_NAME}' linked successfully!"
echo "Job created at: Projects/${DISPLAY_NAME}"
echo "Repository: ${REPOSITORY_URL}"
echo "Branch: ${BRANCH}"
echo "SCM Polling: Every minute (* * * * *)"
''')
    }
}
