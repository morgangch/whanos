pipeline {
    agent any
    
    environment {
        DOCKER_REGISTRY = "${env.DOCKER_REGISTRY ?: 'localhost:5000'}"
    }
    
    stages {
        stage('Build Base Images') {
            parallel {
                stage('Build whanos-c') {
                    steps {
                        script {
                            echo "Building whanos-c base image..."
                            sh '''
                                docker build -t whanos-c -f images/c/Dockerfile.base images/c/
                                docker tag whanos-c ${DOCKER_REGISTRY}/whanos-c:latest
                                docker push ${DOCKER_REGISTRY}/whanos-c:latest
                            '''
                        }
                    }
                }
                
                stage('Build whanos-java') {
                    steps {
                        script {
                            echo "Building whanos-java base image..."
                            sh '''
                                docker build -t whanos-java -f images/java/Dockerfile.base images/java/
                                docker tag whanos-java ${DOCKER_REGISTRY}/whanos-java:latest
                                docker push ${DOCKER_REGISTRY}/whanos-java:latest
                            '''
                        }
                    }
                }
                
                stage('Build whanos-javascript') {
                    steps {
                        script {
                            echo "Building whanos-javascript base image..."
                            sh '''
                                docker build -t whanos-javascript -f images/javascript/Dockerfile.base images/javascript/
                                docker tag whanos-javascript ${DOCKER_REGISTRY}/whanos-javascript:latest
                                docker push ${DOCKER_REGISTRY}/whanos-javascript:latest
                            '''
                        }
                    }
                }
                
                stage('Build whanos-python') {
                    steps {
                        script {
                            echo "Building whanos-python base image..."
                            sh '''
                                docker build -t whanos-python -f images/python/Dockerfile.base images/python/
                                docker tag whanos-python ${DOCKER_REGISTRY}/whanos-python:latest
                                docker push ${DOCKER_REGISTRY}/whanos-python:latest
                            '''
                        }
                    }
                }
                
                stage('Build whanos-befunge') {
                    steps {
                        script {
                            echo "Building whanos-befunge base image..."
                            sh '''
                                docker build -t whanos-befunge -f images/befunge/Dockerfile.base images/befunge/
                                docker tag whanos-befunge ${DOCKER_REGISTRY}/whanos-befunge:latest
                                docker push ${DOCKER_REGISTRY}/whanos-befunge:latest
                            '''
                        }
                    }
                }
            }
        }
        
        stage('Summary') {
            steps {
                echo """
╔═══════════════════════════════════════════╗
║     🐋 Whanos Base Images Built! 🎉      ║
╠═══════════════════════════════════════════╣
║  ✅ whanos-c                              ║
║  ✅ whanos-java                           ║
║  ✅ whanos-javascript                     ║
║  ✅ whanos-python                         ║
║  ✅ whanos-befunge                        ║
╚═══════════════════════════════════════════╝
                """
            }
        }
    }
    
    post {
        success {
            echo "All base images built and pushed successfully!"
        }
        failure {
            echo "Failed to build one or more base images."
        }
    }
}
