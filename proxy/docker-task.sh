#!/bin/bash
# Helper scripts for working with Docker image and container.
# Variables
: "${PROJECT_NAME:=wedding}"  # Used in resource naming
ECR_app_repo="${PROJECT_NAME}-proxy"
IMAGE_NAME=$ECR_app_repo
CONTAINER_NAME=$IMAGE_NAME
AWS_REGION="eu-west-2"



# Get AWS Account ID
accountid=$(aws sts get-caller-identity --query Account --output text)

echo "Image Name: $IMAGE_NAME"

REPOSITORY_PATH="${accountid}.dkr.ecr.${AWS_REGION}.amazonaws.com"
FULLY_QUALIFIED_IMAGE_NAME="${REPOSITORY_PATH}/${ECR_app_repo}"

echo -e "\nFully Qualified Image Name: $FULLY_QUALIFIED_IMAGE_NAME"

HOST_PORT=9999
CONTAINER_PORT=8000  # Check Dockerfile for exposed port!

IMAGE_VERSION="${2:-latest}"  # Default to 'latest' if no version is provided

# Builds the Docker image and tags it with the specified version, utilizing cache if possible.
buildImage () {
    local tag="${1:-latest}"
    echo "Building Image Version: $tag ..."

    docker build --platform=linux/amd64 \
        --cache-from "${IMAGE_NAME}:latest" \
        -t "${IMAGE_NAME}:${tag}" \
        ./ 

    if [ $? -ne 0 ]; then
        echo "Build failed. Exiting."
        exit 1
    fi
    docker tag "${IMAGE_NAME}:${tag}" "${IMAGE_NAME}:latest"
    echo "Build complete."
}

# Runs the container locally.
runContainer () {
    docker run --rm \
        --name "$CONTAINER_NAME" \
        -p "${HOST_PORT}:${CONTAINER_PORT}" \
        -e "NODE_ENV=development" \
        -d "${IMAGE_NAME}:${IMAGE_VERSION}"
    echo "Container started. Open browser at http://localhost:${HOST_PORT}."
}

# Pushes the image with the specified tag to ECR.
pushImage () {
    local tag="${1:-latest}"
    docker tag "${IMAGE_NAME}:${tag}" "${FULLY_QUALIFIED_IMAGE_NAME}:${tag}"
    aws ecr get-login-password --region "$AWS_REGION" | docker login --username AWS --password-stdin "${REPOSITORY_PATH}"
    docker push "${FULLY_QUALIFIED_IMAGE_NAME}:${tag}"
    echo "Image pushed: ${FULLY_QUALIFIED_IMAGE_NAME}:${tag}"
}

# Creates a new ECR repository.
createRepo () {
    aws ecr create-repository --repository-name "$IMAGE_NAME" > /dev/null 2>&1
    if [ $? -eq 0 ]; then
        echo "Created ECR repository: $IMAGE_NAME."
    else
        echo "ECR repository '$IMAGE_NAME' already exists or failed to create."
    fi
}

