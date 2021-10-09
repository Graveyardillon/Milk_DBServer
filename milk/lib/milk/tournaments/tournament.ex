defmodule Milk.Tournaments.Tournament do
  use Milk.Schema

  import Ecto.Changeset

  alias Milk.Accounts.User
  alias Milk.Games.Game
  alias Milk.Lives.Live
  alias Milk.Platforms.Platform

  alias Milk.Tournaments.{
    Entrant,
    Assistant,
    Team,
    TournamentChatTopic,
    TournamentCustomDetail
  }

  @type t :: %__MODULE__{
    capacity: integer(),
    count: integer() | nil,
    deadline: any(),
    description: String.t() | nil,
    discord_server_id: String.t() | nil,
    enabled_coin_toss: boolean(),
    enabled_map: boolean(),
    event_date: any(),
    game_name: String.t() | nil,
    is_started: boolean(),
    is_team: boolean(),
    name: String.t(),
    password: String.t() | nil,
    start_recruiting: any(),
    team_size: integer() | nil,
    thumbnail_path: String.t() | nil,
    type: integer(),
    url: String.t() | nil,
    url_token: String.t() | nil
  }

  schema "tournaments" do
    field :capacity, :integer
    field :count, :integer, default: 0
    field :deadline, EctoDate
    field :description, :string
    field :discord_server_id, :string
    field :enabled_coin_toss, :boolean, default: false
    field :enabled_map, :boolean, default: false
    field :event_date, EctoDate
    field :game_name, :string
    field :is_started, :boolean, default: false
    field :is_team, :boolean, default: false
    field :name, :string
    field :password, :string
    field :start_recruiting, EctoDate
    field :team_size, :integer, default: nil
    field :thumbnail_path, :string
    field :type, :integer
    field :url, :string
    field :url_token, :string

    belongs_to :platform, Platform
    belongs_to :game, Game
    belongs_to :master, User

    has_many :lives, Live
    has_many :entrant, Entrant
    has_many :assistant, Assistant
    has_many :tournament_chat_topics, TournamentChatTopic
    has_many :team, Team
    has_many :map, Milk.Tournaments.Map
    has_one :custom_detail, TournamentCustomDetail

    timestamps()
  end

  @doc false
  def create_changeset(tournament, attrs) do
    tournament
    |> cast(attrs, [
      :name,
      :capacity,
      :description,
      :deadline,
      :discord_server_id,
      :enabled_coin_toss,
      :enabled_map,
      :event_date,
      :game_name,
      :thumbnail_path,
      :password,
      :type,
      :url,
      :url_token,
      :platform_id,
      :master_id,
      :count,
      :is_started,
      :is_team,
      :start_recruiting,
      :team_size
    ])
    |> validate_required([:name, :event_date, :capacity, :deadline, :type])
    |> foreign_key_constraint(:platform_id)
    |> foreign_key_constraint(:game_id)
    |> foreign_key_constraint(:master_id)
    |> put_password_hash()
  end

  defp put_password_hash(
         %Ecto.Changeset{valid?: true, changes: %{password: password}} = changeset
       ) do
    change(changeset, password: create_pass(password))
  end

  defp put_password_hash(changeset), do: changeset

  defp create_pass(password) do
    Argon2.hash_pwd_salt(password)
  end

  @doc false
  def changeset(tournament, attrs) do
    tournament
    |> cast(attrs, [
      :name,
      :enabled_coin_toss,
      :enabled_map,
      :event_date,
      :capacity,
      :description,
      :deadline,
      :discord_server_id,
      :game_name,
      :thumbnail_path,
      :password,
      :type,
      :url,
      :url_token,
      :platform_id,
      :master_id,
      :count,
      :is_started,
      :is_team,
      :start_recruiting
    ])
    |> validate_required([:name, :event_date, :capacity, :deadline])
    |> foreign_key_constraint(:platform_id)
    |> foreign_key_constraint(:game_id)
    |> foreign_key_constraint(:master_id)
    |> put_password_hash()
  end
end
