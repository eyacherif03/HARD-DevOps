pipeline {

    agent any

    environment {
        REGISTRY = "docker-registry/example-application"
        REGISTRY_CREDENTIAL = "registry-credentials-id"
        DOCKER_IMAGE = ""
    }

    stages {

        stage('CHECKOUT SOURCE CODE') {
            steps {
                git 'https://example.com/repository.git'
            }
        }

        stage('MVN CLEAN') {
            steps {
                sh 'java -version'
            }
        }

        stage('ARTIFACT CONSTRUCTION') {
            steps {
                echo 'Building application artifact...'
                sh 'mvn package -Dmaven.test.skip=true'
            }
        }

        stage('UNIT TESTS') {
            steps {
                echo 'Running unit tests...'
                bat 'mvn test'
            }
        }

        stage('STATIC CODE ANALYSIS') {
            steps {
                echo 'Running static code analysis...'
                sh 'mvn sonar:sonar'
            }
        }

        stage('PUBLISH ARTIFACT') {
            steps {
                echo 'Publishing artifact to repository...'
            }
        }

        stage('BUILDING OUR IMAGE') {
            steps {
                script {
                    sh "docker.build -t ${REGISTRY}:${BUILD_NUMBER}"
                }
            }
        }

        stage('DEPLOY CONTAINER IMAGE') {
            steps {
                script {
                    docker.withRegistry('', REGISTRY_CREDENTIAL) {
                        DOCKER_IMAGE.push()
                    }
                }
            }
        }
    }
}
