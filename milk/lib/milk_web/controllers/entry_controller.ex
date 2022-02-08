defmodule MilkWeb.EntryController do
  use MilkWeb, :controller

  import Common.Sperm

  alias Milk.Tournaments
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

  def get_entry_information(conn, %{"team_id" => team_id}) do
    team_id
    |> Tournaments.get_leader()
    |> Map.get(:user_id)
    |> Entries.get_entry_information_by_user_id()
    ~> entry_information

    render(conn, "entry_information_list.json", %{entry_information: entry_information})
  end

  def create_entry_information(conn, %{"tournament_id" => tournament_id, "user_id" => user_id, "entry_information" => entry_information}) when is_list(entry_information) do
    case Entries.create_entry(entry_information, tournament_id, user_id) do
      {:ok, _} -> json(conn, %{result: true})
    end
  end
end
