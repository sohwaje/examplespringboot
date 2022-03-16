node {
   stage('init') {
      checkout scm
   }
   stage('build') {
      sh '''
         /opt/maven/apache-maven-3.6.2/bin/mvn clean package
         cd target
         cp *.jar app.jar
         zip app.zip app.jar
      '''
   }
   stage('deploy') {
      azureWebAppPublish azureCredentialsId: env.AZURE_CRED_ID,
      /* webapp에 업로드할 때 zip이나 war 확장자로 업로드 해야 함. */
      resourceGroup: env.RES_GROUP, appName: env.WEB_APP, filePath: "**/app.zip"
    }
}
