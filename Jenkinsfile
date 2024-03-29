pipeline {
  agent {
    node {
      label 'nodejs'
    }
  }

  parameters {
      string(name: 'PROJECT_VERSION', defaultValue: 'v1.0', description: '项目版本')
      string(name: 'PROJECT_NAME', defaultValue: 'gulimall-vue', description: '构建模块')
  }

  environment {
      DOCKER_CREDENTIAL_ID = 'aliyun-dockerhub-id'
      GITHUB_CREDENTIAL_ID = 'github-token'
      KUBECONFIG_CREDENTIAL_ID = 'kubeconfig'
      REGISTRY = 'registry.cn-hangzhou.aliyuncs.com'
      DOCKERHUB_NAMESPACE = '2399214024'
      GITHUB_ACCOUNT = 'CheneyKwok'
      SONAR_CREDENTIAL_ID = 'sonar-token'
      BRANCH_NAME='master'

  }


  stages {

    stage('拉取代码') {
      agent none
      steps {
        git(url: 'https://github.com/CheneyKwok/gulimall-vue.git', credentialsId: 'github-id', branch: 'master', changelog: true, poll: false)
      }
    }



    stage ('构建镜像 & 推送镜像') {
        steps {
            container ('nodejs') {
                sh 'npm install'
                sh 'npm run build'
                sh "docker build --no-cache -f Dockerfile -t $REGISTRY/$DOCKERHUB_NAMESPACE/$PROJECT_NAME:SNAPSHOT-$BRANCH_NAME-$BUILD_NUMBER ."
                withCredentials([usernamePassword(passwordVariable : 'DOCKER_PASSWORD' ,usernameVariable : 'DOCKER_USERNAME' ,credentialsId : "$DOCKER_CREDENTIAL_ID" ,)]) {
                    sh "echo $DOCKER_PASSWORD | docker login $REGISTRY -u $DOCKER_USERNAME --password-stdin"
                    sh "docker push  $REGISTRY/$DOCKERHUB_NAMESPACE/$PROJECT_NAME:SNAPSHOT-$BRANCH_NAME-$BUILD_NUMBER"
                }
            }
        }
    }

    stage('推送最新镜像'){
       steps{
            container ('nodejs') {
              sh "docker tag  $REGISTRY/$DOCKERHUB_NAMESPACE/$PROJECT_NAME:SNAPSHOT-$BRANCH_NAME-$BUILD_NUMBER $REGISTRY/$DOCKERHUB_NAMESPACE/$PROJECT_NAME:latest "
              sh "docker push  $REGISTRY/$DOCKERHUB_NAMESPACE/$PROJECT_NAME:latest"
            }
       }
    }


    stage('部署到集群') {

      steps {
        input(id: 'deploy-to-dev', message: "是否将 $PROJECT_NAME 部署到集群中?")
        kubernetesDeploy(configs: "deploy/k8s-deployment.yml", enableConfigSubstitution: true, kubeconfigId: "$KUBECONFIG_CREDENTIAL_ID")
      }
    }


    stage('发布版本'){
      when{
        expression{
          return params.PROJECT_VERSION =~ /v.*/
        }
      }
      steps {
          container ('nodejs') {
            input(id: 'release-image-with-tag', message: '发布当前版本镜像吗?')
              withCredentials([usernamePassword(credentialsId: "$GITHUB_CREDENTIAL_ID", passwordVariable: 'GIT_PASSWORD', usernameVariable: 'GIT_USERNAME')]) {
            sh '''
            t=$(git tag)
            v=$PROJECT_VERSION
            if [[ $t == *$v* ]]
            then
                echo "$v 版本已存在"
            else
                git config --global user.email "2399214024.com"
                git config --global user.name "cheneykwok"
                git tag -a $PROJECT_VERSION -m "$PROJECT_VERSION"
                git push http://$GIT_USERNAME:$GIT_PASSWORD@github.com/$GITHUB_ACCOUNT/gulimall-vue.git --tags --ipv4
            fi
            '''
              }
            sh 'docker tag  $REGISTRY/$DOCKERHUB_NAMESPACE/$PROJECT_NAME:SNAPSHOT-$BRANCH_NAME-$BUILD_NUMBER $REGISTRY/$DOCKERHUB_NAMESPACE/$PROJECT_NAME:$PROJECT_VERSION '
            sh 'docker push  $REGISTRY/$DOCKERHUB_NAMESPACE/$PROJECT_NAME:$PROJECT_VERSION '
      }
      }
    }



  }
}