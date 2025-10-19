properties([
    parameters([
        string(name: 'REPOSITORY_URL', description: 'Git repository URL (HTTPS or SSH)', trim: true),
        string(name: 'DISPLAY_NAME', description: 'Project display name', trim: true),
        choice(name: 'BRANCH', choices: ['main', 'master', 'develop'], description: 'Branch to monitor'),
        credentials(name: 'GIT_CREDENTIALS', description: 'Git credentials (if private repo)', required: false)
    ])
])

pipeline {
    agent any
    
    stages {
        stage('Validate Input') {
            steps {
                script {
                    if (!params.REPOSITORY_URL) {
                        error("REPOSITORY_URL parameter is required!")
                    }
                    if (!params.DISPLAY_NAME) {
                        error("DISPLAY_NAME parameter is required!")
                    }
                    
                    echo "Creating Whanos project for: ${params.DISPLAY_NAME}"
                    echo "Repository: ${params.REPOSITORY_URL}"
                    echo "Branch: ${params.BRANCH}"
                }
            }
        }
        
        stage('Create Project Job') {
            steps {
                script {
                    def jobName = "Projects/${params.DISPLAY_NAME}"
                    def jobDsl = """
pipelineJob('${jobName}') {
    displayName('${params.DISPLAY_NAME}')
    description('Whanos automated build and deployment for ${params.REPOSITORY_URL}')
    
    properties {
        pipelineTriggers {
            triggers {
                pollSCM {
                    scmpoll_spec('H/5 * * * *')
                }
            }
        }
    }
    
    definition {
        cpsScm {
            scm {
                git {
                    remote {
                        url('${params.REPOSITORY_URL}')
                        ${params.GIT_CREDENTIALS ? "credentials('${params.GIT_CREDENTIALS}')" : ''}
                    }
                    branch('${params.BRANCH}')
                }
            }
            scriptPath('Jenkinsfile')
        }
    }
}
"""
                    
                    // Use Job DSL to create the project
                    jobDsl scriptText: jobDsl
                    
                    echo """
╔═══════════════════════════════════════════╗
║     🔗 Project Linked Successfully! 🎉   ║
╠═══════════════════════════════════════════╣
║  Project: ${params.DISPLAY_NAME}
║  Repository: ${params.REPOSITORY_URL}
║  Branch: ${params.BRANCH}
║  Job Path: ${jobName}
╚═══════════════════════════════════════════╝
                    """
                }
            }
        }
        
        stage('Test Repository Access') {
            steps {
                script {
                    echo "Testing repository access..."
                    try {
                        if (params.GIT_CREDENTIALS) {
                            withCredentials([usernamePassword(credentialsId: params.GIT_CREDENTIALS, 
                                                             usernameVariable: 'GIT_USER', 
                                                             passwordVariable: 'GIT_PASS')]) {
                                sh """
                                    git ls-remote ${params.REPOSITORY_URL} HEAD
                                """
                            }
                        } else {
                            sh """
                                git ls-remote ${params.REPOSITORY_URL} HEAD
                            """
                        }
                        echo "✅ Repository access successful!"
                    } catch (Exception e) {
                        error("❌ Failed to access repository: ${e.message}")
                    }
                }
            }
        }
        
        stage('Trigger Initial Build') {
            steps {
                script {
                    def jobName = "Projects/${params.DISPLAY_NAME}"
                    echo "Triggering initial build for ${jobName}..."
                    
                    try {
                        build job: jobName, wait: false
                        echo "✅ Initial build triggered successfully!"
                    } catch (Exception e) {
                        echo "⚠️  Could not trigger initial build: ${e.message}"
                    }
                }
            }
        }
    }
    
    post {
        success {
            echo """
════════════════════════════════════════════
    🐋 Whanos Project Linked Successfully!
    
    Your project '${params.DISPLAY_NAME}' is now
    integrated with Whanos and will automatically
    build and deploy on every push.
════════════════════════════════════════════
            """
        }
        failure {
            echo "❌ Failed to link project to Whanos."
        }
    }
}
