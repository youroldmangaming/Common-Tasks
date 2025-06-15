
# Introduction

**Apple Container** is an innovative containerization tool designed specifically for macOS. Unlike traditional Docker, it runs each container as a lightweight virtual machine (VM), providing greater security and isolation.

---

# What are Apple Containers?

**Apple Container** is a tool for running Linux containers on Apple Silicon Macs. Its biggest feature is that each container runs in its own lightweight Linux virtual machine. It's based on Apple's proprietary containerization system, and its VM-per-container architecture offers a higher level of security than traditional container technology.

**Technical background**: Apple Container is built on a containerization system developed in Swift. This system leverages the **Virtualization.framework** optimized for Apple Silicon to run each container as a lightweight VM. Internally, a dedicated init system called `vminitd` runs as PID 1 and communicates between the host and guest using gRPC over vsock.

---

# Differences from Conventional Docker

In traditional container technologies like Docker, multiple containers share the host OS kernel. Apple Container, on the other hand, has the following differences:

| Item                  | Traditional Docker      | Apple Container             |
| :-------------------- | :---------------------- | :-------------------------- |
| **Execution environment** | Shared Linux Kernel     | A separate lightweight Linux VM |
| **Safety features** | Process Isolation       | VM-Level Isolation          |
| **Supported OS** | Linux, Windows, macOS   | macOS only                  |
| **Architecture** | Various platforms       | Apple Silicon Optimization  |
| **Resource Usage** | Lightweight             | Lightweight VM (some overhead) |

---

# Features Designed Specifically for macOS

The **Apple Container** is deeply integrated into the following macOS frameworks:

* **Virtualization Framework**: Creating and managing lightweight VMs
* **vmnet Framework**: Providing virtual networks
* **XPC Framework**: Inter-process communication
* **launchd**: system services manager

This deep integration ensures optimal performance and security for macOS environments.

---

# System Requirements

To use the **Apple Container**, your device must meet these requirements:

## Hardware Requirements

* **Apple Silicon Mac**: M1, M2, M3, or later chips
* **Memory**: Enough RAM (to run a lightweight VM)

## Software Requirements

* **macOS 26 Beta 1 and above**: Recommended version (full feature support)
* **macOS 15**: Supported, but network functionality is limited
* **Administrative privileges**: Required for installation and DNS configuration

### Important Notice

macOS 15 has these limitations:

* Inter-container communication is restricted
* Possible timing issues with your network setup
* Manual subnet configuration may be required

For the best experience, we strongly recommend using macOS 26 Beta 1 or later.

---

# Benefits of Apple Container

1.  **Enhanced security**
    Each container runs in its own VM, providing better isolation between containers and reducing security risks.
2.  **Deep integration with macOS**
    By utilizing the native macOS framework, it achieves high compatibility with the system and stable operation.
3.  **OCI Compliance**
    It's fully compliant with Open Container Initiative (OCI) standards, so you can continue to use your existing Docker images.
4.  **Improved development efficiency**
    Develop and test containerized applications with a natural experience for macOS developers.

---

# Installation and Initial Setup

## Overview

This chapter explains in detail all the steps needed to start using the system, from installing the Apple Container to the initial settings. Each step is explained carefully so even beginners can follow along without getting lost.

## Pre-installation Preparation

### Verify System Requirements

First, make sure your Mac meets the Apple Container requirements:

**Technical background**: Apple Container relies on the `Virtualization.framework` in macOS, and each container runs as a lightweight VM. This requires an Apple Silicon Mac with sufficient system resources. The containerization system also uses the `vmnet` framework to build a virtual network (`192.168.64.0/24` subnet).

### Checking the Hardware

Open a terminal and check your chip type with the following command:

```bash
uname -m
```

If the output is `arm64`, it's an Apple Silicon Mac (M1, M2, M3, etc.). If it's `x86_64`, it's an Intel Mac and you can't use the Apple Container.

### Check your macOS version

Check your macOS version in System Information:

```bash
sw_vers
```

Example output:

```
ProductName:		macOS
ProductVersion:		15.0
BuildVersion:		24A335
```

Basic operation is possible with macOS 15 or later, but macOS 26 Beta 1 or later is recommended.

### Verify Administrator Privileges

