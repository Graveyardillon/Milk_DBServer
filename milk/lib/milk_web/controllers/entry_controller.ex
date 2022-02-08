defmodule MilkWeb.EntryController do
  use MilkWeb, :controller

  alias Milk.Tournaments.Entries

  @doc """
  エントリー情報のテンプレートを作成する関数
  """
  def create_template(conn, %{"entry_templates" => entry_templates}) when is_list(entry_templates) do
    case Entries.create_entry_templates(entry_templates) do
      {:ok, _} -> json(conn, %{result: true})
    end
  end

  def get_template(conn, %{"tournament_id" => tournament_id}) do
    template = Entries.get_entry_template(tournament_id)

    render(conn, "templates.json", templates: template)
  end
end
