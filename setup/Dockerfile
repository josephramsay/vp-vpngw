# Ubuntu Dockerfile
#
# https://github.com/dockerfile/ubuntu
#

# Pull base image.
FROM --platform=linux/amd64 ubuntu:latest

# Preset TZ data values
ENV TZ=Pacific/Auckland
ARG DEBIAN_FRONTEND=noninteractive

# Install.
RUN \
  sed -i 's/# \(.*multiverse$\)/\1/g' /etc/apt/sources.list && \
  apt-get update && \
  apt-get -y upgrade && \
  apt-get install -y build-essential && \
  apt-get install -y tzdata && \
  apt-get install -y software-properties-common && \
  apt-get install -y byobu curl git htop man unzip vim wget zsh && \
  rm -rf /var/lib/apt/lists/*

RUN curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip" && \
  unzip awscliv2.zip && \
  ./aws/install && \
  alias aws=awsv2

RUN apt-get update && \
  apt-get install -y gnupg software-properties-common curl && \
  curl -fsSL https://apt.releases.hashicorp.com/gpg | apt-key add - && \
  apt-add-repository "deb [arch=amd64] https://apt.releases.hashicorp.com $(lsb_release -cs) main" && \
  apt-get update && \
  apt-get install terraform && \
  terraform -install-autocomplete && \
  echo 'alias tf=terraform' >> ~/.zshrc && \
  echo 'alias ti="terraform init"' >> ~/.zshrc && \
  echo 'alias tp="terraform plan"' >> ~/.zshrc

RUN apt-get install jq wireguard
  
# Set environment variables.
ENV HOME /root

# Define working directory.
WORKDIR /root

# Define default command.
CMD ["zsh"]

