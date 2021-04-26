pipeline {
  agent {
    dockerfile {
      label 'docker'
      additionalBuildArgs '--build-arg K_COMMIT="$(cd deps/wasm-semantics/deps/k && git tag --points-at HEAD | cut --characters=2-)" --build-arg USER_ID=$(id -u) --build-arg GROUP_ID=$(id -g)'

    }
  }
  options { ansiColor('xterm') }
  stages {
    stage('Init title') {
      when { changeRequest() }
      steps { script { currentBuild.displayName = "PR ${env.CHANGE_ID}: ${env.CHANGE_TITLE}" } }
    }
    stage('Build') {
      parallel {
        stage('Semantics') { steps { sh 'make build RELEASE=true' } }
      }
    }
    stage('Test') {
      options { timeout(time: 30, unit: 'MINUTES') }
      parallel {
        stage('Unit Test')                   { steps { sh 'make TEST_CONCRETE_BACKEND=llvm test-simple -j4' } }
        stage('Unit Test Python')            { steps { sh 'make TEST_CONCRETE_BACKEND=llvm unittest-python' } }
        stage('Mandos Unit Test')            { steps { sh 'make TEST_CONCRETE_BACKEND=llvm mandos-test -j4' } }
        stage('Mandos Coverage Test')        { steps { sh 'make TEST_CONCRETE_BACKEND=llvm mandos-coverage' } }
        stage('Adder Contract Test')         { steps { sh 'make TEST_CONCRETE_BACKEND=llvm test-elrond-adder' } }
        stage('Lottery Contract Test')       { steps { sh 'make TEST_CONCRETE_BACKEND=llvm test-elrond-lottery-egld' } }
        stage('Multisig Contract Test')      { steps { sh 'make TEST_CONCRETE_BACKEND=llvm test-elrond-multisig' } }
        stage('Basic Features Test')         { steps { sh 'make TEST_CONCRETE_BACKEND=llvm test-elrond-basic-features' } }
        stage('Crowdfunding Contract Test')  { steps { sh 'make TEST_CONCRETE_BACKEND=llvm test-elrond-crowdfunding-egld' } }
      }
    }
  }
}
