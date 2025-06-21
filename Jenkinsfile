pipeline {
    agent any

    environment {
        DOCKER_IMAGE = 'aaleem1993/twnprojectjenkins'
        DOCKER_CREDENTIALS_ID = 'docker-hub-creds'
        GIT_CREDENTIALS_ID = 'git-ssh'
        EC2_SSH_CREDENTIALS_ID = 'demo-ec2-ssh'
        EC2_HOST = 'ubuntu@ec2-3-94-152-136.compute-1.amazonaws.com'
        GIT_SSH_COMMAND = "ssh -o StrictHostKeyChecking=no"
    }

    stages {
        stage('Checkout Code') {
            steps {
                checkout scm
            }
        }

        stage('Increment Version') {
            steps {
                sh 'npm version minor --no-git-tag-version'
            }
        }

        stage('Run Tests') {
            steps {
                sh 'npm test'
            }
        }

        stage('Build Docker Image') {
            steps {
                script {
                    def version = sh(script: "node -p \"require('./package.json').version\"", returnStdout: true).trim()
                    env.IMAGE_TAG = "${DOCKER_IMAGE}:${version}"
                    sh "docker build -t ${env.IMAGE_TAG} ."
                }
            }
        }

        stage('Push Docker Image to Docker Hub') {
            steps {
                withCredentials([usernamePassword(credentialsId: "${DOCKER_CREDENTIALS_ID}", usernameVariable: 'DOCKER_USER', passwordVariable: 'DOCKER_PASS')]) {
                    sh "echo $DOCKER_PASS | docker login -u $DOCKER_USER --password-stdin"
                    sh "docker push ${env.IMAGE_TAG}"
                }
            }
        }

        stage('Terraform Init') {
            steps {
                dir('terraform') {
                    sh 'terraform init'
                }
            }
        }

        stage('Terraform Plan') {
            steps {
                dir('terraform') {
                    sh 'terraform plan'
                }
            }
        }

        stage('Terraform Apply') {
            steps {
                dir('terraform') {
                    sh 'terraform apply -auto-approve'
                }
            }
        }
    }
}

