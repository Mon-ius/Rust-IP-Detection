#!/bin/sh

set -e

sleep 2

_CLOUDFLARE='ZXhhbXBsZV9jbG91ZGZsYXJlX2FjY291bnRfdG9rZW4='
_PORT=10086

SERVICE_PORT="${SERVICE_PORT:-$_PORT}"
CLOUDFLARE="${CLOUDFLARE:-$_CLOUDFLARE}"

if [ ! -e "/usr/bin/$GITHUB_NAME" ]; then
    echo "Error, no binary asset found in /usr/bin" && exit 1;
fi

if [ ! -e "/usr/bin/$CLI_COMMAND" ]; then
    chmod +x "/usr/bin/$GITHUB_NAME"
    echo "/usr/bin/$GITHUB_NAME --cloudflare $CLOUDFLARE --port $SERVICE_PORT "  > "/usr/bin/$CLI_COMMAND"
    chmod +x "/usr/bin/$CLI_COMMAND"
fi

exec "$@"