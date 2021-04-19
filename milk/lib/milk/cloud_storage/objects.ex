defmodule Milk.CloudStorage.Objects do
  require Logger

  @bucket_id Application.get_env(:milk, :storage_bucket_id)

  def upload(file_path) do
    {:ok, token} = Goth.fetch(Milk.Goth)
      |> IO.inspect(label: :goth_token)
    Logger.info("got goth.token")
    conn = GoogleApi.Storage.V1.Connection.new(token.token)
      |> IO.inspect(label: :connection_new)
    Logger.info("new connection")

    {:ok, object} = GoogleApi.Storage.V1.Api.Objects.storage_objects_insert_simple(
      conn,
      @bucket_id,
      "multipart",
      %{name: Path.basename(file_path)},
      file_path
    )
    |> IO.inspect(label: :upload)
    Logger.info("uploaded")

    object
  end

  def get(obj_name) do
    {:ok, token} = Goth.fetch(Milk.Goth)
    conn = GoogleApi.Storage.V1.Connection.new(token.token)

    {:ok, object} = GoogleApi.Storage.V1.Api.Objects.storage_objects_get(
      conn,
      @bucket_id,
      obj_name
    )

    object
  end

  def delete(obj_name) do
    {:ok, token} = Goth.fetch(Milk.Goth)
    conn = GoogleApi.Storage.V1.Connection.new(token.token)

    {:ok, object} = GoogleApi.Storage.V1.Api.Objects.storage_objects_delete(
      conn,
      @bucket_id,
      obj_name
    )

    object
  end
end
