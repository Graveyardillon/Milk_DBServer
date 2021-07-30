FROM elixir:1.10.4

ARG app_name=milk
ARG phoenix_subdir=.
ARG build_env=prod
ENV MIX_ENV=${build_env} TERM=xterm
ENV GOOGLE_APPLICATION_CREDENTIALS=e-players6814-8e8eac82841c.json
ENV GOOGLE_PROJECT_ID=e-players6814
ENV CLOUD_SQL_HOST=e-players6814:asia-northeast1:milkdb-test

WORKDIR /opt/app
RUN apk update \
  && apk add --no-cache fish git openssh curl \
  && apk --no-cache --update add nodejs nodejs-npm \
  && apk add alpine-sdk \
  && apk add libc6-compat libstdc++ \
  && mix local.rebar --force \
  && mix local.hex --force

COPY . .