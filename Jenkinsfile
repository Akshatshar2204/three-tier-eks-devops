pipeline {
  agent {
    kubernetes {
      defaultContainer 'node'
      yaml '''
apiVersion: v1
kind: Pod
spec:
  serviceAccountName: jenkins-agent
  containers:
    - name: node
      image: node:24-bookworm-slim
      command: ["cat"]
      tty: true
      resources:
        requests:
          cpu: "100m"
          memory: "128Mi"
        limits:
          cpu: "1000m"
          memory: "1536Mi"

    - name: aws
      image: public.ecr.aws/aws-cli/aws-cli:latest
      command: ["cat"]
      tty: true
      resources:
        requests:
          cpu: "50m"
          memory: "64Mi"
        limits:
          cpu: "200m"
          memory: "256Mi"

    - name: git
      image: alpine/git:latest
      command: ["cat"]
      tty: true
      resources:
        requests:
          cpu: "50m"
          memory: "64Mi"
        limits:
          cpu: "200m"
          memory: "256Mi"

    - name: buildkit
      image: moby/buildkit:rootless
      command: ["cat"]
      tty: true
      env:
        - name: BUILDKITD_FLAGS
          value: "--oci-worker-no-process-sandbox"
      securityContext:
        runAsUser: 1000
        runAsGroup: 1000
        seccompProfile:
          type: Unconfined
        appArmorProfile:
          type: Unconfined
      resources:
        requests:
          cpu: "250m"
          memory: "256Mi"
        limits:
          cpu: "1500m"
          memory: "1536Mi"
    - name: trivy
      image: public.ecr.aws/aquasecurity/trivy:0.75.0
      command: ["cat"]
      tty: true
      resources:
        requests:
          cpu: "100m"
          memory: "64Mi"
        limits:
          cpu: "500m"
          memory: "1Gi"
'''
    }
  }

  options {
    skipDefaultCheckout(true)
    timeout(time: 45, unit: 'MINUTES')
    disableConcurrentBuilds()
  }

  triggers {
    pollSCM('H/5 * * * *')
  }

  environment {
    AWS_REGION = 'ap-south-1'
    AWS_ACCOUNT_ID = '828479100787'
    ECR_REGISTRY = '828479100787.dkr.ecr.ap-south-1.amazonaws.com'
    FRONTEND_REPO = '828479100787.dkr.ecr.ap-south-1.amazonaws.com/three-tier-eks-frontend'
    BACKEND_REPO = '828479100787.dkr.ecr.ap-south-1.amazonaws.com/three-tier-eks-backend'
    GITOPS_REPO_URL = 'https://github.com/Akshatshar2204/three-tier-eks-devops.git'
    IMAGE_TAG = "build-${BUILD_NUMBER}"
  }

  stages {
    stage('Checkout') {
      steps {
        container('git') {
          script {
            def scmInfo = checkout scm
            env.CHECKED_OUT_GIT_BRANCH = scmInfo.GIT_BRANCH ?: env.GIT_BRANCH ?: ''
            echo "SCM branch metadata: ${env.CHECKED_OUT_GIT_BRANCH ?: '<unset>'}"
          }
          sh '''
            git config --global --add safe.directory "$WORKSPACE"
            git rev-parse --short HEAD
          '''
        }
      }
    }

    stage('Test Backend') {
      steps {
        container('node') {
          dir('application-code/Application-Code/backend') {
            sh '''
              set -eu
              npm ci --no-audit --no-fund
              node --check index.js
              node --check db.js
              node --check routes/tasks.js
              node --check models/task.js
            '''
          }
        }
      }
    }

    stage('Build Frontend') {
      steps {
        container('node') {
          dir('application-code/Application-Code/frontend') {
            sh '''
              set -eu
              npm ci --no-audit --no-fund
              npm run build
            '''
          }
        }
      }
    }

    stage('Authenticate to ECR') {
      when {
        expression {
          def branch = env.CHECKED_OUT_GIT_BRANCH ?: env.GIT_BRANCH ?: env.BRANCH_NAME ?: ''
          if (branch.startsWith('refs/remotes/origin/')) {
            branch = branch.substring('refs/remotes/origin/'.length())
          }
          if (branch.startsWith('refs/heads/')) {
            branch = branch.substring('refs/heads/'.length())
          }
          if (branch.startsWith('origin/')) {
            branch = branch.substring('origin/'.length())
          }
          if (branch.startsWith('*/')) {
            branch = branch.substring(2)
          }
          branch == 'main'
        }
      }
      steps {
        container('aws') {
          sh '''
            set -eu
            set +x
            aws sts get-caller-identity
            mkdir -p "$WORKSPACE/.docker"
            ECR_PASSWORD="$(aws ecr get-login-password --region "$AWS_REGION")"
            ECR_AUTH="$(printf 'AWS:%s' "$ECR_PASSWORD" | base64 | tr -d '\\n')"
            printf '{"auths":{"%s":{"auth":"%s"}}}\\n' \
              "$ECR_REGISTRY" "$ECR_AUTH" > "$WORKSPACE/.docker/config.json"
            chown 1000:1000 "$WORKSPACE/.docker"
            chown 1000:1000 "$WORKSPACE/.docker/config.json"
            chmod 700 "$WORKSPACE/.docker"
            chmod 600 "$WORKSPACE/.docker/config.json"

            unset ECR_PASSWORD ECR_AUTH
          '''
        }
      }
    }

    stage('Build and Push Images') {
      when {
        expression {
          def branch = env.CHECKED_OUT_GIT_BRANCH ?: env.GIT_BRANCH ?: env.BRANCH_NAME ?: ''
          if (branch.startsWith('refs/remotes/origin/')) {
            branch = branch.substring('refs/remotes/origin/'.length())
          }
          if (branch.startsWith('refs/heads/')) {
            branch = branch.substring('refs/heads/'.length())
          }
          if (branch.startsWith('origin/')) {
            branch = branch.substring('origin/'.length())
          }
          if (branch.startsWith('*/')) {
            branch = branch.substring(2)
          }
          branch == 'main'
        }
      }
      steps {
        container('buildkit') {
          sh '''
            set -eu
            export DOCKER_CONFIG="$WORKSPACE/.docker"

            buildctl-daemonless.sh build \
              --frontend dockerfile.v0 \
              --local context="$WORKSPACE/application-code/Application-Code/frontend" \
              --local dockerfile="$WORKSPACE/application-code/Application-Code/frontend" \
              --opt filename=Dockerfile \
              --output "type=image,name=${FRONTEND_REPO}:${IMAGE_TAG},push=true" \
              --progress plain

            buildctl-daemonless.sh build \
              --frontend dockerfile.v0 \
              --local context="$WORKSPACE/application-code/Application-Code/backend" \
              --local dockerfile="$WORKSPACE/application-code/Application-Code/backend" \
              --opt filename=Dockerfile \
              --output "type=image,name=${BACKEND_REPO}:${IMAGE_TAG},push=true" \
              --progress plain
          '''
        }
      }
    }

    stage('Scan Images with Trivy') {
      when {
        expression {
          def branch = env.CHECKED_OUT_GIT_BRANCH ?: env.GIT_BRANCH ?: env.BRANCH_NAME ?: ''
          if (branch.startsWith('refs/remotes/origin/')) {
            branch = branch.substring('refs/remotes/origin/'.length())
          }
          if (branch.startsWith('refs/heads/')) {
            branch = branch.substring('refs/heads/'.length())
          }
          if (branch.startsWith('origin/')) {
            branch = branch.substring('origin/'.length())
          }
          if (branch.startsWith('*/')) {
            branch = branch.substring(2)
          }
          branch == 'main'
        }
      }
      steps {
        container('trivy') {
          sh '''
            set -eu
            export DOCKER_CONFIG="$WORKSPACE/.docker"

            trivy --version

            echo "Scanning frontend image..."
            trivy image \
              --scanners vuln \
              --severity HIGH,CRITICAL \
              --ignore-unfixed \
              --exit-code 1 \
              "${FRONTEND_REPO}:${IMAGE_TAG}"

            echo "Scanning backend image..."
            trivy image \
              --scanners vuln \
              --severity HIGH,CRITICAL \
              --ignore-unfixed \
              --exit-code 1 \
              "${BACKEND_REPO}:${IMAGE_TAG}"
          '''
        }
      }
    }

    stage('Remove ECR Token') {
      steps {
        container('aws') {
          sh 'rm -f "$WORKSPACE/.docker/config.json"; rmdir "$WORKSPACE/.docker" 2>/dev/null || true'
        }
      }
    }

    stage('Update GitOps Image Tags') {
      when {
        expression {
          def branch = env.CHECKED_OUT_GIT_BRANCH ?: env.GIT_BRANCH ?: env.BRANCH_NAME ?: ''
          if (branch.startsWith('refs/remotes/origin/')) {
            branch = branch.substring('refs/remotes/origin/'.length())
          }
          if (branch.startsWith('refs/heads/')) {
            branch = branch.substring('refs/heads/'.length())
          }
          if (branch.startsWith('origin/')) {
            branch = branch.substring('origin/'.length())
          }
          if (branch.startsWith('*/')) {
            branch = branch.substring(2)
          }
          branch == 'main'
        }
      }
      steps {
        container('git') {
          withCredentials([
            usernamePassword(
              credentialsId: 'github-https',
              usernameVariable: 'GIT_USERNAME',
              passwordVariable: 'GIT_TOKEN'
            )
          ]) {
            sh '''
              set -eu
              git config --global --add safe.directory "$WORKSPACE"

              git config user.name "Jenkins CI"
              git config user.email "akshatshar2204@users.noreply.github.com"

              cat > /tmp/git-askpass.sh <<'ASKPASS'
#!/bin/sh
case "$1" in
  *Username*) printf '%s\\n' "$GIT_USERNAME" ;;
  *Password*) printf '%s\\n' "$GIT_TOKEN" ;;
  *) exit 1 ;;
esac
ASKPASS

              chmod 700 /tmp/git-askpass.sh
              export GIT_ASKPASS=/tmp/git-askpass.sh
              export GIT_TERMINAL_PROMPT=0

              git remote set-url origin "$GITOPS_REPO_URL"
              git fetch origin gitops
              git checkout -B gitops origin/gitops

              sed -i -E "s/^([[:space:]]*tag:[[:space:]]*).*/\\1${IMAGE_TAG}/" \
                helm/three-tier-app/values.yaml

              if git diff --quiet -- helm/three-tier-app/values.yaml; then
                echo "GitOps image tags are already current."
              else
                git add helm/three-tier-app/values.yaml
                git commit -m "Deploy application images ${IMAGE_TAG}"
                git push origin HEAD:gitops
              fi

              rm -f /tmp/git-askpass.sh
            '''
          }
        }
      }
    }
  }

  post {
    always {
      echo 'Pipeline finished. The Kubernetes agent pod will be cleaned up by Jenkins.'
    }
  }
}
