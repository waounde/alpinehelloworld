@Library('shared-library@main')_
pipeline {
    agent none
    environment {
        DOCKERHUB_AUTH = credentials('DOCKERHUB_AUTH')
        ID_DOCKER = "${DOCKERHUB_AUTH_USR}"
        PORT_EXPOSED = "80"
        IMAGE_NAME = "alpinehelloworld"
        IMAGE_TAG = "latest"
    }
    stages {
        stage('Build image') {
            agent any
            steps {
                script {
                    sh 'docker build -t ${ID_DOCKER}/${IMAGE_NAME}:${IMAGE_TAG} .'
                }
            }
        }

        stage('Run container based on built image') {
            agent any
            steps {
                script {
                    sh '''
                        echo "Cleaning Environment"
                        docker rm -f $IMAGE_NAME || true
                        docker run --name $IMAGE_NAME -d -p ${PORT_EXPOSED}:5000 -e PORT=5000 ${ID_DOCKER}/$IMAGE_NAME:$IMAGE_TAG
                        sleep 5
                    '''
                }
            }
        }

        stage('Test image') {
            agent any
            steps {
                script {
                    sh '''
                        curl -f http://localhost:${PORT_EXPOSED} | grep -q "Hello world!"
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

        stage('Login and Push Image to Docker Hub') {
            agent any           
            steps {
                script {
                    sh '''
                        echo "$DOCKERHUB_AUTH_PSW" | docker login -u $DOCKERHUB_AUTH_USR --password-stdin
                        docker push ${ID_DOCKER}/$IMAGE_NAME:$IMAGE_TAG
                    '''
                }
            }
        }

        stage('Deploy to staging') {
            agent any
            environment {
                HOSTNAME_DEPLOY_STAGING = "16.170.225.83"
            }
            steps {
                sshagent(credentials: ['SSH_AUTH_SERVER']) {
                    sh '''
                        [ -d ~/.ssh ] || mkdir -p ~/.ssh && chmod 0700 ~/.ssh
                        ssh-keyscan -H ${HOSTNAME_DEPLOY_STAGING} >> ~/.ssh/known_hosts 2>/dev/null
                        ssh ubuntu@${HOSTNAME_DEPLOY_STAGING} "
                            echo \"$DOCKERHUB_AUTH_PSW\" | docker login -u $DOCKERHUB_AUTH_USR --password-stdin
                            docker pull $DOCKERHUB_AUTH_USR/$IMAGE_NAME:$IMAGE_TAG
                            docker rm -f webapp || true
                            docker run -d -p 80:5000 -e PORT=5000 --name webapp $DOCKERHUB_AUTH_USR/$IMAGE_NAME:$IMAGE_TAG
                        "
                    '''
                }
            }
        }

        stage('Deploy to production') {
            agent any
            environment {
                HOSTNAME_DEPLOY_PROD = "56.228.42.215"
            }
            steps {
                sshagent(credentials: ['SSH_AUTH_SERVER']) {
                    sh '''
                        [ -d ~/.ssh ] || mkdir -p ~/.ssh && chmod 0700 ~/.ssh
                        ssh-keyscan -H ${HOSTNAME_DEPLOY_PROD} >> ~/.ssh/known_hosts 2>/dev/null
                        ssh ubuntu@${HOSTNAME_DEPLOY_PROD} "
                            echo \"$DOCKERHUB_AUTH_PSW\" | docker login -u $DOCKERHUB_AUTH_USR --password-stdin
                            docker pull $DOCKERHUB_AUTH_USR/$IMAGE_NAME:$IMAGE_TAG
                            docker rm -f webapp || true
                            docker run -d -p 80:5000 -e PORT=5000 --name webapp $DOCKERHUB_AUTH_USR/$IMAGE_NAME:$IMAGE_TAG
                        "
                    '''
                }
            }
        }
    }
    post {
        always {
            script {
                /* Use slackNotifier.groovy from shared library and provide current build result as parameter*/
                slackNotifier currentBuild.result
            }
        } 
    }
}
