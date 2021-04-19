defmodule Milk.CloudStorage.Buckets do

  def list(project_id) do
    {:ok, token} = Goth.fetch(Milk.Goth)
    conn = GoogleApi.Storage.V1.Connection.new(token.token)
    {:ok, response} = GoogleApi.Storage.V1.Api.Buckets.storage_buckets_list(conn, project_id)
    Enum.each(response.items, &IO.puts(&1.id))
  end
end
