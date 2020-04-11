ARG ALPINE_VERSION=3.11.5

FROM alpine:$ALPINE_VERSION AS build-env

ARG GITEA_VERSION=1.11.4

# Build dependencies
RUN apk --no-cache add curl wget

WORKDIR /build

RUN wget -q https://github.com/go-gitea/gitea/archive/v$GITEA_VERSION.tar.gz -O gitea.tar.gz && \
    tar xf gitea.tar.gz --strip-components=1

RUN wget -q -O gitea https://github.com/go-gitea/gitea/releases/download/v$GITEA_VERSION/gitea-$GITEA_VERSION-linux-arm-6 && \
    chmod +x gitea

# Make sure the binary runs
RUN ./gitea -h

FROM alpine:$ALPINE_VERSION

LABEL maintainer="Matthias Schoettle <docker@mattsch.com>"

RUN apk --no-cache add \
	su-exec \
	ca-certificates \
	sqlite \
	bash \
	git \
	linux-pam \
	gettext \
	s6 \
	curl \
	openssh \
	tzdata  && \
	addgroup \
	-S -g 1000 \
	git && \
	adduser \
	-S -H -D \
	-h /data/git \
	-s /bin/bash \
	-u 1000 \
	-G git \
	git && \
	echo "git:$(date +%s | sha256sum | base64 | head -c 32)" | chpasswd

ENV USER=git
ENV GITEA_CUSTOM=/data/gitea GITEA_WORK_DIR=/data/gitea
ENV GODEBUG=netdns=go

EXPOSE 22 3000

VOLUME ["/data"]

ENTRYPOINT ["/usr/bin/entrypoint"]
CMD ["/bin/s6-svscan", "/etc/s6"]

COPY --from=build-env /build/docker/root /
COPY --from=build-env /build/gitea /app/gitea/gitea
