pipeline {
	agent any

	stages {
        stage("Checkout") {
            steps {
                checkout(
                    [$class: 'GitSCM', 
                    branches: [[name: "${params.BRANCH}"]],
                    userRemoteConfigs: [[
                        url: 'https://github.com/seunghyun-you/on-premise-cicd',
                        credentialsId: 'github-accesskey'
                    ]]
                    ]
                )
            }
        }
        stage('Create Variable') {
            steps {
                script {
                    services = []
                    builds = []
                }
            }
        }
        stage('App Directory Check') {
            when { changeset "app/**" }
            steps {
                script {
                    services.add([NAME: 'app'])
                }
            }
        }
        stage('DB Directory Check') {
            when { changeset "db/**" }
            steps {
                script {
                    services.add([NAME: 'db'])
                }
            }
        }
        stage('Docker Build') {
            agent any
            steps {
                script {
                    services.each { service ->
                        withCredentials([usernamePassword(
                            credentialsId: 'nexus-credential', 
                            usernameVariable: 'NEXUS_USER', 
                            passwordVariable: 'NEXUS_PASS')]) {

                            def CURL_RESULT = sh(
                                script: "curl -s -u ${NEXUS_USER}:${NEXUS_PASS} ${NEXUS_URL}/v2/${service.NAME}/tags/list",
                                returnStdout: true
                            )
                            echo "${CURL_RESULT}"

                            def IMAGE_VERSION = sh(
                                script: "echo '${CURL_RESULT}' | jq -r .tags[] | sort -Vr | head -n 1",
                                returnStdout: true
                            ).trim()
                            echo "${IMAGE_VERSION}"

                            
                            def CLEAN = IMAGE_VERSION.replace("v", "")
                            def parts = CLEAN.tokenize('.')
                            def MAJOR = parts[0] as int
                            def MINOR = parts[1] as int
                            def PATCH = parts[2] as int

                            if (params.BRANCH.contains('dev')) {
                                def NEW_PATCH = PATCH + 1
                                NEW_IMAGE_VERSION = "v${MAJOR}.${MINOR}.${NEW_PATCH}"
                                echo "${NEW_IMAGE_VERSION}"
                            } else if (params.BRANCH.contains('main')) {
                                def NEW_MINOR = MINOR + 1
                                NEW_IMAGE_VERSION = "v${MAJOR}.${NEW_MINOR}.0"
                                echo "${NEW_IMAGE_VERSION}"
                            }
                        }
                        dir("./${service.NAME}") {
                            echo "${env.NEXUS_URL}/${service.NAME}:${NEW_IMAGE_VERSION}"
                            def artifact = docker.build("${env.NEXUS_URL}/${service.NAME}:${NEW_IMAGE_VERSION}")

                            builds.add([NAME: "${service.NAME}", 
                                        VERSION: "${NEW_IMAGE_VERSION}",
                                        ARTIFACT: artifact])

                            echo "Success ${service.NAME} images build: ${NEW_IMAGE_VERSION}"
                        }
                    }
                }
            }
        }
        stage('Push Image') {
            agent any
            steps {
                script {
                    builds.each { build ->  
                        docker.withRegistry("https://${env.NEXUS_URL}", "nexus-credential") {     
                            build.ARTIFACT.push("${build.VERSION}")
                            build.ARTIFACT.push("latest")
                        }
                    }
                }
            }
        }
        stage('Image Update') {
            agent any
            steps {
                script {
                    builds.each { build ->
                        withCredentials([gitUsernamePassword(credentialsId: 'github-accesskey')]) {
                            sh "rm -rf *"
                            sh "rm -rf .git"
                            sh "git clone https://github.com/seunghyun-you/on-premise-cicd-manifest.git"
                            sh "git config --global user.email 'jenkins@example.com'"
                            sh "git config --global user.name 'Jenkins CI'"

                            dir ('on-premise-cicd-manifest') {
                                sh "sed -i 's/tag: \"v[0-9]\\+\\.[0-9]\\+\\.[0-9]\\+\"/tag: \"${build.VERSION}\"/g' ${build.NAME}/values.yaml"
                                
                                sh "git add ."
                                sh "git commit -m 'Update image tag to ${build.VERSION}'"
                                sh "git push origin main"
                            }
                        }
                    }
                }
            }
        }
    }
}