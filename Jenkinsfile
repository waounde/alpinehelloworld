@Library('shared-library@main')
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
        stage('Build images') {
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
                        echo "Clean Environment"
                        docker ps -a | grep -q $IMAGE_NAME && docker rm -f $IMAGE_NAME || echo "Container does not exist"
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
                        curl http://172.17.0.1:${PORT_EXPOSED} | grep -q "Hello world!"
                    '''
                }
            }
        }

        stage('Clean Container') {
            agent any
            steps {
                script {
                    sh '''
                        docker stop $IMAGE_NAME
                        docker rm $IMAGE_NAME
                    '''
                }
            }
        }

        stage('Login and Push Image on Docker Hub') {
            agent any
            steps {
                script {
                    sh '''
                        docker login -u $DOCKERHUB_AUTH_USR -p $DOCKERHUB_AUTH_PSW
                        docker push ${ID_DOCKER}/$IMAGE_NAME:$IMAGE_TAG
                    '''
                }
            }
        }

        stage('Deploy in staging') {
            agent any
            environment {
                HOSTNAME_DEPLOY_STAGING = "16.170.225.83"
            }
            steps {
                sshagent(credentials: ['SSH_AUTH_SERVER']) {
                    sh '''
                        [ -d ~/.ssh ] || mkdir ~/.ssh && chmod 0700 ~/.ssh
                        ssh-keyscan -t rsa,dsa ${HOSTNAME_DEPLOY_STAGING} >> ~/.ssh/known_hosts
                        command1="docker login -u $DOCKERHUB_AUTH_USR -p $DOCKERHUB_AUTH_PSW"
                        command2="docker pull $DOCKERHUB_AUTH_USR/$IMAGE_NAME:$IMAGE_TAG"
                        command3="docker rm -f webapp || echo 'app does not exist'"
                        command4="docker run -d -p 80:5000 -e PORT=5000 --name webapp $DOCKERHUB_AUTH_USR/$IMAGE_NAME:$IMAGE_TAG"
                        ssh -t ubuntu@${HOSTNAME_DEPLOY_STAGING} \
                            -o SendEnv=IMAGE_NAME \
                            -o SendEnv=IMAGE_TAG \
                            -o SendEnv=DOCKERHUB_AUTH_USR \
                            -o SendEnv=DOCKERHUB_AUTH_PSW \
                            -C "$command1 && $command2 && $command3 && $command4"
                    '''
                }
            }
        }

        stage('Deploy in prod') {
            agent any
            environment {
                HOSTNAME_DEPLOY_PROD = "56.228.42.215"
            }
            steps {
                sshagent(credentials: ['SSH_AUTH_SERVER']) {
                    sh '''
                        [ -d ~/.ssh ] || mkdir ~/.ssh && chmod 0700 ~/.ssh
                        ssh-keyscan -t rsa,dsa ${HOSTNAME_DEPLOY_PROD} >> ~/.ssh/known_hosts
                        command1="docker login -u $DOCKERHUB_AUTH_USR -p $DOCKERHUB_AUTH_PSW"
                        command2="docker pull $DOCKERHUB_AUTH_USR/$IMAGE_NAME:$IMAGE_TAG"
                        command3="docker rm -f webapp || echo 'app does not exist'"
                        command4="docker run -d -p 80:5000 -e PORT=5000 --name webapp $DOCKERHUB_AUTH_USR/$IMAGE_NAME:$IMAGE_TAG"
                        ssh -t ubuntu@${HOSTNAME_DEPLOY_PROD} \
                            -o SendEnv=IMAGE_NAME \
                            -o SendEnv=IMAGE_TAG \
                            -o SendEnv=DOCKERHUB_AUTH_USR \
                            -o SendEnv=DOCKERHUB_AUTH_PSW \
                            -C "$command1 && $command2 && $command3 && $command4"
                    '''
                }
            }
        }
    }
    post {
        always {
            script {
                /* Utilisation de slackNotifier.groovy depuis la bibliothèque partagée et en passant le résultat actuel du build comme paramètre */
                slackNotifier currentBuild.result
            }
        }
    }
}
