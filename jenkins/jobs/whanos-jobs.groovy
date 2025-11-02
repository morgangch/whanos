// Job DSL Seed Job to create all Whanos jobs

// Create folders
folder('Whanos base images') {
    description('Contains all Whanos base image build jobs')
}

folder('Projects') {
    description('Contains all linked project jobs')
}

// Create individual base image build jobs
def languages = ['c', 'java', 'javascript', 'python', 'befunge']

languages.each { lang ->
    freeStyleJob("Whanos base images/whanos-${lang}") {
        description("Build and push whanos-${lang} base image to Docker registry")
        
        steps {
            shell("""#!/bin/bash
set -e

echo "Building whanos-${lang} base image..."

# Navigate to images directory
cd \${WORKSPACE}/../../../images/${lang}

# Build the base image
docker build -t whanos-${lang} -f Dockerfile.base .

# Tag the image
docker tag whanos-${lang} \${DOCKER_REGISTRY:-localhost:5000}/whanos-${lang}:latest

# Push to registry
docker push \${DOCKER_REGISTRY:-localhost:5000}/whanos-${lang}:latest

echo "✅ whanos-${lang} base image built and pushed successfully!"
""")
        }
    }
}

// Create "Build all base images" job
freeStyleJob('Whanos base images/Build all base images') {
    description('Trigger all whanos base image builds')
    
    steps {
        languages.each { lang ->
            downstreamParameterized {
                trigger("Whanos base images/whanos-${lang}") {
                    block {
                        buildStepFailure('FAILURE')
                        failure('FAILURE')
                        unstable('UNSTABLE')
                    }
                }
            }
        }
    }
}

// Create link-project job
freeStyleJob('link-project') {
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
import jenkins.model.*
import hudson.model.*
import hudson.tasks.*
import hudson.plugins.git.*
import hudson.triggers.*

def repoUrl = REPOSITORY_URL
def displayName = DISPLAY_NAME
def branch = BRANCH ?: 'main'
def credentialsId = GIT_CREDENTIALS

if (!repoUrl || !displayName) {
    throw new Exception("REPOSITORY_URL and DISPLAY_NAME are required!")
}

println "Creating project: ${displayName}"
println "Repository: ${repoUrl}"
println "Branch: ${branch}"

// Create the job using Job DSL
freeStyleJob("Projects/${displayName}") {
    description("Whanos automated build and deployment for ${repoUrl}")
    
    scm {
        git {
            remote {
                url(repoUrl)
                if (credentialsId) {
                    credentials(credentialsId)
                }
            }
            branch(branch)
        }
    }
    
    triggers {
        scm('* * * * *')  // Poll every minute
    }
    
    steps {
        shell("""#!/bin/bash
set -e

DOCKER_REGISTRY=\\${DOCKER_REGISTRY:-localhost:5000}
IMAGE_NAME=\\$(echo "${displayName}" | tr '[:upper:]' '[:lower:]' | tr -cs '[:alnum:]-' '-' | sed 's/-\\$//')
IMAGE_TAG=\\${BUILD_NUMBER}
LANGUAGE=""

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
echo "🔨 Building Docker image for \\${LANGUAGE}..."

if [ -f "Dockerfile" ]; then
    echo "📄 Using custom Dockerfile with whanos-\\${LANGUAGE} base"
    docker pull \\${DOCKER_REGISTRY}/whanos-\\${LANGUAGE}:latest || true
    docker build -t \\${IMAGE_NAME}:\\${IMAGE_TAG} .
else
    echo "📄 Using standalone Dockerfile for \\${LANGUAGE}"
    
    # Get standalone Dockerfile from images directory
    STANDALONE_DOCKERFILE="/var/jenkins_home/whanos-images/\\${LANGUAGE}/Dockerfile.standalone"
    
    if [ ! -f "\\${STANDALONE_DOCKERFILE}" ]; then
        echo "❌ Standalone Dockerfile not found for \\${LANGUAGE}"
        exit 1
    fi
    
    docker build -t \\${IMAGE_NAME}:\\${IMAGE_TAG} -f \\${STANDALONE_DOCKERFILE} .
fi

# Tag and push
docker tag \\${IMAGE_NAME}:\\${IMAGE_TAG} \\${DOCKER_REGISTRY}/\\${IMAGE_NAME}:\\${IMAGE_TAG}
docker tag \\${IMAGE_NAME}:\\${IMAGE_TAG} \\${DOCKER_REGISTRY}/\\${IMAGE_NAME}:latest
docker push \\${DOCKER_REGISTRY}/\\${IMAGE_NAME}:\\${IMAGE_TAG}
docker push \\${DOCKER_REGISTRY}/\\${IMAGE_NAME}:latest

echo "✅ Image built and pushed: \\${DOCKER_REGISTRY}/\\${IMAGE_NAME}:\\${IMAGE_TAG}"

# Deploy to Kubernetes if whanos.yml exists
if [ -f "whanos.yml" ]; then
    echo "📦 Deploying to Kubernetes..."
    
    # Read whanos.yml configuration
    DEPLOYMENT="deployment: true"
    if grep -q "deployment:" whanos.yml; then
        DEPLOYMENT=\\$(grep "deployment:" whanos.yml | head -1)
    fi
    
    if echo "\\${DEPLOYMENT}" | grep -q "true"; then
        REPLICAS=\\$(grep "replicas:" whanos.yml 2>/dev/null | head -1 | awk '{print \\$2}' || echo "1")
        PORT=\\$(grep "port:" whanos.yml 2>/dev/null | head -1 | awk '{print \\$2}' || echo "80")
        
        echo "Deploying with \\${REPLICAS} replicas on port \\${PORT}"
        
        # Apply Kubernetes deployment
        cat <<EOF | kubectl apply -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: \\${IMAGE_NAME}
  namespace: default
spec:
  replicas: \\${REPLICAS}
  selector:
    matchLabels:
      app: \\${IMAGE_NAME}
  template:
    metadata:
      labels:
        app: \\${IMAGE_NAME}
    spec:
      containers:
      - name: \\${IMAGE_NAME}
        image: \\${DOCKER_REGISTRY}/\\${IMAGE_NAME}:\\${IMAGE_TAG}
        ports:
        - containerPort: \\${PORT}
---
apiVersion: v1
kind: Service
metadata:
  name: \\${IMAGE_NAME}
  namespace: default
spec:
  selector:
    app: \\${IMAGE_NAME}
  ports:
  - port: \\${PORT}
    targetPort: \\${PORT}
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
""")
    }
}

println "✅ Project '${displayName}' linked successfully!"

// Trigger initial build
def instance = Jenkins.getInstance()
def job = instance.getItemByFullName("Projects/${displayName}")
if (job) {
    job.scheduleBuild2(0)
    println "✅ Initial build triggered"
}
''')
            removeAction('DELETE')
            removeViewAction('DELETE')
        }
    }
}
