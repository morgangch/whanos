import jenkins.model.*
import hudson.model.*
import javaposse.jobdsl.plugin.*
import javaposse.jobdsl.plugin.actions.*
import javaposse.jobdsl.plugin.GlobalJobDslSecurityConfiguration
import jenkins.model.GlobalConfiguration

def instance = Jenkins.getInstance()

// Disable Job DSL script security to allow seed job execution
def jobDslSecurity = GlobalConfiguration.all().get(GlobalJobDslSecurityConfiguration.class)
if (jobDslSecurity != null) {
    jobDslSecurity.useScriptSecurity = false
    jobDslSecurity.save()
    println "✅ Job DSL script security disabled"
}

// Read all DSL files and combine them
def dslDir = new File('/var/jenkins_home/whanos-jenkins/jobs')
def dslScripts = []

if (dslDir.exists() && dslDir.isDirectory()) {
    dslDir.listFiles().findAll { it.name.endsWith('.dsl') }.each { file ->
        println "📄 Loading DSL: ${file.name}"
        dslScripts << file.text
    }
}

def combinedScript = dslScripts.join('\n\n')

if (!combinedScript.trim()) {
    println "⚠️  No DSL files found in ${dslDir.absolutePath}"
    println "⚠️  Skipping seed job creation"
} else {
    // Create seed job that will create all other jobs using Job DSL
    def seedJobName = 'whanos-seed-job'
    def seedJob = instance.getItem(seedJobName)

    if (seedJob == null) {
        seedJob = new FreeStyleProject(instance, seedJobName)
        seedJob.setDescription('Seed job that creates all Whanos jobs using Job DSL')
        
        // Add Job DSL build step with inline script
        def jobDslBuildStep = new ExecuteDslScripts()
        jobDslBuildStep.setScriptText(combinedScript)
        jobDslBuildStep.setUseScriptText(true)
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
}