Installing the Apple Container requires administrator privileges, which you can check with the following command:

```bash
sudo -v
```

You'll be prompted for your password; if no error occurs, you have administrator privileges.

## Installation Instructions

### 1. Download the installer

Download the latest signed installer package from the official Apple Container GitHub release page.

* Visit the Apple Container releases page on GitHub in your browser.
* Download the latest release `.pkg` file.
* Make sure it's saved in your downloads folder.

### 2. Run the installer

Double-click the downloaded `.pkg` file to start the installation wizard.

The installation process does the following:

* The CLI binary is installed in `/usr/local/bin/`
* A helper service is installed in `/usr/local/libexec/`
* A Launch Agent is registered.
* The required directory structure is created.

If prompted, enter your administrator password to complete the installation.

### 3. Verify the installation

Let's check if the installation was successful:

```bash
container --version
```

If successful, you'll see the version information:

```
container version 0.1.0
```

If the command isn't found, open a new terminal session and try again.

## Initial Setup

### Starting system services

Before you can use the Apple Container, you must start the required system services.

```bash
container system start
```

On first run, you might see output similar to this:

```
% container system start
Verifying apiserver is running...
Installing base container filesystem...
No default kernel configured.
Install the recommended default kernel from [https://github.com/kata-containers/kata-containers/releases/download/3.17.0/kata-static-3.17.0-arm64.tar.xz]? [Y/n]:
```

### Installing the kernel

The Apple Container requires a Linux kernel to run. You'll be prompted to install the recommended kernel on first boot.

#### Installing the recommended kernel

When prompted, press `Y` or `Enter` to start the installation:

```bash
Install the recommended default kernel from [https://github.com/kata-containers/kata-containers/releases/download/3.17.0/kata-static-3.17.0-arm64.tar.xz]? [Y/n]: y
Installing kernel...
```

Downloading and installing the kernel may take a few minutes, so be patient. An internet connection is required.

### Verifying the kernel installation

Once installation is complete, you can check the kernel's status with:

```bash
container system kernel list
```

### Checking the service status

Let's check if the system services are running properly:

```bash
container system status
```

If it's running properly, you'll see something like this:

```
API Server Status
Available Plug-in Services
Network Settings Status
```

### First operation check

Let's run a quick test to make sure everything's set up correctly:

```bash
container list --all
```

Initially, no containers are running, so you'll see an empty list:

```
ID  IMAGE  OS  ARCH  STATE  ADDR
```

If you see this output, your Apple Container is successfully installed and ready to use.

## Optional Settings

### DNS Settings (recommended)

We recommend configuring DNS so your containers can be accessed by hostname, like `container-name.test`, instead of just IP addresses:

#### Creating a DNS Domain

```bash
sudo container system dns create test
```

This command requires administrator privileges; you'll be prompted for your password.

#### Setting the default DNS domain

```bash
container system dns default set test
```

#### Checking DNS Settings

Verify that the settings were applied successfully:

```bash
container system dns list
```

### Verifying the Network Configuration

Apple Containers use a `192.168.64.0/24` subnet by default. Let's check your network settings:

```bash
ifconfig | grep bridge
```

If the `bridge100` interface appears, your virtual network is set up successfully.

---

# Upgrade Procedure

If you're upgrading an existing Apple Container installation, follow these steps:

### 1. Stop the existing installation

```bash
container system stop
```

### 2. Uninstall with data retention

```bash
uninstall-container.sh -k
```

The `-k` flag preserves user data (container images and configuration).

### 3. Install the new version

Download the new installer package and follow the normal installation steps.

---

# Troubleshooting

## Common problems and solutions

### Command not found

```
command not found: container
```

**Solution**:

* Open a new terminal session.
* Check that it's in your PATH:
    ```bash
    echo $PATH | grep /usr/local/bin
    ```

### Service startup error

```
Error: Failed to start container services
```

**Solution**:

* Check for existing processes:
    ```bash
    ps aux | grep container
    ```
* End the process if necessary and restart it.

### Network Issues (macOS 15)

In macOS 15, you might experience issues with network settings.

**Solution**:

```bash
container system stop
defaults write com.apple.container.defaults network.subnet 192.168.66.1/24
container system start
```

### Checking the logs

If you run into any issues, you can get more information by checking the system logs:

