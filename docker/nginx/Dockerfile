ARG BASE_IMAGE
FROM ${BASE_IMAGE}
COPY entrypoint.sh /run/entrypoint.sh
ENTRYPOINT ["/run/entrypoint.sh"]
EXPOSE 443
CMD ["run-nginx"]