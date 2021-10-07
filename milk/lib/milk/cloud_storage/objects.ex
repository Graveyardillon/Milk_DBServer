defmodule Milk.CloudStorage.Objects do
  require Logger

  @bucket_id Application.get_env(:milk, :storage_bucket_id)

  def upload(file_path) do
    {:ok, token} = Goth.fetch(Milk.Goth)
    conn = GoogleApi.Storage.V1.Connection.new(token.token)

    basename = Path.basename(file_path)

    {:ok, object} =
      GoogleApi.Storage.V1.Api.Objects.storage_objects_insert_simple(
        conn,
        @bucket_id,
        "multipart",
        %GoogleApi.Storage.V1.Model.Object{name: basename},
        file_path
      )

    object
  end

  def get(obj_name) do
    {:ok, token} = Goth.fetch(Milk.Goth)
    conn = GoogleApi.Storage.V1.Connection.new(token.token)

    {:ok, object} =
      GoogleApi.Storage.V1.Api.Objects.storage_objects_get(
        conn,
        @bucket_id,
        obj_name
      )

    object
  end

  def delete(obj_name) do
    {:ok, token} = Goth.fetch(Milk.Goth)
    conn = GoogleApi.Storage.V1.Connection.new(token.token)

    {:ok, object} =
      GoogleApi.Storage.V1.Api.Objects.storage_objects_delete(
        conn,
        @bucket_id,
        obj_name
      )

    object
  end
end