```bash
container system logs
```

---

# Understand the Basic Command Structure

## Overview

In this chapter, you'll learn the basic command structure of Apple Container, understand the command hierarchy for more efficient tool use, and get an in-depth look at how to use the help system.

## Command Hierarchy

The Apple Container CLI has a hierarchical structure organized by functionality, with three main categories under the main `container` command:

### Overall structure overview

```
container
├── Container operation commands
│   ├── create      # Create container
│   ├── run         # Create and run container
│   ├── start       # Start stopped container
│   ├── stop        # Stop running container
│   ├── delete/rm   # Delete container
│   ├── list/ls     # List containers
│   ├── exec        # Execute command in container
│   ├── logs        # View container logs
│   ├── kill        # Force stop container
│   └── inspect     # View detailed container information
├── Image manipulation commands
│   ├── build       # Build image
│   ├── images      # Image management
│   │   ├── list    # List images
│   │   ├── pull    # Pull image
│   │   ├── push    # Push image
│   │   ├── tag     # Tag image
│   │   ├── save    # Export image
│   │   ├── load    # Import image
│   │   ├── inspect # Inspect image details
│   │   └── rm      # Delete image
│   └── registry    # Registry operations
│       ├── login   # Log in to registry
│       ├── default # Set default registry
│       └── ...
└── System operation commands
    ├── system      # System management
    │   ├── start   # Start service
    │   ├── stop    # Stop service
    │   ├── restart # Restart service
    │   ├── status  # Check service status
    │   ├── logs    # View system logs
    │   ├── dns     # DNS settings
    │   └── kernel  # Kernel management
    └── builder     # Builder management
        ├── start   # Start builder
        ├── stop    # Stop builder
        ├── delete  # Delete builder
        └── status  # Check builder status
```

### 1. Container operation commands

These commands manage the container lifecycle, from creation to deletion.

#### Basic Lifecycle

The typical lifecycle of a container is:

* **Create**: `container create` or `container run`
* **Start**: `container start` (auto-run if `run`)
* **Operation**: Working in container with `container exec`
* **Monitor**: Check logs with `container logs`
* **Stop**: `container stop`
* **Delete**: `container delete`

#### Description of main commands

| Command   | Contraction | Purpose                               | Main Options                               |
| :-------- | :---------- | :------------------------------------ | :----------------------------------------- |
| `create`  | -           | Create a container (do not run it)      | `--name`, `--memory`, `--cpus`             |
| `run`     | -           | Create and run containers             | `--detach`, `--rm`, `--interactive`, `--tty` |
| `start`   | -           | Start a stopped container             | -                                          |
| `stop`    | -           | Stop a running container              | `--timeout`                                |
| `delete`  | `rm`        | Delete a container                    | `--force`                                  |
| `list`    | `ls`        | List containers                       | `--all`, `--format`                        |
| `exec`    | -           | Execute commands in a container       | `--interactive`, `--tty`                   |
| `logs`    | -           | View container logs                   | `--boot`, `--follow`                       |
| `kill`    | -           | Force stop container                  | `--signal`                                 |
| `inspect` | -           | View detailed container information | -                                          |

#### Practical command examples

##### Creating and running a container

```bash
# Run in background (detached mode)
container run --name web-server --detach nginx

# Run interactively
container run --interactive --tty ubuntu bash

# Run with resource limits
container run --memory 2g --cpus 4 my-app
```

##### Managing containers

```bash
# List all containers
container list --all

# Show only running containers
container list

# Display detailed information in JSON format
container list --format json

# Extract specific information by combining with jq
container list --format json | jq '.[] | {name: .configuration.id, ip: .networks[0].address}'
```

### 2. Image Manipulation Commands

Commands related to building and managing container images.

#### Basic image management flow

* **Get**: `container images pull` (Download from registry)
* **Build**: `container build` (Create from Dockerfile)
* **Management**: `container images list` (Check the list)
* **Distribute**: `container images push` (Upload to Registry)

#### Build Command

To build the image, run the `container build` command:

```bash
# Basic build
container build --tag my-app --file Dockerfile .

# Multi-architecture build
container build --arch arm64 --arch amd64 --tag my-app .

# Specify build arguments
container build --build-arg VERSION=1.0 --tag my-app .
```

