pipeline {
    agent any

    environment {
        IMAGE_NAME = "phuhuynh197/projectscgh-devsecops"
        IMAGE_TAG  = "latest"
    }

    options {
        timestamps()
        disableConcurrentBuilds()
    }

    stages {

        stage("Checkout") {
            steps {
                cleanWs()
                checkout scm
                bat "if not exist security mkdir security"
            }
        }

        stage("Docker Login") {
            steps {
                withCredentials([usernamePassword(
                    credentialsId: 'dockerhub-creds',
                    usernameVariable: 'DOCKER_USER',
                    passwordVariable: 'DOCKER_PASS'
                )]) {
                    bat '''
                    echo %DOCKER_PASS% | docker login -u %DOCKER_USER% --password-stdin
                    '''
                }
            }
        }

        stage("Hadolint") {
            steps {
                bat '''
                docker run --rm -i hadolint/hadolint < Dockerfile > security/hadolint.txt || exit /b 0
                '''
            }
        }

        stage("Build Image") {
            steps {
                bat '''
                docker build -t %IMAGE_NAME%:%IMAGE_TAG% .
                '''
            }
        }

        stage("Push Image To DockerHub") {
            steps {
                bat '''
                docker push %IMAGE_NAME%:%IMAGE_TAG%
                '''
            }
        }

        stage("Gitleaks") {
            steps {
                bat '''
                docker run --rm -v "%cd%:/repo" zricethezav/gitleaks:latest detect ^
                  --source="/repo" ^
                  --report-format json ^
                  --report-path="/repo/security/gitleaks.json" ^
                  --exit-code 0 ^
                  --no-banner
                '''
            }
        }

        stage("Trivy Config") {
            steps {
                bat '''
                docker run --rm -v "%cd%:/workdir" aquasec/trivy:latest config /workdir ^
                  --format json ^
                  --output /workdir/security/trivy-config.json || exit /b 0
                '''
            }
        }

        stage("Trivy Image") {
            steps {
                bat '''
                docker run --rm ^
                  -v "%cd%:/workdir" ^
                  aquasec/trivy:latest image %IMAGE_NAME%:%IMAGE_TAG% ^
                  --scanners vuln ^
                  --severity HIGH,CRITICAL ^
                  --format json ^
                  --output /workdir/security/trivy-image.json || exit /b 0
                '''
            }
        }
        
        stage("Grype") {
            steps {
                bat '''
                docker run --rm anchore/grype:latest ^
                  registry:%IMAGE_NAME%:%IMAGE_TAG% ^
                  -o json > security/grype.json || exit /b 0
                '''
            }
        }
        
        stage("Dockle") {
            steps {
                bat '''
                docker run --rm goodwithtech/dockle:latest ^
                  --format json ^
                  %IMAGE_NAME%:%IMAGE_TAG% > security/dockle.json || exit /b 0
                '''
            }
        }

        stage("Resolve Maven Dependencies") {
            steps {
                bat '''
                docker run --rm ^
                  -v "%cd%:/app" ^
                  -w /app ^
                  maven:3.9-eclipse-temurin-17 ^
                  mvn -B -DskipTests dependency:copy-dependencies
                '''
            }
        }
        
        stage("Dependency-Check") {
            steps {
                withCredentials([
                    string(credentialsId: 'nvd-api-key', variable: 'NVD_API_KEY')
                ]) {
                    bat '''
                    docker run --rm ^
                      -v "%cd%:/src" ^
                      -v dependency-check-data:/usr/share/dependency-check/data ^
                      owasp/dependency-check:latest ^
                      --project "%JOB_NAME%" ^
                      --scan /src/target/dependency ^
                      --format HTML ^
                      --out /src/security ^
                      --nvdApiKey %NVD_API_KEY% ^
                      --failOnCVSS 11
                    '''
                }
            }
        }

        stage("Publish Artifacts") {
            steps {
                archiveArtifacts artifacts: "security/**", fingerprint: true
            }
        }

        stage("Publish Dependency-Check HTML") {
            steps {
                publishHTML(target: [
                    reportDir: 'security',
                    reportFiles: 'dependency-check-report.html',
                    reportName: 'OWASP Dependency-Check Report',
                    keepAll: true,
                    alwaysLinkToLastBuild: true,
                    allowMissing: false
                ])
            }
        }

        stage("Fail On Critical") {
            steps {
                bat '''
                setlocal EnableDelayedExpansion
                set found=0
        
                if exist security\\trivy-image.json findstr /I "\"CRITICAL\"" security\\trivy-image.json >nul && set found=1
                if exist security\\grype.json       findstr /I "\"Critical\""  security\\grype.json >nul && set found=1
                if exist security\\dockle.json      findstr /I "\"FATAL\""     security\\dockle.json >nul && set found=1
        
                if exist security\\dependency-check-report.html (
                  findstr /I "Vulnerabilities Found: 0" security\\dependency-check-report.html >nul || set found=1
                )
        
                if "!found!"=="1" exit /b 1
                exit /b 0
                '''
            }
        }
    }
    
    post {
        always {
            echo "Jenkins DevSecOps Pipeline Finished"
        }

        success {
            echo "Build SUCCESS"
        }

        failure {
            echo "Build FAILED due to SECURITY"
        }
    }
}
