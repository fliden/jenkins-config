FROM jenkins/jenkins:lts

# Copy plugin list
COPY plugins.txt /usr/share/jenkins/ref/plugins.txt

# Install plugins
RUN jenkins-plugin-cli --plugin-file /usr/share/jenkins/ref/plugins.txt

# Skip initial setup wizard (also set in docker-compose for redundancy)
ENV JAVA_OPTS="-Djenkins.install.runSetupWizard=false"

# Set user back to jenkins
USER jenkins
