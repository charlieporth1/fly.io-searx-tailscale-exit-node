ARG TSFILE=tailscale_1.20.2_amd64.tgz

FROM alpine:latest as tailscale
ARG TSFILE
WORKDIR /app
ENV TSFILE=tailscale_1.30.2_amd64.tgz
RUN wget https://pkgs.tailscale.com/stable/${TSFILE} && \
  tar xzf ${TSFILE} --strip-components=1
COPY . ./



FROM alpine:latest
RUN apk update && apk add ca-certificates iptables ip6tables iproute2 && rm -rf /var/cache/apk/*

WORKDIR /app
# Copy binary to production image
COPY --from=tailscale /app/start.sh /app/start.sh
COPY --from=tailscale /app/tailscaled /app/tailscaled
COPY --from=tailscale /app/tailscale /app/tailscale
RUN mkdir -p /var/run/tailscale
RUN mkdir -p /var/cache/tailscale
RUN mkdir -p /var/lib/tailscale

RUN apk update && \
  apk add git python3 py3-pip openssl

RUN  git clone https://github.com/asciimoo/searx.git && \
  cd searx && \
  pip install -r requirements.txt && \
  sed -i "s/ultrasecretkey/`openssl rand -hex 16`/g" searx/settings.yml && \
  sed -i 's/bind_address : "127.0.0.1"/bind_address : "0.0.0.0"/g' searx/settings.yml
RUN ls -R
EXPOSE 8888
EXPOSE 8080


# Run on container startup.
USER root
CMD ["/app/start.sh"]
