pipeline {
    agent none
    environment {
        DOCKERHUB_AUTH_PSW = credentials('DOCKERHUB_AUTH')
        ID_DOCKER = "${DOCKERHUB_AUTH_USR}"
        PORT_EXPOSED = "80"
    }
    stages {
        stage ('Build Image') {
            agent any
            steps {
                script {
                    sh 'docker build -t ${ID_DOCKER}/${IMAGE_NAME}:${IMAGE_TAG} .'
                }
            }
        }

        stage('Run container based on builded image') {
            agent any
            steps {
               script {
                 sh '''
                    echo "Clean Environment"
                    docker rm -f $IMAGE_NAME || echo "container does not exist"
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

        stage ('Login and Push Image on dockerhub') {
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

        stage ('Deploy in staging') {
            agent any
            environment {
                HOSTNAME_DEPLOY_STAGING = "ec2-18-215-143-212.compute-1.amazonaws.com"
            }
            steps {
              script{
                    echo "deploying to shell-script to ec2"
                    def pullcmd="docker pull ${ID_DOCKER}/${IMAGE_NAME}:${IMAGE_TAG}"
                    def stopcmd=" docker stop ${IMAGE_NAME} || echo 'Container not running'"
                    def rmvcmd=" docker rm ${IMAGE_NAME} || echo 'Container not found'"
                    def runcmd="docker run -d -p $PORT_EXPOSED:5000 -e PORT=5000 --name ${IMAGE_NAME} ${ID_DOCKER}/${IMAGE_NAME}:${IMAGE_TAG}"
                    sshagent(['SSH_AUTH_SERVER']){
                       sh "ssh -o StrictHostKeyChecking=no ubuntu@${HOSTNAME_DEPLOY_STAGING} ${stopcmd}"
                       sh "ssh -o StrictHostKeyChecking=no ubuntu@${HOSTNAME_DEPLOY_STAGING} ${rmvcmd}"
                       sh "ssh -o StrictHostKeyChecking=no ubuntu@${HOSTNAME_DEPLOY_STAGING} ${pullcmd}"
                       sh "ssh -o StrictHostKeyChecking=no ubuntu@${HOSTNAME_DEPLOY_STAGING} ${runcmd}"
              }
            }
        }

        stage ('Deploy in prod') {
            agent any
            environment {
                HOSTNAME_DEPLOY_PROD = "ec2-52-71-142-24.compute-1.amazonaws.com"
            }
            steps {
              script{
                    echo "deploying to shell-script to ec2"
                    def pullcmd="docker pull ${ID_DOCKER}/${IMAGE_NAME}:${IMAGE_TAG}"
                    def stopcmd=" docker stop ${IMAGE_NAME} || echo 'Container not running'"
                    def rmvcmd=" docker rm ${IMAGE_NAME} || echo 'Container not found'"
                    def runcmd="docker run -d -p $PORT_EXPOSED:5000 -e PORT=5000 --name ${IMAGE_NAME} ${ID_DOCKER}/${IMAGE_NAME}:${IMAGE_TAG}"
                    sshagent(['SSH_AUTH_SERVER']){
                       sh "ssh -o StrictHostKeyChecking=no ubuntu@${HOSTNAME_DEPLOY_STAGING} ${stopcmd}"
                       sh "ssh -o StrictHostKeyChecking=no ubuntu@${HOSTNAME_DEPLOY_STAGING} ${rmvcmd}"
                       sh "ssh -o StrictHostKeyChecking=no ubuntu@${HOSTNAME_DEPLOY_STAGING} ${pullcmd}"
                       sh "ssh -o StrictHostKeyChecking=no ubuntu@${HOSTNAME_DEPLOY_STAGING} ${runcmd}"
              }

    }
}
