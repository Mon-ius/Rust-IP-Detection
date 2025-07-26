FROM alpine:3.22

ARG GITHUB_TOKEN
ARG GITHUB_REPOSITORY
ARG GITHUB_NAME
ENV GITHUB_TOKEN=$GITHUB_TOKEN
ENV GITHUB_REPOSITORY=$GITHUB_REPOSITORY
ENV GITHUB_NAME=$GITHUB_NAME
ENV CLI_COMMAND=${GITHUB_NAME}-cli

RUN apk update && apk upgrade \
    && apk add --no-cache curl jq\
    && rm -rf /var/cache/apk/*

RUN set -e; \
    cd /tmp && \
    case $(arch) in \
        x86_64)  ARCH='x86_64' ;; \
        aarch64) ARCH='aarch64' ;; \
        ppc64le) ARCH='powerpc64le' ;; \
        *)       echo "Unsupported architecture $(arch)" && exit 1 ;; \
    esac && \
    echo "Acquiring for $TARGET..." && \
    TARGET="${ARCH}-unknown-linux-musl.tar.gz" && \
    GITHUB_API_BASE_URL="https://api.github.com" && \
    TEMP="releases-latest.json" && \
    response=$(curl -sH "Authorization: Bearer ${GITHUB_TOKEN}" ${GITHUB_API_BASE_URL}/repos/${GITHUB_REPOSITORY}/releases/latest > ${TEMP} ) \
    asset_id=$(cat ${TEMP} | jq -r --arg TARGET "$TARGET" '.assets[] | select(.name | contains($TARGET)) | .id') && \
    if [ -z "$asset_id" ]; then \
        echo "No release asset found matching pattern: $TARGET" && exit 1; \
    fi && \
    echo "Downloading asset: $TARGET" && \
    curl -L \
        -H "Accept: application/octet-stream" \
        -H "Authorization: Bearer ${GITHUB_TOKEN}" \
        "${GITHUB_API_BASE_URL}/repos/${GITHUB_REPOSITORY}/releases/assets/${asset_id}" \
        -o "${TARGET}" && \
    tar xzf "${TARGET}" -C /usr/bin && \
    rm -rf /tmp/*

COPY entrypoint.sh /run/entrypoint.sh
ENTRYPOINT ["/run/entrypoint.sh"]

CMD ["sh", "-c", "${CLI_COMMAND}"]
