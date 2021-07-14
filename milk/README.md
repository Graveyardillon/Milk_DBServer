# Milk

To start this database server:

  * Install dependencies with `mix deps.get`
  * Create and migrate your database with `mix ecto.setup`
  * Install Node.js dependencies with `cd assets && npm install`
  * Start Phoenix endpoint with `mix phx.server`

Now you can visit [`localhost:4000`](http://localhost:4000) from your browser.

Ready to run in production? Please [check our deployment guides](https://hexdocs.pm/phoenix/deployment.html).

## trouble shooting

too many openみたいなFile.Errorを解消するには
https://superuser.com/questions/433746/is-there-a-fix-for-the-too-many-open-files-in-system-error-on-os-x-10-7-1/443168#443168

### MacOS

`/etc/sysctl.conf`を作成する。

```
ulimit -S -n 2048 # or whatever number you choose
```
を実行する。

## excoveralls
```
MIX_ENV=test mix coveralls

MIX_ENV=test mix coveralls.detail --filter general.ex

MIX_ENV=test mix coveralls.html
```

### debug seed data
```
mix ecto.reset && \
mix run ./priv/repo/seeds/tournament/tournament_seeds.exs && \
mix run ./priv/repo/seeds/tournament/fill_size_4_tournament.exs && \
mix run ./priv/repo/seeds/tournament/fill_size_32_tournament.exs && \
mix run ./priv/repo/seeds/notification/add_all_notification_on_user_1.exs && \
mix run ./priv/repo/seeds/relation/block_some_users.exs && \
mix run ./priv/repo/seeds/relation/follow.exs && \
mix run ./priv/repo/seeds/tournament/assistant_check.exs && \
mix run ./priv/repo/seeds/action_history/seeder.exs && \
mix phx.server
```

```
mix ecto.reset && \
mix run ./priv/repo/seeds/tournament/tournament_seeds.exs && \
mix run ./priv/repo/seeds/tournament/fill_size_6_tournament.exs && \
mix run ./priv/repo/seeds/notification/add_all_notification_on_user_1.exs && \
mix run ./priv/repo/seeds/relation/block_some_users.exs && \
mix run ./priv/repo/seeds/tournament/assistant_check.exs && \
mix run ./priv/repo/seeds/action_history/seeder.exs && \
mix phx.server
```

```
mix ecto.reset && \
mix run ./priv/repo/seeds/tournament/team/setup_progress.exs && \
mix phx.server
```