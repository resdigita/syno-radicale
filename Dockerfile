FROM alpine:latest

LABEL maintainer="Peter Boy <pb@resdigita.de>"
LABEL version="1.0"

# import config files
COPY  config logging rights docker-entrypoint.sh  /root/

# install everything in one run
RUN  set -x \
  &&  apk add --no-cache   \
          python3          \
          apache2-utils    \
          ca-certificates  \
          openssl          \
          su-exec          \
          shadow           \
  &&  apk add --no-cache --virtual=build-deps  \
          python3-dev   \
          build-base    \
          libffi-dev    \
          git           \
  &&  python3 -m pip install --upgrade pip     \
  &&  python3 -m pip install passlib bcrypt    \
  &&  python3 -m pip install radicale==2.1.11  \
  &&  python3 -m pip install --upgrade git+https://github.com/Unrud/RadicaleInfCloud \
  &&  apk del  --purge build-deps              \
  &&  mkdir -p  /etc/radicale  /srv/radicale   \
  &&  mv  /root/config  /root/logging  /root/rights  /etc/radicale/  \
  &&  touch  /etc/radicale/users                                     \
  &&  mv  /root/docker-entrypoint.sh  /usr/local/bin/                \
  &&  chmod +x  /usr/local/bin/docker-entrypoint.sh


# volume for Radicale persistent user data
# mount using -v  /path/to/hostdir:/srv/radicale
VOLUME /srv/radicale

# tcp port for radicale, publish either on
# public interface with -p 5232:5232 or internal with --network=host
EXPOSE 5232


# set config environment variable
ENV RADICALE_CONFIG /etc/radicale/config
# set custom entrypoint
ENTRYPOINT ["docker-entrypoint.sh"]
CMD ["radicale"]