#### Images Subcommand

Here are subcommands for managing images:

```bash
# List images
container images list

# Pull image
container images pull python:alpine

# Tag image
container images tag python:alpine my-python:latest

# Delete image
container images rm my-python:latest

# Inspect image details
container images inspect python:alpine
```

#### Registry Sub-Command

Registry integration features:

```bash
# Log in to registry
container registry login ghcr.io

# Set default registry
container registry default set ghcr.io

# Check default registry
container registry default get
```

### 3. System Operation Commands

Apple Container System-wide management commands.

#### System Subcommand

Take full control of the system:

```bash
# Start system services
container system start

# Stop system services
container system stop

# Restart system services
container system restart

# Check system status
container system status

# View system logs
container system logs
```

#### DNS management

System level DNS settings:

```bash
# Create DNS domain
sudo container system dns create test

# Set default DNS domain
container system dns default set test

# List DNS settings
container system dns list
```

#### Kernel Management

Managing the Linux kernel:

```bash
# List kernels
container system kernel list

# Install recommended kernel
container system kernel set --recommended

# Set custom kernel
container system kernel set --binary /path/to/kernel
```

#### Builder Subcommand

Builder container management for image builds:

```bash
# Start builder (specify resources)
container builder start --cpus 8 --memory 16g

# Check builder status
container builder status

# Stop builder
container builder stop

# Delete builder
container builder delete
```

---

# Using the Help System

The Apple Container CLI has an extensive built-in help system.

## Getting basic help

```bash
# Display main help
container --help

# Help for a specific command
container run --help

# Help for a subcommand
container images --help
container images pull --help
```

## Help hierarchy

The help system is also hierarchical, following the command structure:

```bash
# Level 1: Main command
container --help

# Level 2: Category command
container images --help
container system --help

# Level 3: Specific subcommand
container images pull --help
container system dns --help
```

## How to use practical help

### Check available options

```bash
# Check all options for the 'run' command
container run --help
```

### Check the list of subcommands

```bash
# Check all subcommands in the 'images' category
container images --help
```

### Check specific use cases

Many of the help pages include practical examples:

```bash
container build --help
```

## Command Abbreviations and Aliases

For efficiency, many commands have abbreviations.

### Major contractions

| Full form    | Contraction | Purpose           |
| :----------- | :---------- | :---------------- |
| `list`       | `ls`        | List view         |
| `delete`     | `rm`        | Delete            |
| `images`     | `i`         | Image Manipulation |
| `registry`   | `r`         | Registry operations |
| `system`     | `s`         | System Operation  |

### Option Shorthand

| Full form       | Contraction | Purpose             |
| :-------------- | :---------- | :------------------ |
| `--all`         | `-a`        | Show All            |
| `--detach`      | `-d`        | Background execution |
| `--interactive` | `-i`        | Interactive mode    |
| `--tty`         | `-t`        | Pseudo terminals    |
| `--file`        | `-f`        | File Specification  |
| `--memory`      | `-m`        | Memory Limit        |
| `--volume`      | `-v`        | Volume Mount        |

### Practical examples

Here's an example of a more efficient command using abbreviations:

```bash
# Long form
container list --all
container images list
container run --detach --interactive --tty ubuntu

# Abbreviated form
container ls -a
container i ls
container run -dit ubuntu
```

## Global Options

Global options are available to all commands.

### Key Global Options

| Option      | Environmental variables | Purpose                 |
| :---------- | :---------------------- | :---------------------- |
| `--debug`   | `CONTAINER_DEBUG`       | Enabling debug output   |
| `--version` | -                       | Displaying version information |
| `--help`    | -                       | Getting Help            |

### Utilizing debug mode

If you run into any issues, you can enable debug mode to get more information:

```bash
# Enable debug when running a command
container --debug run ubuntu

# Enable debug with an environment variable
export CONTAINER_DEBUG=1
container run ubuntu
```

---

# Hands-on Tutorial - Introduction to Container using Python Web Server

## Overview

In this chapter, you'll learn the basics of using Apple Containers by actually building a Python web server. You'll experience Apple Container's functions through practical steps, from booting the system to building an image, running the container, and checking network functions.

## Tutorial Goals

After completing this tutorial, you'll be able to:

