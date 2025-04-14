pipeline {
    agent none
    environment {
        DOCKERHUB_AUTH = credentials('docker')
        IMAGE_NAME = "your-image-name" // Remplacez par le nom de votre image
        IMAGE_TAG = "latest" // Remplacez par le tag de votre image
        PORT_EXPOSED = "80"
        HOSTNAME_DEPLOY_PROD = "ec2-15-237-191-5.eu-west-3.compute.amazonaws.com"
        HOSTNAME_DEPLOY_STAGING = "ec2-13-37-227-8.eu-west-3.compute.amazonaws.com"
        SSH_CREDENTIALS_STAGING = 'SSH_AUTH_SERVER'
        SSH_CREDENTIALS_PROD = 'SSH_AUTH_PROD'
    }
    stages {
        stage('Build Docker Image') {
            agent any
            steps {
                script {
                    sh '''
                        echo "Building Docker image..."
                        docker build -t ${DOCKERHUB_AUTH_USR}/${IMAGE_NAME}:${IMAGE_TAG} .
                    '''
                }
            }
        }

        stage('Run Local Container') {
            agent any
            steps {
                script {
                    sh '''
                        echo "Cleaning up existing container..."
                        docker rm -f ${IMAGE_NAME} || echo "No existing container to remove"
                        echo "Running container locally..."
                        docker run --name ${IMAGE_NAME} -d -p ${PORT_EXPOSED}:5000 -e PORT=5000 ${DOCKERHUB_AUTH_USR}/${IMAGE_NAME}:${IMAGE_TAG}
                        sleep 5
                    '''
                }
            }
        }

        stage('Test Local Container') {
            agent any
            steps {
                script {
                    sh '''
                        echo "Testing local container..."
                        curl -s http://localhost:${PORT_EXPOSED} | grep -q "Hello world Lewis!" || exit 1
                    '''
                }
            }
        }

        stage('Push Docker Image to Docker Hub') {
            agent any
            steps {
                script {
                    sh '''
                        echo "Logging into Docker Hub..."
                        docker login -u ${DOCKERHUB_AUTH_USR} -p ${DOCKERHUB_AUTH_PSW}
                        echo "Pushing Docker image to Docker Hub..."
                        docker push ${DOCKERHUB_AUTH_USR}/${IMAGE_NAME}:${IMAGE_TAG}
                    '''
                }
            }
        }

        stage('Deploy to Staging') {
            agent any
            steps {
                sshagent(credentials: [SSH_CREDENTIALS_STAGING]) {
                    sh '''
                        echo "Deploying to Staging..."
                        ssh-keyscan -H ${HOSTNAME_DEPLOY_STAGING} >> ~/.ssh/known_hosts
                        ssh centos@${HOSTNAME_DEPLOY_STAGING} << EOF
                            docker login -u ${DOCKERHUB_AUTH_USR} -p ${DOCKERHUB_AUTH_PSW}
                            docker pull ${DOCKERHUB_AUTH_USR}/${IMAGE_NAME}:${IMAGE_TAG}
                            docker rm -f webapp || echo "No existing container to remove"
                            docker run -d -p 80:5000 -e PORT=5000 --name webapp ${DOCKERHUB_AUTH_USR}/${IMAGE_NAME}:${IMAGE_TAG}
                        EOF
                    '''
                }
            }
        }

        stage('Test Staging') {
            agent any
            steps {
                script {
                    sh '''
                        echo "Testing Staging environment..."
                        curl -s http://${HOSTNAME_DEPLOY_STAGING} | grep -q "Hello world!" || exit 1
                    '''
                }
            }
        }

        stage('Deploy to Production') {
            agent any
            steps {
                sshagent(credentials: [SSH_CREDENTIALS_PROD]) {
                    sh '''
                        echo "Deploying to Production..."
                        ssh-keyscan -H ${HOSTNAME_DEPLOY_PROD} >> ~/.ssh/known_hosts
                        ssh centos@${HOSTNAME_DEPLOY_PROD} << EOF
                            docker login -u ${DOCKERHUB_AUTH_USR} -p ${DOCKERHUB_AUTH_PSW}
                            docker pull ${DOCKERHUB_AUTH_USR}/${IMAGE_NAME}:${IMAGE_TAG}
                            docker rm -f webapp || echo "No existing container to remove"
                            docker run -d -p 80:5000 -e PORT=5000 --name webapp ${DOCKERHUB_AUTH_USR}/${IMAGE_NAME}:${IMAGE_TAG}
                        EOF
                    '''
                }
            }
        }

        stage('Test Production') {
            agent any
            steps {
                script {
                    sh '''
                        echo "Testing Production environment..."
                        curl -s http://${HOSTNAME_DEPLOY_PROD} | grep -q "Hello world!" || exit 1
                    '''
                }
            }
        }
    }

    post {
        success {
            slackSend(color: '#00FF00', message: "SUCCESSFUL: Job '${env.JOB_NAME} [${env.BUILD_NUMBER}]' (${env.BUILD_URL})")
        }
        failure {
            slackSend(color: '#FF0000', message: "FAILED: Job '${env.JOB_NAME} [${env.BUILD_NUMBER}]' (${env.BUILD_URL})")
        }
    }
}
