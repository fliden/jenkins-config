# We discussed using a specific tag for stability/size, but 'lts' works too.
FROM jenkins/jenkins:lts

# [CRITICAL STEP 1] Switch to root to install system packages
USER root

# [CRITICAL STEP 2] Install the Docker CLI
# Without this, your agents will fail with "docker: command not found"
RUN apt-get update && \
    apt-get install -y docker.io && \
    rm -rf /var/lib/apt/lists/*

# [CRITICAL STEP 3] Switch back to Jenkins user for security/plugins
USER jenkins

# Copy plugin list
COPY plugins.txt /usr/share/jenkins/ref/plugins.txt

# Install plugins
RUN jenkins-plugin-cli --plugin-file /usr/share/jenkins/ref/plugins.txt

# Skip initial setup wizard
ENV JAVA_OPTS="-Djenkins.install.runSetupWizard=false"
