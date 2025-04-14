pipeline {
    agent none
    environment {
        DOCKERHUB_AUTH = credentials('docker')  // Prendre en compte l'identification Docker Hub
        ID_DOCKER = "${DOCKERHUB_AUTH_USR}"    // Utilisation du secret pour l'utilisateur Docker
        PORT_EXPOSED = "80"
        IMAGE_NAME = "alpinehelloworld"         // Définir IMAGE_NAME si ce n'est pas déjà défini
        IMAGE_TAG = "latest"                   // Définir IMAGE_TAG si ce n'est pas déjà défini
    }
    stages {
        stage('Build Image') {
            agent any
            steps {
                script {
                    echo "Building Docker image..."
                    sh 'docker build -t ${ID_DOCKER}/${IMAGE_NAME}:${IMAGE_TAG} .'
                }
            }
        }

        stage('Run container based on built image') {
            agent any
            steps {
                script {
                    echo "Cleaning up environment..."
                    // Supprimer le conteneur existant si nécessaire
                    sh '''
                        docker rm -f ${IMAGE_NAME} || echo "Container ${IMAGE_NAME} does not exist"
                        docker run --name ${IMAGE_NAME} -d -p ${PORT_EXPOSED}:5000 -e PORT=5000 ${ID_DOCKER}/${IMAGE_NAME}:${IMAGE_TAG}
                        sleep 5  # Temps d'attente pour s'assurer que l'application a démarré
                    '''
                }
            }
        }

        stage('Test image') {
            agent any
            steps {
                script {
                    echo "Testing the image..."
                    // Vérification de l'exécution du conteneur et test de la réponse HTTP
                    sh '''
                        docker ps  # Vérifier si le conteneur est en cours d'exécution

                        # Tester la connexion via localhost
                        curl http://127.0.0.1:${PORT_EXPOSED} | grep -q "Hello world Lewis!" || echo "Test failed: Response not as expected"
                    '''
                }
            }
        }

        stage('Clean Container') {
            agent any
            steps {
                script {
                    echo "Stopping and removing the container..."
                    // Arrêter et supprimer le conteneur
                    sh '''
                        docker stop ${IMAGE_NAME}
                        docker rm ${IMAGE_NAME}
                    '''
                }
            }
        }

        stage('Login and Push Image on Docker Hub') {
            agent any
            steps {
                script {
                    echo "Logging in to Docker Hub and pushing the image..."
                    // Se connecter à Docker Hub et pousser l'image
                    sh '''
                        docker login -u ${DOCKERHUB_AUTH_USR} -p ${DOCKERHUB_AUTH_PSW}
                        docker push ${ID_DOCKER}/${IMAGE_NAME}:${IMAGE_TAG}
                    '''
                }
            }
        }

        stage('Deploy in Staging') {
            agent any
            environment {
                HOSTNAME_DEPLOY_STAGING = "ec2-13-37-227-8.eu-west-3.compute.amazonaws.com"
            }
            steps {
                script {
                    sh '''
                        # Configurer les clés SSH manuellement
                        mkdir -p ~/.ssh
                        cp /path/to/your/private_key ~/.ssh/id_rsa
                        chmod 600 ~/.ssh/id_rsa
                        ssh-keyscan -t rsa,dsa ${HOSTNAME_DEPLOY_STAGING} >> ~/.ssh/known_hosts
                        
                        # Déployer l'application
                        command1="docker login -u ${DOCKERHUB_AUTH_USR} -p ${DOCKERHUB_AUTH_PSW}"
                        command2="docker pull ${DOCKERHUB_AUTH_USR}/${IMAGE_NAME}:${IMAGE_TAG}"
                        command3="docker rm -f webapp || echo 'App does not exist'"
                        command4="docker run -d -p 80:5000 -e PORT=5000 --name webapp ${DOCKERHUB_AUTH_USR}/${IMAGE_NAME}:${IMAGE_TAG}"
                        
                        ssh -t centos@${HOSTNAME_DEPLOY_STAGING} "$command1 && $command2 && $command3 && $command4"
                    '''
                }
            }
        }

        stage('Deploy in Prod') {
            agent any
            environment {
                HOSTNAME_DEPLOY_PROD = "ec2-15-237-191-5.eu-west-3.compute.amazonaws.com"
            }
            steps {
                sshagent(credentials: ['SSH_AUTH_PROD']) {
                    echo "Deploying to production server..."
                    sh '''
                        # Préparer l'environnement SSH
                        [ -d ~/.ssh ] || mkdir -p ~/.ssh && chmod 0700 ~/.ssh
                        ssh-keyscan -t rsa,dsa ${HOSTNAME_DEPLOY_PROD} >> ~/.ssh/known_hosts

                        # Déployer l'image sur le serveur de production
                        command1="docker login -u ${DOCKERHUB_AUTH_USR} -p ${DOCKERHUB_AUTH_PSW}"
                        command2="docker pull ${DOCKERHUB_AUTH_USR}/${IMAGE_NAME}:${IMAGE_TAG}"
                        command3="docker rm -f webapp || echo 'App does not exist'"
                        command4="docker run -d -p 80:5000 -e PORT=5000 --name webapp ${DOCKERHUB_AUTH_USR}/${IMAGE_NAME}:${IMAGE_TAG}"

                        ssh -t centos@${HOSTNAME_DEPLOY_PROD} \
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
}
