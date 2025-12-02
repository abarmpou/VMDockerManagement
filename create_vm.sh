#!/bin/bash


while [[ $# -gt 0 ]]; do
    case "$1" in
        -p|--password)
            if [[ -z "$2" || "$2" == -* ]]; then
                echo "Error: -p|--password requires an argument."
                exit 1
            fi
            default_password="$2"
            shift 2
            ;;
        -n|--name)
            if [[ -z "$2" || "$2" == -* ]]; then
                echo "Error: -n|--name requires an argument."
                exit 1
            fi
            name="$2"
            shift 2
            ;;
        --) # End of options
            shift
            break
            ;;
        -*)
            echo "Invalid option: $1"
            echo "Usage: $0 [-p password] [--password password] [-n name] [--name name]"
            exit 1
            ;;
        *)
            # No more options; break out to preserve positional args
            break
            ;;
    esac
done

if [ -n "$name" ]; then
    echo "A name was provided."
else
    echo "A name must be provided using [-n name] [--name name]"
    exit 1
fi

if [ -n "$default_password" ]; then
    echo "Password was provided."
else
    echo "A password must be provided using [-p password] [--password password]"
    exit 1
fi



# Check if Docker is installed
if ! command -v docker &> /dev/null; then
    echo "Docker is not installed. Installing docker..."
    apt-get update
    apt-get install docker
# The following line may be needed if you get an installation error message
#    apt-get install containerd=1.3.3-0ubuntu2
    apt install docker.io
    docker --version
fi

# Define the image name
image_name="ubuntu"

# Check if the Docker image exists
if docker images "$image_name" | grep "$image_name" >/dev/null; then
    echo "The Docker image '$image_name' exists. Checking for updates..."
    docker pull "$image_name:latest"
else
    echo "The Docker image '$image_name' does not exist. Pulling image..."
    docker pull "$image_name:latest"
fi

if docker image inspect "$name" > /dev/null 2>&1; then
    echo "Docker image '$name' exists. Remove it by: docker rmi '$name'"
    exit 1
else
    echo "Docker image '$name' does NOT exist."
fi


# Check if a local folder with the site_name exists
if [ -d "$name" ]; then
    echo "A local folder with the name '$name' exists. Please remove it."
    exit 1
else
    echo "Creating local folder '$name'..."
    mkdir -p "$name"/data
fi

port=2222
port_found=false

while [ "$port_found" = false ] && [ "$port" -lt 4223 ]; do
    if docker ps | grep ":$port" >/dev/null; then
        port=$((port + 100))
    else
        port_found=true
    fi
done

if [ "$port_found" = false ]; then
    echo "No available ports found in the range."
else
    echo "Available port: $port"
fi

current_directory=$(pwd)

cat <<EOF > $name/dockerfile
FROM ubuntu:latest

RUN apt update && \
    apt install -y openssh-server && \
    mkdir /var/run/sshd

# Set root password (change this!)
RUN echo "root:$default_password" | chpasswd

# Allow root login (or create a non-root user instead)
RUN sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin yes/' /etc/ssh/sshd_config

EXPOSE $port
CMD ["/usr/sbin/sshd", "-D"]
EOF

docker build -t $name $name
rm $name/dockerfile
docker run -d --restart=unless-stopped -v $current_directory/$name/data:/data -p $port:22 $name

echo "VM is running at port: $port"
echo "Access by: ssh root@localhost -p $port"

exit 1
