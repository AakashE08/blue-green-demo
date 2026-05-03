pipeline {
    agent any
    parameters {
        choice(
            name: 'DEPLOY_COLOR',
            choices: ['blue', 'green'],
            description: 'Which color slot to deploy?'
        )
        booleanParam(
            name: 'SWITCH_TRAFFIC',
            defaultValue: false,
            description: 'Switch live traffic to new slot?'
        )
    }
    environment {
        DOCKER_HUB_USER = 'aakash888'
        KUBECONFIG      = '/var/lib/jenkins/.kube/config'
        BLUE_IMAGE      = "${DOCKER_HUB_USER}/blue-app"
        GREEN_IMAGE     = "${DOCKER_HUB_USER}/green-app"
        MASTER_PRIVATE_IP = '172.31.45.159'
    }
    stages {
        stage('Fix Kubeconfig') {
            steps {
                sh """
                    sudo sed -i "s|https://.*:6443|https://${MASTER_PRIVATE_IP}:6443|" ${KUBECONFIG}
                    sudo sed -i '/certificate-authority-data/d' ${KUBECONFIG}
                    grep -q 'insecure-skip-tls-verify' ${KUBECONFIG} || \
                        sudo sed -i '/server:/a\\    insecure-skip-tls-verify: true' ${KUBECONFIG}
                    echo 'Kubeconfig updated!'
                    kubectl get nodes --kubeconfig=${KUBECONFIG}
                """
            }
        }
        stage('Checkout') {
            steps {
                git branch: 'main',
                    credentialsId: 'github-credentials',
                    url: 'https://github.com/AakashE08/blue-green-demo.git'
                echo "Deploying: ${params.DEPLOY_COLOR} | Switch Traffic: ${params.SWITCH_TRAFFIC}"
            }
        }
        stage('Build Blue') {
            when { expression { params.DEPLOY_COLOR == 'blue' } }
            steps {
                sh "docker build -t ${BLUE_IMAGE}:${BUILD_NUMBER} ./app-blue"
                sh "docker tag ${BLUE_IMAGE}:${BUILD_NUMBER} ${BLUE_IMAGE}:latest"
            }
        }
        stage('Build Green') {
            when { expression { params.DEPLOY_COLOR == 'green' } }
            steps {
                sh "docker build -t ${GREEN_IMAGE}:${BUILD_NUMBER} ./app-green"
                sh "docker tag ${GREEN_IMAGE}:${BUILD_NUMBER} ${GREEN_IMAGE}:latest"
            }
        }
        stage('Push Image') {
            steps {
                withCredentials([usernamePassword(
                    credentialsId: 'dockerhub-credentials',
                    usernameVariable: 'DOCKER_USER',
                    passwordVariable: 'DOCKER_PASS'
                )]) {
                    sh 'docker login -u $DOCKER_USER -p $DOCKER_PASS'
                    script {
                        if (params.DEPLOY_COLOR == 'blue') {
                            sh "docker push ${BLUE_IMAGE}:${BUILD_NUMBER}"
                            sh "docker push ${BLUE_IMAGE}:latest"
                        } else {
                            sh "docker push ${GREEN_IMAGE}:${BUILD_NUMBER}"
                            sh "docker push ${GREEN_IMAGE}:latest"
                        }
                    }
                    sh 'docker logout'
                }
            }
        }
        stage('Deploy') {
            steps {
                script {
                    if (params.DEPLOY_COLOR == 'blue') {
                        sh """
                            kubectl apply --validate=false -f k8s/blue-deployment.yaml --kubeconfig=${KUBECONFIG}
                            kubectl apply --validate=false -f k8s/service.yaml --kubeconfig=${KUBECONFIG}
                            kubectl set image deployment/app-blue app=${BLUE_IMAGE}:${BUILD_NUMBER} --kubeconfig=${KUBECONFIG}
                            kubectl rollout status deployment/app-blue --timeout=120s --kubeconfig=${KUBECONFIG}
                        """
                    } else {
                        sh """
                            kubectl apply --validate=false -f k8s/green-deployment.yaml --kubeconfig=${KUBECONFIG}
                            kubectl set image deployment/app-green app=${GREEN_IMAGE}:${BUILD_NUMBER} --kubeconfig=${KUBECONFIG}
                            kubectl rollout status deployment/app-green --timeout=120s --kubeconfig=${KUBECONFIG}
                        """
                    }
                }
            }
        }
        stage('Health Check') {
            when { expression { params.DEPLOY_COLOR == 'green' } }
            steps {
                sh """
                    echo 'Waiting for Green pods...'
                    sleep 20
                    GREEN_POD=\$(kubectl get pods -l app=demo-app,slot=green \
                        --kubeconfig=${KUBECONFIG} \
                        -o jsonpath='{.items[0].metadata.name}')
                    echo "Testing pod: \$GREEN_POD"
                    kubectl port-forward \$GREEN_POD 8888:3000 \
                        --kubeconfig=${KUBECONFIG} &
                    PF_PID=\$!
                    sleep 5
                    HEALTH=\$(curl -s http://localhost:8888/health | \
                        python3 -c "import sys,json; print(json.load(sys.stdin)['status'])")
                    kill \$PF_PID || true
                    echo "Health status: \$HEALTH"
                    if [ "\$HEALTH" = "healthy" ]; then
                        echo "GREEN HEALTH CHECK PASSED!"
                    else
                        echo "GREEN HEALTH CHECK FAILED!"
                        exit 1
                    fi
                """
            }
        }
        stage('Switch Traffic') {
            when {
                allOf {
                    expression { params.DEPLOY_COLOR == 'green' }
                    expression { params.SWITCH_TRAFFIC == true }
                }
            }
            steps {
                sh """
                    echo 'Switching traffic to GREEN...'
                    kubectl patch service demo-app-service \
                        -p '{"spec":{"selector":{"app":"demo-app","slot":"green"}}}' \
                        --kubeconfig=${KUBECONFIG}
                    echo 'Traffic switched to GREEN!'
                    kubectl get svc demo-app-service --kubeconfig=${KUBECONFIG}
                """
            }
        }
        stage('Verify') {
            steps {
                sh """
                    kubectl get deployments --kubeconfig=${KUBECONFIG}
                    kubectl get pods -l app=demo-app --kubeconfig=${KUBECONFIG}
                    kubectl get svc demo-app-service --kubeconfig=${KUBECONFIG}
                """
            }
        }
    }
    post {
        failure {
            sh """
                sudo sed -i "s|https://.*:6443|https://${MASTER_PRIVATE_IP}:6443|" ${KUBECONFIG} || true
                kubectl patch service demo-app-service \
                    -p '{"spec":{"selector":{"app":"demo-app","slot":"blue"}}}' \
                    --kubeconfig=${KUBECONFIG} || true
                kubectl scale deployment app-green --replicas=0 \
                    --kubeconfig=${KUBECONFIG} || true
            """
            echo 'FAILED! Rolled back to Blue.'
        }
        success {
            echo "SUCCESS! Access at http://98.86.229.154:30090"
        }
        always { cleanWs() }
    }
}
