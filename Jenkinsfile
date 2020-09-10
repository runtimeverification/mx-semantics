pipeline {
  agent {
    dockerfile {
      label 'docker'
      additionalBuildArgs '--build-arg K_COMMIT=$(cd deps/wasm-semantics/deps/k && git rev-parse --short=7 HEAD) --build-arg USER_ID=$(id -u) --build-arg GROUP_ID=$(id -g)'
    }
  }
  options { ansiColor('xterm') }
  stages {
    stage('Init title') {
      when { changeRequest() }
      steps { script { currentBuild.displayName = "PR ${env.CHANGE_ID}: ${env.CHANGE_TITLE}" } }
    }
    stage('Build') { steps { sh 'make build RELEASE=true' } }
    stage('Test') {
      options { timeout(time: 5, unit: 'MINUTES') }
      parallel {
        stage('Unit Test')   { steps { sh 'make TEST_CONCRETE_BACKEND=llvm test-simple -j4' } }
        stage('Mandos Test') { steps { sh 'make TEST_CONCRETE_BACKEND=llvm elrond-test -j4' } }
      }
    }
  }
}
