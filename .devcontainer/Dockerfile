# Note: You can use any Debian/Ubuntu base image
FROM ghcr.io/retaildevcrews/dind
# FROM mcr.microsoft.com/vscode/devcontainers/base:focal

# Avoid warnings by switching to noninteractive
ENV DEBIAN_FRONTEND=noninteractive

# Configure apt and install packages
# Optional components
# uncomment any you want to install
RUN apt-get update && apt-get -y install nodejs 
RUN apt-get -y install python3


# uncomment these if you want terraform installed
RUN  apt-get update && sudo apt-get install -y gnupg software-properties-common curl 
RUN curl -fsSL https://apt.releases.hashicorp.com/gpg | sudo apt-key add - 
RUN  apt-add-repository "deb [arch=amd64] https://apt.releases.hashicorp.com $(lsb_release -cs) main" 
RUN  apt-get update && sudo apt-get -y install terraform


# Switch back to dialog for any ad-hoc use of apt-get
ENV DEBIAN_FRONTEND=dialog

# install selected components
# many scripts take optional parameters
# see the script header for details of each
RUN echo "👋 Welcome to your devcontainer for construction sets! You are on a custom image defined in your devcontainer.json file.\n" > /usr/local/etc/vscode-dev-containers/first-run-notice.txt 

