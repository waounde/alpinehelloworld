pipeline {
    agent none
    environment {
        DOCKERHUB_AUTH = credentials('docker')
        ID_DOCKER = "${DOCKERHUB_AUTH_USR}"
        PORT_EXPOSED = "80"
        IMAGE_NAME = "alpinehelloworld" // Remplacez par le nom de votre image
        IMAGE_TAG = "latest" // Remplacez par le tag de votre image
    }
    stages {
        stage('Build Docker Image') {
            agent any
            steps {
                script {
                    sh '''
                        echo "Building Docker image..."
                        docker build -t ${ID_DOCKER}/${IMAGE_NAME}:${IMAGE_TAG} .
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
                        docker run --name ${IMAGE_NAME} -d -p ${PORT_EXPOSED}:5000 -e PORT=5000 ${ID_DOCKER}/${IMAGE_NAME}:${IMAGE_TAG}
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
                        RESPONSE=$(curl -s http://localhost:${PORT_EXPOSED})
                        echo "Response: $RESPONSE"
                        echo "$RESPONSE" | grep -iq "hello world lewis!" || exit 1
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
                        docker push ${ID_DOCKER}/${IMAGE_NAME}:${IMAGE_TAG}
                    '''
                }
            }
        }

        stage('Deploy to Staging') {
            agent any
            environment {
                HOSTNAME_DEPLOY_STAGING = "ec2-13-48-44-234.eu-north-1.compute.amazonaws.com"
            }
            steps {
                sshagent(credentials: ['SSH_AUTH_SERVER']) {
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

        stage('Deploy to Production') {
            agent any
            environment {
                HOSTNAME_DEPLOY_PROD = "ec2-13-60-186-40.eu-north-1.compute.amazonaws.com"
            }
            steps {
                sshagent(credentials: ['SSH_AUTH_PROD']) {
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
    }
}
