// Build all Whanos base images
freeStyleJob('Whanos base images/Build all base images') {
    displayName('Build all base images')
    description('Trigger all whanos base image builds')
    
    steps {
        downstreamParameterized {
            trigger('Whanos base images/whanos-c') {
                block {
                    buildStepFailure('FAILURE')
                    failure('FAILURE')
                    unstable('UNSTABLE')
                }
            }
        }
        downstreamParameterized {
            trigger('Whanos base images/whanos-java') {
                block {
                    buildStepFailure('FAILURE')
                    failure('FAILURE')
                    unstable('UNSTABLE')
                }
            }
        }
        downstreamParameterized {
            trigger('Whanos base images/whanos-javascript') {
                block {
                    buildStepFailure('FAILURE')
                    failure('FAILURE')
                    unstable('UNSTABLE')
                }
            }
        }
        downstreamParameterized {
            trigger('Whanos base images/whanos-python') {
                block {
                    buildStepFailure('FAILURE')
                    failure('FAILURE')
                    unstable('UNSTABLE')
                }
            }
        }
        downstreamParameterized {
            trigger('Whanos base images/whanos-befunge') {
                block {
                    buildStepFailure('FAILURE')
                    failure('FAILURE')
                    unstable('UNSTABLE')
                }
            }
        }
    }
}
