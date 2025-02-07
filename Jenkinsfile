pipeline {
    agent none
    environment {
        DOCKERHUB_AUTH = credentials('DOCKERHUB_AUTH')
        ID_DOCKER = "${DOCKERHUB_AUTH_USR}"
        PORT_EXPOSED = "80"
    }
    stages {
        stage('Build Image') {
            agent any
            steps {
                script {
                    sh "docker build -t ${ID_DOCKER}/${IMAGE_NAME}:${IMAGE_TAG} ."
                }
            }
        }

        stage('Run container based on built image') {
            agent any
            steps {
                script {
                    sh '''
                        echo "Clean Environment"
                        docker rm -f $IMAGE_NAME || echo "Container does not exist"
                        docker run --name $IMAGE_NAME -d -p ${PORT_EXPOSED}:5000 -e PORT=5000 ${ID_DOCKER}/$IMAGE_NAME:$IMAGE_TAG
                        sleep 5
                    '''
                }
            }
        }

        stage('Test Image') {
            agent any
            steps {
                script {
                    sh '''
                        curl -s http://172.17.0.1:${PORT_EXPOSED} | grep -q "Hello world!"
                    '''
                }
            }
        }

        stage('Clean Container') {
            agent any
            steps {
                script {
                    sh '''
                        docker stop $IMAGE_NAME || true
                        docker rm $IMAGE_NAME || true
                    '''
                }
            }
        }

        stage('Login and Push Image to DockerHub') {
            agent any           
            steps {
                script {
                    sh '''
                        echo "${DOCKERHUB_AUTH_PSW}" | docker login -u "$DOCKERHUB_AUTH_USR" --password-stdin
                        docker push ${ID_DOCKER}/$IMAGE_NAME:$IMAGE_TAG
                    '''
                }
            }
        }

        stage('Deploy in staging') {
            agent any
            environment {
                HOSTNAME_DEPLOY_STAGING = "ec2-18-215-143-212.compute-1.amazonaws.com"
            }
            steps {
                script {
                    echo "Deploying to EC2 (staging)"
                    def commands = """
                        docker stop ${IMAGE_NAME} || echo 'Container not running'
                        docker rm ${IMAGE_NAME} || echo 'Container not found'
                        docker pull ${ID_DOCKER}/${IMAGE_NAME}:${IMAGE_TAG}
                        docker run -d -p ${PORT_EXPOSED}:5000 -e PORT=5000 --name ${IMAGE_NAME} ${ID_DOCKER}/${IMAGE_NAME}:${IMAGE_TAG}
                    """
                    sshagent(['SSH_AUTH_SERVER']) {
                        sh "ssh -o StrictHostKeyChecking=no ubuntu@${HOSTNAME_DEPLOY_STAGING} '${commands}'"
                    }       
                }
            }
        }

        stage('Deploy in prod') {
            agent any
            environment {
                HOSTNAME_DEPLOY_PROD = "ec2-52-71-142-24.compute-1.amazonaws.com"
            }
            steps {
                script {
                    echo "Deploying to EC2 (prod)"
                    def commands = """
                        docker stop ${IMAGE_NAME} || echo 'Container not running'
                        docker rm ${IMAGE_NAME} || echo 'Container not found'
                        docker pull ${ID_DOCKER}/${IMAGE_NAME}:${IMAGE_TAG}
                        docker run -d -p ${PORT_EXPOSED}:5000 -e PORT=5000 --name ${IMAGE_NAME} ${ID_DOCKER}/${IMAGE_NAME}:${IMAGE_TAG}
                    """
                    sshagent(['SSH_AUTH_SERVER']) {
                        sh "ssh -o StrictHostKeyChecking=no ubuntu@${HOSTNAME_DEPLOY_PROD} '${commands}'"
                    }
                }
            }
        }
    }
}
