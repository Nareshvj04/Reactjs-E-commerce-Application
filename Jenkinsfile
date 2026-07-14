pipeline {
    agent any
    
    environment {
        DOCKER_CREDS      = credentials('dockerhub-creds')
        DOCKER_USER       = 'nareshvj04'
        TARGET_SERVER_IP  = '52.66.171.197'
        TARGET_SSH_USER   = 'ec2-user'                    
        SSH_KEY_ID        = 'mykey'
    }
    
    stages {
        stage('Determine Environment & Build') {
            steps {
                script {
                    // Automatically track branch contexts
                    env.BRANCH = env.BRANCH_NAME ?: sh(script: "git rev-parse --abbrev-ref HEAD", returnStdout: true).trim()
                    echo "Processing pipeline execution for branch: ${env.BRANCH}"
                    
                    // Set target registry destination tags based on branch rules
                    if (env.BRANCH == 'dev') {
                        env.IMAGE_TAG = "${DOCKER_USER}/dev:latest"
                    } else if (env.BRANCH == 'main') {
                        env.IMAGE_TAG = "${DOCKER_USER}/prod:latest"
                    } else {
                        env.IMAGE_TAG = "${DOCKER_USER}/dev:${env.BRANCH}"
                    }
                }
                // Build the image locally on Jenkins Controller
                sh "chmod +x build.sh && ./build.sh"
            }
        }
        
        stage('Push to Registry') {
            steps {
                // Securely log into DockerHub and push the image built in the previous stage
                sh "echo \$DOCKER_CREDS_PSW | docker login -u \$DOCKER_CREDS_USR --password-stdin"
                script {


            		def repoName = (env.BRANCH_NAME == 'main') ? 'prod' : 'dev'
            		sh "docker push nareshvj04/${repoName}:latest"
			//if (env.BRANCH_NAME == 'dev') {
               
                	//	sh "docker push \$DOCKER_USER/dev:latest"
			//} else if (env.BRANCH_NAME == 'main') {
                
                	//	sh "docker push \$DOCKER_USER/prod:latest"
			//}
			}
				
            }
        }
        
        stage('Remote Deploy via Docker Compose') {
            steps {
                // Initialize the secure SSH agent context
                sshagent(credentials: [env.SSH_KEY_ID]) {
                    
                    // Step 1: Copy your local project docker-compose.yml directly to the remote server root
                    sh "ssh -o StrictHostKeyChecking=no ${env.TARGET_SSH_USER}@${env.TARGET_SERVER_IP} 'mkdir -p ~/app'"
                    sh "scp -o StrictHostKeyChecking=no docker-compose.yml ${env.TARGET_SSH_USER}@${env.TARGET_SERVER_IP}:~/app/docker-compose.yml"
                    
                    // Step 2: Execute remote terminal deployment using an SSH Heredoc block
                    sh """
                    ssh -o StrictHostKeyChecking=no ${env.TARGET_SSH_USER}@${env.TARGET_SERVER_IP} << 'EOF'
                        cd ~/app
                        
                        # Authenticate the remote daemon session to download images safely
                        echo "${DOCKER_CREDS_PSW}" | docker login -u "${DOCKER_CREDS_USR}" --password-stdin
                        
                        # Export variables explicitly to pass them into the remote docker compose runtime context
                        export DOCKER_USER="${env.DOCKER_USER}"
			export REPO_NAME="${env.BRANCH == 'main' ? 'prod' : 'dev'}"
                        export HOST_PORT="${env.BRANCH == 'main' ? '8000' : '80'}"

                        // export TAG="${env.BRANCH == 'main' ? 'prod' : 'dev'}"
                        
                        echo "Pulling fresh updates from registry targeting: \$DOCKER_USER/\$REPO_NAME:latest"
                        docker-compose pull
                        
                        echo "Bouncing containers gracefully..."
                        docker-compose down --remove-orphans
                        docker-compose up -d
                        
                        echo "Cleaning up outdated, dangling local images from the system cache..."
                        docker image prune -f
                        
                        echo "Remote deployment successfully executed!"
EOF
                    """
                }
            }
        }
    }
    
    post {
        always {
            // Clean up the local Jenkins workspace to save disk space
            cleanWs()
        }
    }
}

