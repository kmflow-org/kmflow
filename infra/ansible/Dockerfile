FROM geerlingguy/docker-ubuntu2204-ansible:latest
RUN apt-get update -y \
    && apt-get install -y curl unzip \
    && pip3 install botocore boto3 \
    && curl "https://s3.amazonaws.com/session-manager-downloads/plugin/latest/ubuntu_64bit/session-manager-plugin.deb" -o "session-manager-plugin.deb" \
    && dpkg -i session-manager-plugin.deb