* Start and initialize the Apple Container System.
* Create a Dockerfile and build an image.
* Run and manage containers.
* Execute commands in a container.
* Check network functionality and inter-container communication.
* Perform registry manipulation (optional).
* Clean the system.

## Prerequisites

* Apple Container successfully installed as described in Chapter 1.
* Ability to perform basic terminal operations.
* A text editor is available.

## Step 1: Boot the system

First, start the Apple Container system service:

**Technical background**: The `container system start` command initializes each component of the containerization system. This includes starting the VirtualMachineManager, creating a virtual network (`bridge100`) using the `vmnet` framework, and preparing the Linux kernel for container execution.

### Starting system services

Open a terminal and run the following command:

```bash
container system start
```

On first run, you might see output similar to this:

```
% container system start
Verifying apiserver is running...
Installing base container filesystem...
No default kernel configured.
Install the recommended default kernel from [https://github.com/kata-containers/kata-containers/releases/download/3.17.0/kata-static-3.17.0-arm64.tar.xz]? [Y/n]:
```

### Installing the kernel

The Apple Container requires a Linux kernel to run. You'll be prompted to install the recommended kernel on first boot.

#### Installing the recommended kernel

When prompted, press `Y` or `Enter` to start the installation:

```bash
Install the recommended default kernel from [https://github.com/kata-containers/kata-containers/releases/download/3.17.0/kata-static-3.17.0-arm64.tar.xz]? [Y/n]: y
Installing kernel...
```

Downloading and installing the kernel may take a few minutes, so be patient. An internet connection is required.

### Operation check

Verify that the system boots successfully:

```bash
container list --all
```

Initially, no containers are running, so you'll see an empty list:

```
% container list --all
ID  IMAGE  OS  ARCH  STATE  ADDR
%
```

If you see this output, your system is working properly.

## Step 2: Prepare the project

Create a Python web server project.

### Creating a working directory

```bash
mkdir web-test
cd web-test
```

### Creating a Dockerfile

Using a text editor, create a file named `Dockerfile` with the following content:

```dockerfile
FROM docker.io/python:alpine
WORKDIR /content
RUN apk add curl
RUN echo '<!DOCTYPE html><html><head><title>Hello</title></head><body><h1>Hello, world!</h1></body></html>' > index.html
CMD ["python3", "-m", "http.server", "80", "--bind", "0.0.0.0"]
```

### Dockerfile description

Let's understand what each line means:

* `FROM docker.io/python:alpine`: Uses the Alpine Linux base image with Python 3 installed.
* `WORKDIR /content`: Sets the working directory in the container to `/content`.
* `RUN apk add curl`: Installs the `curl` command (used later for testing).
* `RUN echo ...`: Creates a simple HTML file.
* `CMD [...]`: Starts a Python HTTP server when the container starts (listening on port 80).

## Step 3: Build the image

Build a container image from the Dockerfile you created.

### Run the build

```bash
container build --tag web-test --file Dockerfile .
```

The build process will begin, and you'll see output similar to this:

```
% container build --tag web-test --file Dockerfile .
[+] Building 45.2s (8/8) FINISHED
 => [internal] load build definition from Dockerfile
 => => transferring dockerfile: 234B
 => [internal] load .dockerignore
 => => transferring context: 2B
 => [internal] load metadata for docker.io/library/python:alpine
 => [1/4] FROM docker.io/library/python:alpine
 => [2/4] WORKDIR /content
 => [3/4] RUN apk add curl
 => [4/4] RUN echo '<!DOCTYPE html>...' > index.html
 => exporting to image
 => => exporting layers
 => => writing image sha256:25b99501f174...
 => => naming to web-test:latest
```

### Checking the build results

Once the build is complete, check that the image was created successfully:

```bash
container images list
```

You should see output similar to this:

```
% container images list
NAME      TAG     DIGEST
python    alpine  b4d299311845147e7e47c970...
web-test  latest  25b99501f174803e21c58f9c...
%
```

If the `web-test` image and base image `python:alpine` are displayed, then it's successful.

## Step 4: Run the container

Run a container from the built image.

### Starting the web server

```bash
container run --name my-web-server --detach --rm web-test
```

The options in this command mean:

