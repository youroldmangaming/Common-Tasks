# container run --rm -it -d --name my-dev-test -p 88:80 -v ./data:/usr/share/nginx/html dev:macos /bin/bash

container run -d -v ./data:/var/www/html --name my-dev-test dev:macos
