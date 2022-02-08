defmodule MilkWeb.EntryController do
  use MilkWeb, :controller

  alias Milk.Tournaments.Entries

  @doc """
  エントリー情報のテンプレートを作成する関数
  """
  def create_template(conn, %{"entry_templates" => entry_templates}) when is_list(entry_templates) do
    case Entries.create_entry_templates(entry_templates) do
      {:ok, _}    -> json(conn, %{result: true})
    end
  end
end
