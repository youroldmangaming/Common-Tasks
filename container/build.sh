container stop buildkit
container rm buildkit
container build --tag dev:macos --file Dockerfile
