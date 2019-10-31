@Library('jenkins-shared-libraries') _

def DISTRIBUTION = 'alpine'
def DEPLOY = params.getOrDefault("DEPLOY", false)
// tag as SNAPSHOT if not `master` or is `pr`
def SNAPSHOT =  DEPLOY ? true : (env.CHANGE_ID || env.BRANCH_NAME != 'master');
def TIMESTAMP = (new Date()).format("yyyyddMMHHmmss")
def IMAGES = [];

// This looks like shit because of
//  - https://issues.jenkins-ci.org/browse/JENKINS-35988
//  - https://issues.jenkins-ci.org/browse/JENKINS-36195

pipeline {
    agent {
        label "alpine-docker"
    }
    parameters {
        booleanParam defaultValue: false, description: 'Deploy tagged images to docker hub.', name: 'DEPLOY'
    }
    options {
        buildDiscarder logRotator(artifactDaysToKeepStr: '', artifactNumToKeepStr: '50', daysToKeepStr: '', numToKeepStr: '1000')
        timeout(time: 2, unit: 'HOURS')
        disableResume()
        durabilityHint 'PERFORMANCE_OPTIMIZED'
        disableConcurrentBuilds()
        skipStagesAfterUnstable()
    }
    environment {
        TIMESTAMP = "$TIMESTAMP"
    }
    stages {
        stage('Node') {
            steps {
                container("docker") {
                    nodeInfo("docker")
                }
            }
        }
        stage('Build') {
            steps {
                script {
                    def buildStages = [:]
                    buildStages.put("alpine", distributionBuildStages("alpine", SNAPSHOT, IMAGES))
                    buildStages.put("debian", distributionBuildStages("debian", SNAPSHOT, IMAGES))
                    buildStages.put("centos", distributionBuildStages("centos", SNAPSHOT, IMAGES))
                    buildStages.put("opensuse", distributionBuildStages("opensuse", SNAPSHOT, IMAGES))
                    buildStages.put("ubuntu", distributionBuildStages("ubuntu", SNAPSHOT, IMAGES))

                    parallel buildStages

                    println IMAGES
                }
            }
        }
        stage('Publish') {
            when {
                anyOf {
                    branch 'master'
                    expression { DEPLOY == true }
                }
            }
            steps {
                container("docker") {
                    echo "Images to push: " + IMAGES.toString()
                    withDockerRegistry([credentialsId: '6fedbf52-4df3-4328-90d6-0caf08edb68d', url: "https://index.docker.io/v1/"]) {
                        script {
                            def attempt = 0
                            retry(5) {
                                // wait for a moment, might be a temporary network issue?
                                if(attempt > 0) {
                                    sleep 15
                                }
                                attempt++;
                                IMAGES.each {
                                    sh label: "Publishing ${it}...",
                                       script: "docker push ${it}"
                                }
                            }
                        }
                    }
                }
            }
        }
    }
    post {
        always {
            container("docker") {
                archiveArtifacts '*/**.build.log'
            }
        }
    }
}

def distributionBuildStages(DISTRIBUTION, SNAPSHOT, IMAGES) {
    return {
        stage('base') {
            container("docker") {
                script {
                    def built = processDockerfiles(findDockerfiles((String) "./images/$DISTRIBUTION/Dockerfile.$DISTRIBUTION*"), SNAPSHOT);
                    IMAGES = IMAGES + built
                }
            }
        }
        stage('jdk8') {
            container("docker") {
                script {
                    def built = processDockerfiles(findDockerfiles((String) "./images/$DISTRIBUTION/jdk8"), SNAPSHOT);
                    IMAGES = IMAGES + built
                }
            }
        }
        stage('jdk11') {
            container("docker") {
                script {
                    def built = processDockerfiles(findDockerfiles((String) "./images/$DISTRIBUTION/jdk11"), SNAPSHOT);
                    IMAGES = IMAGES + built
                }
            }
        }
    }
}

def findDockerfiles(path, maxDepth = "")
{
    def findArgs = maxDepth ? " -maxdepth $maxDepth " : ""
    // !!!!!!!! DO NOT MESS WITH THE QUOTES OR YOU WILL REGRET IT !!!!!!!!
    // https://gist.github.com/Faheetah/e11bd0315c34ed32e681616e41279ef4
    return sh(script: """find $path $findArgs -type f -name "*Dockerfile*" ! -name "*build.log" | sort | xargs""", label: "Searching for Dockerfiles", returnStdout: true)
}

def processDockerfiles(files, snapshot)
{
    def BUILD_ARGS = snapshot ? " --snapshot " : ""
    def images = [];

    files.split(" ").each {
        println it
        def match = (it =~ /(.*)\\/Dockerfile\.(\w+)(\.(.+))?/)
        if (match.find())
        {
            retry(2) {
                // Do not use `docker.build` because it fails with `"docker build" requires exactly 1 argument.`.
                // docker.build(IMAGE, '-f ${it} --no-cache .')

                def IMAGE_TAG = sh(label: "Getting image tag", script: "/bin/bash ./build.sh ${BUILD_ARGS} --get-image $it", returnStdout: true)

                sh label: "Building $IMAGE_TAG",
                   script: "/bin/bash ./build.sh --no-cache ${BUILD_ARGS} $it"

                images.add(IMAGE_TAG)
            }
        }
        else
        {
            println "Something went wrong and we could not properly parse ${it} - skipping"
        }
    }

    return images
}
