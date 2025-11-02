FROM jenkins/jenkins:lts

# Skip setup wizard
ENV JAVA_OPTS=-Djenkins.install.runSetupWizard=false

# Install Docker CLI
USER root
RUN apt-get update && \
    apt-get install -y docker.io && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Install kubectl
RUN curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl" && \
    chmod +x kubectl && \
    mv kubectl /usr/local/bin/

# Copy plugins list and install plugins
USER jenkins
COPY plugins.txt /usr/share/jenkins/ref/plugins.txt
RUN jenkins-plugin-cli --plugin-file /usr/share/jenkins/ref/plugins.txt

# Copy init scripts
USER root
COPY init.groovy.d /usr/share/jenkins/ref/init.groovy.d/

# Copy Job DSL files
COPY jobs /var/jenkins_home/whanos-jenkins/jobs/

USER jenkins
