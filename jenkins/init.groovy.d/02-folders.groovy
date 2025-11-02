import jenkins.model.*
import hudson.model.*
import javaposse.jobdsl.plugin.*

def instance = Jenkins.getInstance()

// Create seed job that will create all other jobs using Job DSL
def seedJobName = 'whanos-seed-job'
def seedJob = instance.getItem(seedJobName)

if (seedJob == null) {
    seedJob = new FreeStyleProject(instance, seedJobName)
    seedJob.setDescription('Seed job that creates all Whanos jobs using Job DSL')
    
    // Add Job DSL build step pointing to .dsl files
    def jobDslBuildStep = new ExecuteDslScripts(
        new ExecuteDslScripts.ScriptLocation(
            'true',  // use script location (files)
            '/var/jenkins_home/whanos-jenkins/jobs/*.dsl',  // targets - all .dsl files
            null  // script text (not used)
        ),
        false,  // ignore existing
        RemovedJobAction.DELETE,
        RemovedViewAction.DELETE,
        LookupStrategy.JENKINS_ROOT,
        ''  // additional classpath
    )
    
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
