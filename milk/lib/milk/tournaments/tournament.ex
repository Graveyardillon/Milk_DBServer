defmodule Milk.Tournaments.Tournament do
  use Milk.Schema

  import Ecto.Changeset

  alias Milk.Accounts.User
  alias Milk.Games.Game
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
          count: integer(),
          deadline: any(),
          description: String.t() | nil,
          discord_server_id: String.t() | nil,
          enabled_coin_toss: boolean(),
          enabled_map: boolean(),
          event_date: any(),
          game_id: integer() | nil,
          game_name: String.t() | nil,
          is_started: boolean(),
          is_team: boolean(),
          language: String.t() | nil,
          master_id: integer(),
          name: String.t(),
          password: String.t() | nil,
          platform_id: integer(),
          rule: String.t(),
          start_recruiting: any(),
          team_size: integer() | nil,
          thumbnail_path: String.t() | nil,
          url: String.t() | nil,
          url_token: String.t() | nil,
          # NOTE: timestamps
          create_time: any(),
          update_time: any()
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
    field :language, :string, default: "english"
    field :name, :string
    field :password, :string
    field :rule, :string, default: "basic"
    field :start_recruiting, EctoDate
    field :team_size, :integer, default: nil
    field :thumbnail_path, :string
    field :url, :string
    field :url_token, :string

    belongs_to :platform, Platform
    belongs_to :game, Game
    belongs_to :master, User

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
      :count,
      :capacity,
      :description,
      :deadline,
      :discord_server_id,
      :enabled_coin_toss,
      :enabled_map,
      :event_date,
      :game_name,
      :is_started,
      :is_team,
      :language,
      :master_id,
      :password,
      :platform_id,
      :rule,
      :start_recruiting,
      :team_size,
      :thumbnail_path,
      :url,
      :url_token
    ])
    |> generate_rule_if_empty()
    |> validate_required([:name, :capacity, :master_id, :is_team, :rule])
    |> foreign_key_constraint(:platform_id)
    |> foreign_key_constraint(:game_id)
    |> foreign_key_constraint(:master_id)
    |> put_password_hash()
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
      :language,
      :thumbnail_path,
      :password,
      :rule,
      :url,
      :url_token,
      :platform_id,
      :master_id,
      :count,
      :is_started,
      :is_team,
      :start_recruiting
    ])
    |> validate_required([:name, :capacity])
    |> foreign_key_constraint(:platform_id)
    |> foreign_key_constraint(:game_id)
    |> foreign_key_constraint(:master_id)
    |> put_password_hash()
  end

  defp generate_rule_if_empty(changeset) do
    case get_change(changeset, :rule) do
      nil -> put_change(changeset, :rule, "basic")
      "" -> put_change(changeset, :rule, "basic")
      _ -> changeset
    end
  end

  defp put_password_hash(%Ecto.Changeset{valid?: true, changes: %{password: password}} = changeset) do
    change(changeset, password: create_pass(password))
  end

  defp put_password_hash(changeset), do: changeset

  defp create_pass(password), do: Argon2.hash_pwd_salt(password)
end