* `--name my-web-server`: Names the container `my-web-server`.
* `--detach`: Runs in background (detached mode).
* `--rm`: Automatically deletes when the container stops.

**Technical background**: The `container run` command internally creates a lightweight VM and starts `vminitd` in it as PID 1. `vminitd` receives gRPC over vsock communication from the host and runs the specified container process. Each container runs in an independent Linux VM, providing stronger isolation than traditional Docker.

### Checking running containers

```bash
container ls
```

You'll see output similar to this:

```
% container ls
ID             IMAGE                                               OS     ARCH   STATE    ADDR
buildkit       ghcr.io/apple/container-builder-shim/builder:0.0.3  linux  arm64  running  192.168.64.2
my-web-server  web-test:latest                                     linux  arm64  running  192.168.64.3
%
```

You can see that the `my-web-server` container is in the `running` state and has an IP address (in this example `192.168.64.3`) assigned to it.

## Step 5: Access the Web Server

Let's access the running web server.

### Access via browser

Access the container in your browser using its IP address:

```bash
open http://192.168.64.3
```

**Note**: The IP address may differ depending on your environment. Use the IP address confirmed by the `container ls` command.

If the browser opens and displays "Hello, world!", the operation was successful.

### DNS Settings (Optional)

If you configured DNS in Chapter 1, you can also access it by hostname:

```bash
open http://my-web-server.test
```

## Step 6: Run commands in the container

Let's try executing a command inside a running container.

### Non-interactive command execution

```bash
container exec my-web-server ls /content
```

Example output:

```
% container exec my-web-server ls /content
index.html
%
```

### Interactive Shell Sessions

```bash
container exec --tty --interactive my-web-server sh
```

An interactive shell will be started:

```
% container exec --tty --interactive my-web-server sh
/content # ls
index.html
/content # uname -a
Linux my-web-server 6.12.28 #1 SMP Tue May 20 15:19:05 UTC 2025 aarch64 Linux
/content # cat index.html
<!DOCTYPE html><html><head><title>Hello</title></head><body><h1>Hello, world!</h1></body></html>
/content # exit
%
```

In your shell try the following:

* `ls`: Check the file list
* `uname -a`: Display system information
* `cat index.html`: Check the contents of the HTML file
* `exit`: Exit the shell

## Step 7: Check the logs

Learn how to check your container logs.

### Viewing the Application Log

```bash
container logs my-web-server
```

Here's the Python webserver access log:

```
% container logs my-web-server
Serving HTTP on 0.0.0.0 port 80 (http://0.0.0.0:80/) ...
192.168.64.1 - - [10/Jun/2025 02:15:23] "GET / HTTP/1.1" 200 -
```

### Viewing the Boot Log

You can also check the container (VM) startup logs:

```bash
container logs --boot my-web-server
```

## Step 8: Test inter-container communication

Let's try accessing the running web server from another container.

### Testing in a temporary container

```bash
container run -it --rm web-test curl http://192.168.64.3
```

**Note**: Replace the IP addresses with your own `my-web-server` IP.

If successful, you'll see the HTML content:

```
% container run -it --rm web-test curl http://192.168.64.3
<!DOCTYPE html><html><head><title>Hello</title></head><body><h1>Hello, world!</h1></body></html>
%
```

### Access using DNS name (if DNS is configured)

```bash
container run -it --rm web-test curl http://my-web-server.test
```

This test ensures that network communication between containers is working properly.

## Step 9: Advanced Registry Manipulation

Learn how to push the image you created to a container registry. This is an optional step.

### Logging in to the Registry

```bash
container registry login registry.example.com
```

**Note**: Be sure to substitute your actual registry URL (e.g., `ghcr.io`, `docker.io`, etc.).

### Image tagging

```bash
container images tag web-test registry.example.com/your-username/web-test:latest
```

### Pushing an Image

```bash
container images push registry.example.com/your-username/web-test:latest
```

### Running tests from a remote image

Let's delete the local image and try running it remotely:

```bash
# Stop current container
container stop my-web-server

# Delete local image
container images delete web-test registry.example.com/your-username/web-test:latest

# Run from remote image
container run --name my-web-server --detach --rm registry.example.com/your-username/web-test:latest
```

## Step 10: Clean up

At the end of the tutorial, you'll clean up the resources you created.

