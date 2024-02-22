FROM jenkins

USER root

# Copy jenkins master based custom execution files
COPY lib/executors.groovy /usr/share/jenkins/ref/init.groovy.d/executors.groovy

RUN apt-get update && apt-get install -y jq python-pip python-dev build-essential \
    git-core nodejs logrotate
RUN gpg --keyserver hkp://pgp.mit.edu --recv-keys 409B6B1796C275462A1703113804BB82D39DC0E3 && \
  curl -L get.rvm.io | bash -s stable  && \
  echo 'source /var/jenkins_home/.rvm/scripts/rvm' >> /var/jenkins_home/.bashrc

RUN /bin/bash -l -c "source /var/jenkins_home/.rvm/scripts/rvm && rvm install 2.2.7 && chown jenkins -R /var/jenkins_home/.rvm/" && \
  echo 'source /var/jenkins_home/.rvm/scripts/rvm' >> /root/.bashrc
RUN python -m pip install --upgrade pip

USER jenkins

EXPOSE 8080 50000