# Loads a Docker image from a zip file, tags it for ECR.
loadImage () {
    local zip_file="$1"
    local tag="${2:-latest}"  # Optional tag, defaults to 'latest'

    if [ -z "$zip_file" ]; then
        echo "Please provide the zip file containing the Docker image tarball."
        echo "Usage: $0 load <zip_file> [tag]"
        exit 1
    fi

    if [ ! -f "$zip_file" ]; then
        echo "File '$zip_file' does not exist."
        exit 1
    fi

    # Check if unzip is installed
    if ! command -v unzip > /dev/null; then
        echo "Error: 'unzip' is not installed. Please install it and try again."
        exit 1
    fi

    # Create a temporary directory for extraction
    temp_dir=$(mktemp -d)
    echo "Extracting '$zip_file' to temporary directory '$temp_dir'..."
    unzip "$zip_file" -d "$temp_dir"
    if [ $? -ne 0 ]; then
        echo "Failed to unzip '$zip_file'."
        rm -rf "$temp_dir"
        exit 1
    fi

    # Find the first .tar file in the extracted directory
    tarball=$(find "$temp_dir" -type f -name "*.tar" | head -n 1)

    if [ -z "$tarball" ]; then
        echo "No tarball found in '$zip_file'. Ensure it contains a '.tar' file."
        rm -rf "$temp_dir"
        exit 1
    fi

    echo "Loading Docker image from '$tarball'..."
    # Capture the output of docker load
    load_output=$(docker load -i "$tarball")
    if [ $? -ne 0 ]; then
        echo "Failed to load Docker image from '$tarball'."
        rm -rf "$temp_dir"
        exit 1
    fi

    # Extract the repository and tag from the load_output
    # Example load_output: Loaded image: bruvio/wedding:latest-6926ba2
    repo_tag=$(echo "$load_output" | grep "Loaded image:" | awk '{print $3}')

    if [ -z "$repo_tag" ]; then
        echo "Failed to parse loaded image name from docker load output."
        rm -rf "$temp_dir"
        exit 1
    fi

    repo=$(echo "$repo_tag" | cut -d':' -f1)
    loaded_tag=$(echo "$repo_tag" | cut -d':' -f2)

    if [ -z "$repo" ] || [ -z "$loaded_tag" ]; then
        echo "Failed to extract repository or tag from loaded image name."
        rm -rf "$temp_dir"
        exit 1
    fi

    # Tag the image for ECR
    docker tag "${repo}:${loaded_tag}" "${FULLY_QUALIFIED_IMAGE_NAME}:${tag}"
    if [ $? -ne 0 ]; then
        echo "Failed to tag the image for ECR."
        rm -rf "$temp_dir"
        exit 1
    fi

    echo "Tagged image as '${FULLY_QUALIFIED_IMAGE_NAME}:${tag}'."

    # Cleanup temporary files
    rm -rf "$temp_dir"

    echo "Image is loaded and tagged. Ready to push to ECR using the 'push' command."
}

# Shows the usage for the script.
showUsage () {
    echo "Description:"
    echo "    Builds, runs, pushes, and loads Docker images for '$IMAGE_NAME'."
    echo ""
    echo "Options:"
    echo "    build [tag]: Builds a Docker image ('$IMAGE_NAME') with an optional tag (default: latest)."
    echo "    run: Runs a container based on an existing Docker image ('$IMAGE_NAME')."
    echo "    buildrun [tag]: Builds a Docker image and runs the container with an optional tag."
    echo "    createrepo: Creates a new ECR repository called '$IMAGE_NAME'."
    echo "    push [tag]: Pushes the Docker image to the ECR repository with an optional tag (default: latest)."
    echo "    load <zip_file> [tag]: Loads a Docker image from a zip file and tags it for ECR."
    echo ""
    echo "Examples:"
    echo "    ./docker-task.sh build stable"
    echo "        Builds a Docker image named '$IMAGE_NAME' with the tag 'stable'."
    echo ""
    echo "    ./docker-task.sh build"
    echo "        Builds a Docker image named '$IMAGE_NAME' with the tag 'latest'."
    echo ""
    echo "    ./docker-task.sh run"
    echo "        Runs a container from the '$IMAGE_NAME' image with the default tag."
    echo ""
    echo "    ./docker-task.sh buildrun beta"
    echo "        Builds a Docker image with the tag 'beta' and runs it as a container."
    echo ""
    echo "    ./docker-task.sh createrepo"
    echo "        Creates a new ECR repository named '$IMAGE_NAME'."
    echo ""
    echo "    ./docker-task.sh push stable"
    echo "        Pushes the Docker image tagged 'stable' to ECR."
    echo ""
    echo "    ./docker-task.sh load images_archive.zip stable"
    echo "        Loads a Docker image from 'images_archive.zip' and tags it with 'stable' for ECR."
}

# Ensure AWS CLI is configured
if ! aws sts get-caller-identity > /dev/null 2>&1; then
    echo "AWS CLI is not configured. Please configure it before running this script."
    exit 1
fi

# Handle script arguments
if [ $# -eq 0 ]; then
    showUsage
    exit 1
fi

COMMAND="$1"
TAG="$2"

case "$COMMAND" in
    "build")
        buildImage "$TAG"
        ;;
    "run")
        runContainer
        ;;
    "buildrun")
        buildImage "$TAG"
        runContainer
        ;;
    "push")
        pushImage "$TAG"
        ;;
    "pushall")
        # Example of pushing both 'latest' and a specific tag
        pushImage "latest"
        pushImage "$TAG"
        ;;
    "createrepo")
        createRepo
        ;;
    "load")
        loadImage "$2" "$3"
        ;;
    *)
        echo "Unknown command: $COMMAND"
        showUsage
        exit 1
        ;;
esac