### Stopping a container

```bash
container stop my-web-server
```

The container will be automatically deleted because you used the `--rm` option.

### Confirm container deletion

```bash
container list --all
```

Verify that `my-web-server` has disappeared from the list:

```
% container list --all
ID        IMAGE                                               OS     ARCH   STATE    ADDR
buildkit  ghcr.io/apple/container-builder-shim/builder:0.0.3  linux  arm64  running  192.168.64.2
%
```

### Stopping system services

```bash
container system stop
```

This will stop all Apple Container services.

---

# Troubleshooting

This section explains what to do if you encounter any issues during the tutorial.

## Common issues

### 1. Build Error

```
Error: failed to build image
```

**Solution**:

* Check the syntax of your Dockerfile.
* Check your Internet connection.
* Check the error details with `container system logs`.

### 2. The container doesn't start

```
Error: failed to start container
```

**Solution**:

* Check the log with `container logs container-name`.
* Check for possible resource shortages.
* Reboot the system and try again.

### 3. No network access

```
curl: (7) Failed to connect to 192.168.64.3 port 80
```

**Solution**:

* Recheck your IP address with `container ls`.
* Check your firewall settings.
* Possible network restrictions for macOS 15.

## How to debug

If you need more information, enable debug mode:

```bash
container --debug run web-test
```

Or set it in an environment variable:

```bash
export CONTAINER_DEBUG=1
container run web-test
```

---

# Command Reference

## Overview

This chapter provides an in-depth look at each of the Apple Container commands. After learning the basics in the tutorial in Chapter 3, this chapter systematically explains each command, including more advanced options and practical use cases.

## Command Reference Structure

This chapter is divided into three sections:

* **Container manipulation commands**: Container lifecycle management.
* **Image management commands**: Building, distributing, and managing images.
* **System Administration Commands**: System-wide configuration and management.

For each command, we provide the following information:

* Basic syntax and uses
* Main options and explanations
* Practical use cases
* Combination with related commands

---

## 1. Container operation commands

### `container run`

This is the most frequently used command to create and run a container at the same time.

#### Basic Syntax

```bash
container run [OPTIONS] IMAGE [COMMAND] [ARG...]
```

#### Main Options

| Option        | Contraction | Explanation                  | Defaults          |
| :------------ | :---------- | :--------------------------- | :---------------- |
| `--name`      | -           | Specify the container name   | automatic generation |
| `--detach`    | `-d`        | Run in background            | foreground        |
| `--interactive` | `-i`        | Keep STDIN open              | `false`           |
| `--tty`       | `-t`        | Allocate a pseudo TTY        | `false`           |
| `--rm`        | -           | Automatically remove containers on exit | `false`           |
| `--memory`    | `-m`        | Set memory limit             | `1GB`             |
| `--cpus`      | -           | Set CPU limit                | `4`               |
| `--volume`    | `-v`        | Mount the volume             | -                 |
| `--mount`     | -           | Advanced Mount Settings      | -                 |
| `--dns-domain` | -           | Set DNS domain               | `test`            |

#### Practical examples

##### Basic execution

```bash
# Simple execution
container run ubuntu echo "Hello World"

# Interactive shell
container run -it ubuntu bash

# Run in background
container run -d --name web-server nginx
```

##### Resource Limits

```bash
# Limit memory and CPU
container run --memory 2g --cpus 2 my-app

# Allocate large resources
container run --memory 16g --cpus 8 heavy-workload
```

##### Volume Mount

```bash
# Mount host directory
container run -v ${HOME}/data:/app/data my-app

# Mount multiple volumes
container run \
  -v ${HOME}/config:/etc/config \
  -v ${HOME}/logs:/var/log \
  my-app
```

### `container create`

A command to create a container but not run it, so you can start it later with `container start`.

#### Basic Syntax

```bash
container create [OPTIONS] IMAGE [COMMAND] [ARG...]
```

#### Usage example

```bash
# Create container (do not run it)
container create --name my-container ubuntu

# Start later
container start my-container
```

### `container start` / `stop`

Start and stop existing containers.

#### Basic Syntax

```bash
container start [OPTIONS] CONTAINER [CONTAINER...]
container stop [OPTIONS] CONTAINER [CONTAINER...]
```

#### Usage example

