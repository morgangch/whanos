import jenkins.model.*
import hudson.model.*
import javaposse.jobdsl.plugin.*
import javaposse.jobdsl.plugin.actions.*

def instance = Jenkins.getInstance()

// Create seed job that will create all other jobs using Job DSL
def seedJobName = 'whanos-seed-job'
def seedJob = instance.getItem(seedJobName)

if (seedJob == null) {
    seedJob = new FreeStyleProject(instance, seedJobName)
    seedJob.setDescription('Seed job that creates all Whanos jobs using Job DSL')
    
    // Add Job DSL build step pointing to .dsl files
    def jobDslBuildStep = new ExecuteDslScripts()
    jobDslBuildStep.setTargets('/var/jenkins_home/whanos-jenkins/jobs/*.dsl')
    jobDslBuildStep.setUseScriptText(false)
    jobDslBuildStep.setIgnoreExisting(false)
    jobDslBuildStep.setRemovedJobAction(RemovedJobAction.DELETE)
    jobDslBuildStep.setRemovedViewAction(RemovedViewAction.DELETE)
    
    seedJob.getBuildersList().add(jobDslBuildStep)
    instance.putItem(seedJob)
    
    println "✅ Seed job '${seedJobName}' created"
    
    // Trigger the seed job to create all Whanos jobs
    println "🚀 Triggering seed job to create Whanos jobs..."
    seedJob.scheduleBuild2(0)
    
} else {
    println "ℹ️  Seed job '${seedJobName}' already exists"
}

instance.save()

println "✅ Job DSL seed job configured successfully"
