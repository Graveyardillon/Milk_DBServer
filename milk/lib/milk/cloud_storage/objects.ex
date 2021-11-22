defmodule Milk.CloudStorage.Objects do
  @moduledoc """
  本番環境で画像をGCSへアップロードするためのモジュール
  """
  require Logger

  # NOTE: compile_env/3でアプリケーションのビルド時とランタイムでconfigの変数が違っているかをElixir検知させることができる。
  @bucket_id Application.compile_env(:milk, :storage_bucket_id)

  def upload(file_path) do
    {:ok, token} = Goth.fetch(Milk.Goth)
    conn = GoogleApi.Storage.V1.Connection.new(token.token)

    basename = Path.basename(file_path)

    GoogleApi.Storage.V1.Api.Objects.storage_objects_insert_simple(
      conn,
      @bucket_id,
      "multipart",
      %GoogleApi.Storage.V1.Model.Object{name: basename},
      file_path
    )
  end

  def get(obj_name) do
    {:ok, token} = Goth.fetch(Milk.Goth)
    conn = GoogleApi.Storage.V1.Connection.new(token.token)

    GoogleApi.Storage.V1.Api.Objects.storage_objects_get(
      conn,
      @bucket_id,
      obj_name
    )
  end

  def delete(obj_name) do
    {:ok, token} = Goth.fetch(Milk.Goth)
    conn = GoogleApi.Storage.V1.Connection.new(token.token)

    GoogleApi.Storage.V1.Api.Objects.storage_objects_delete(
      conn,
      @bucket_id,
      obj_name
    )
  end
end
