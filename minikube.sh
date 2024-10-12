#!/bin/bash

###################
## Author: Lexur ##
###################

check_distro() {
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        DISTRO=$ID
        PACKAGE_MANAGER=""
        if [[ -x "$(command -v apt)" ]]; then
            PACKAGE_MANAGER="apt"
        elif [[ -x "$(command -v dnf)" ]]; then
            PACKAGE_MANAGER="dnf"
        elif [[ -x "$(command -v yum)" ]]; then
            PACKAGE_MANAGER="yum"
        else
            echo "Unsupported package manager. Exiting."
            exit 1
        fi
    else
        echo "Unable to detect Linux distribution."
        exit 1
    fi
}


install_docker() {
    if command -v docker >/dev/null; then
        echo "Docker already installed."
    else
        echo "Installing Docker..."

        if [[ "$PACKAGE_MANAGER" == "apt-get" || "$PACKAGE_MANAGER" == "apt" ]]; then
            sudo $PACKAGE_MANAGER update -y
            sudo $PACKAGE_MANAGER install -y apt-transport-https ca-certificates curl software-properties-common
            curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
            sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
            sudo $PACKAGE_MANAGER update -y
            sudo $PACKAGE_MANAGER install -y docker-ce docker-ce-cli containerd.io
            sudo systemctl start docker
            sudo systemctl enable docker
        elif [[ "$PACKAGE_MANAGER" == "dnf" || "$PACKAGE_MANAGER" == "yum" ]]; then
            sudo $PACKAGE_MANAGER install -y dnf-plugins-core
            sudo $PACKAGE_MANAGER config-manager --add-repo https://download.docker.com/linux/fedora/docker-ce.repo
            sudo $PACKAGE_MANAGER install -y docker-ce docker-ce-cli containerd.io
            sudo systemctl start docker
            sudo systemctl enable docker
        else
            echo "Unsupported package manager for Docker installation."
            exit 1
        fi
    fi
    
}

install_kubectl() {
    if command -v kubectl >/dev/null 2>&1; then
        echo "Docker is already installed."
    else
        echo "Installing Kubectl..."
        curl -LO "https://storage.googleapis.com/kubernetes-release/release/$(curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt)/bin/linux/amd64/kubectl"
        chmod +x ./kubectl
        sudo mv ./kubectl /usr/local/bin/kubectl
    fi
}

install_minikube() {
    if command -v minikube >/dev/null 2>&1; then
        echo "Minikube already installed."
    else
        echo "Installing Minikube..."
        curl -LO https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64
        sudo install minikube-linux-amd64 /usr/local/bin/minikube
    fi
}

configure_minikube() {
    echo "Configuring Minikube..."
    minikube config set memory 4096
    minikube config set cpus 2
    minikube config set image-pull-timeout 300
}

clean_up() {
    echo "Cleaning up Docker and Minikube..."
    minikube delete
    docker system prune -f
}

start_minikube() {
    echo "Starting Minikube with Docker driver..."
    minikube start --driver=docker --docker-opt="default-ulimit=nofile=65536:65536"
}

check_minikube_status() {
    echo "Checking Minikube status..."
    minikube status

    echo "Fetching Minikube logs..."
    minikube logs
}

main() {
    check_distro
    install_docker
    install_kubectl
    install_minikube
    configure_minikube
    clean_up
    start_minikube
    check_minikube_status
}

# Run the script
main
