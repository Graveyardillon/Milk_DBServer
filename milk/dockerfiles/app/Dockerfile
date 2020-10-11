FROM elixir:1.9.4-alpine AS build

RUN apk add --no-cache build-base npm git python

WORKDIR /app

RUN mix local.hex --force && \
    mix local.rebar --force

ENV MIX_ENV=prod

COPY mix.exs mix.lock ./
COPY config config
RUN mix do deps.get, deps.compile

COPY priv priv
COPY lib lib
COPY rel rel
RUN mix compile
RUN mix ecto.create
RUN mix ecto.migrate
RUN mix release

FROM alpine:3.9 AS app
RUN apk add --no-cache openssl ncurses-libs

WORKDIR /app

RUN chown nobody:nobody /app

USER nobody:nobody

COPY --from=build --chown=nobody:nobody /app/_build/prod/rel/milk ./

ENV HOME=/app

CMD ["bin/my_app", "start"]

