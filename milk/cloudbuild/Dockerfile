FROM elixir:alpine
ARG app_name=milk-test
ARG phoenix_subdir=..
ARG build_env=test
ENV MIX_ENV=${build_env} TERM=xterm
ENV MILK_TEST_USERNAME=postgres
ENV MILK_TEST_PASSWORD=postgres
ENV MILK_TEST_DATABASE=milk_test
ENV MILK_TEST_HOSTNAME=localhost
ENV MILK_TEST_REDISHOST=localhost
ENV MILK_TEST_REDISPORT=6380
#ENV GOOGLE_APPLICATION_CREDENTIALS=e-players6814-8e8eac82841c.json
ENV GOOGLE_PROJECT_ID=e-players6814

WORKDIR /opt/app
RUN apk update \
  && apk --no-cache --update add nodejs nodejs-npm \
  && apk add alpine-sdk \
  && mix local.rebar --force \
  && mix local.hex --force

COPY .. .
RUN pwd
RUN ls -l
RUN mix do deps.get, compile
RUN mix deps.update certifi
RUN mix ecto.create
RUN mix ecto.migrate
RUN mix test