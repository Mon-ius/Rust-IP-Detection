# Rust-IP-Detection

[![CI Status](https://github.com/Mon-ius/Rust-IP-Detection/workflows/ci/badge.svg)](https://github.com/Mon-ius/Rust-IP-Detection/actions?query=workflow:ci)
[![GitHub release (with filter)](https://img.shields.io/github/v/release/Mon-ius/Rust-IP-Detection)](https://github.com/Mon-ius/Rust-IP-Detection/releases)
[![Issues](https://img.shields.io/github/issues/Mon-ius/Rust-IP-Detection)](https://github.com/Mon-ius/Rust-IP-Detection/issues) 
[![Forks](https://img.shields.io/github/forks/Mon-ius/Rust-IP-Detection)](https://github.com/Mon-ius/Rust-IP-Detection/network/members)
[![Stars](https://img.shields.io/github/stars/Mon-ius/Rust-IP-Detection)](https://github.com/Mon-ius/Rust-IP-Detection/stargazers)
[![Downloads](https://img.shields.io/github/downloads/Mon-ius/Rust-IP-Detection/total.svg)](https://github.com/Mon-ius/Rust-IP-Detection/releases)
[![License: GPL v3](https://img.shields.io/badge/License-GPLv3-blue.svg)](./LICENSE)
[![GitHub top language](https://img.shields.io/github/languages/top/Mon-ius/Rust-IP-Detection?logo=rust&label=)](./Cargo.toml#L4)
[![Code Size](https://img.shields.io/github/languages/code-size/Mon-ius/Rust-IP-Detection)](https://github.com/Mon-ius/Rust-IP-Detection)

### Install

```sh
# sudo systemctl enable --now docker

# sudo usermod -aG docker ${USER}
# sudo chmod 666 /var/run/docker.sock
# sudo chown root:docker /var/run/docker.sock

curl -fsSL bit.ly/create-docker | sh
```

### Run

```sh
export SERVICE_NAME='ip'
export SERVICE_PORT=10086
export CLOUDFLARE='ZXhhbXBsZV9jbG91ZGZsYXJlX2FjY291bnRfdG9rZW4='

docker rm -f $(docker ps -a -q) && docker rmi -f $(docker images -a -q)
echo y | docker network prune && cat docker-compose.yml | docker compose -f - up -d
```

### Source

- [Rust-IP-Detection](https://github.com/Mon-ius/Rust-IP-Detection)

## License

The scripts and documentation in this project are released under the [GPLv3
License].

[GPLv3 License]: LICENSE