```bash
# Start container
container start my-container

# Start multiple containers simultaneously
container start web-server database cache

# Stop container
container stop my-container

# Force stop (specify timeout)
container stop --timeout 30 my-container
```

### `container list` / `ls`

Display a list of containers.

#### Basic Syntax

```bash
container list [OPTIONS]
container ls [OPTIONS]  # Abbreviated form
```

#### Main Options

| Option    | Contraction | Explanation                 |
| :-------- | :---------- | :-------------------------- |
| `--all`   | `-a`        | Show stopped containers too |
| `--format` | -           | Specify the output format (json) |

#### Usage example

```bash
# Show only running containers
container ls

# Show all containers
container ls -a

# Output in JSON format
container ls --format json

# Extract specific information by combining with jq
container ls --format json | jq '.[] | {name: .configuration.id, ip: .networks[0].address}'
```

### `container exec`

Execute a command inside a running container.

#### Basic Syntax

```bash
container exec [OPTIONS] CONTAINER COMMAND [ARG...]
```

#### Main Options

| Option        | Contraction | Explanation           |
| :------------ | :---------- | :-------------------- |
| `--interactive` | `-i`        | Keep STDIN open       |
| `--tty`       | `-t`        | Allocate a pseudo TTY |

#### Usage example

```bash
# Execute a single command
container exec my-container ls /app

# Interactive shell session
container exec -it my-container bash

# Execute command with environment variables
container exec my-container env VAR=value my-command

# Check file contents
container exec my-container cat /etc/hosts
```

### `container logs`

View the container logs.

#### Basic Syntax

```bash
container logs [OPTIONS] CONTAINER
```

#### Main Options

| Option     | Explanation             |
| :--------- | :---------------------- |
| `--boot`   | Show boot log           |
| `--follow` | Track logs in real time |

#### Usage example

```bash
# Display application logs
container logs my-web-server

# Display boot logs
container logs --boot my-container

# Monitor logs in real time
container logs --follow my-web-server
```

### `container inspect`

Display detailed information about a container in JSON format.

#### Basic Syntax

```bash
container inspect CONTAINER [CONTAINER...]
```

#### Usage example

```bash
# Display detailed container information
container inspect my-container

# Extract specific information with jq
container inspect my-container | jq '.networks[0].address'

# Get information for multiple containers at once
container inspect web-server database
```

### `container delete` / `rm`

Delete the container.

#### Basic Syntax

```bash
container delete [OPTIONS] CONTAINER [CONTAINER...]
container rm [OPTIONS] CONTAINER [CONTAINER...]  # Abbreviated form
```

#### Main Options

| Option    | Explanation                         |
| :-------- | :---------------------------------- |
| `--force` | Force delete running containers too |

#### Usage example

```bash
# Delete stopped container
container rm my-container

# Force delete running container
container rm --force my-container

# Delete multiple containers
container rm container1 container2 container3
```

### `container kill`

Send a signal to a running container.

#### Basic Syntax

```bash
container kill [OPTIONS] CONTAINER [CONTAINER...]
```

#### Usage example

```bash
# Force terminate with SIGKILL
container kill my-container

# Send a specific signal
container kill --signal SIGTERM my-container
```

---

## 2. Image Management Commands

### `container build`

Build the image from the Dockerfile.

#### Basic Syntax

```bash
container build [OPTIONS] PATH
```

#### Main Options

| Option     | Contraction | Explanation                     |
| :--------- | :---------- | :------------------------------ |
| `--tag`    | `-t`        | Specify the image name and tag  |
| `--file`   | `-f`        | Specify the path to the Dockerfile. |
| `--arch`   | -           | Specify the target architecture |
| `--build-arg` | -           | Set build arguments             |

#### Usage example

```bash
# Basic build
container build -t my-app .

# Use a specific Dockerfile
container build -t my-app -f Dockerfile.prod .

# Multi-architecture build
container build --arch arm64 --arch amd64 -t my-app .

# Specify build arguments
container build --build-arg VERSION=1.0 --build-arg ENV=production -t my-app .
```

### `container images list`

List local images.

#### Basic Syntax

```bash
container images list [OPTIONS]
```

#### Usage example

```bash
# List images
container images list

# Output in JSON format
container images list --format json
```
