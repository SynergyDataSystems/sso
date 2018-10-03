# =============================================================================
# build stage
#
# install golang dependencies & build binaries
# =============================================================================
FROM golang:1.10 AS build

ENV GOFLAGS='-ldflags="-s -w"'
ENV CGO_ENABLED=0

# use gpm to install dependencies
COPY Godeps gpm /tmp/
RUN cd /tmp && ./gpm install

WORKDIR /go/src/github.com/buzzfeed/sso

COPY cmd ./cmd
COPY internal ./internal
RUN cd cmd/sso-auth && go build -o /go/bin/sso-auth \
&& cd ../sso-proxy && go build -o /go/bin/sso-proxy \
&& cd /tmp \
&& wget https://s3.amazonaws.com/psi-downloads/aws-sm-env.gz \
&& wget https://s3.amazonaws.com/psi-downloads/aws-sm-env.sh \
&& gunzip aws-sm-env.gz \
&& chmod 755 aws-sm-env aws-sm-env.sh \
&& mv aws-sm-env aws-sm-env.sh /go/bin/

# =============================================================================
# final stage
#
# add static assets and copy binaries from build stage
# =============================================================================
FROM debian:stable-slim
RUN apt-get update && apt-get install -y ca-certificates && rm -rf /var/lib/apt/lists/*
WORKDIR /sso
COPY --from=build /go/bin/* /bin/
