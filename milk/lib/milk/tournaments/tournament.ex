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

  schema "tournaments" do
    field :capacity, :integer
    field :count, :integer, default: 0
    field :deadline, EctoDate
    field :description, :string
    field :enabled_coin_toss, :boolean, default: false
    field :enabled_multiple_selection, :boolean, default: false
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

    belongs_to :platform, Platform
    belongs_to :game, Game
    belongs_to :master, User
    has_many :lives, Live
    has_many :entrant, Entrant
    has_many :assistant, Assistant
    has_many :tournament_chat_topics, TournamentChatTopic
    has_many :team, Team
    has_one :custom_detail, TournamentCustomDetail

    timestamps()
  end

  @doc false
  def create_changeset(tournament, attrs) do
    tournament
    |> cast(attrs, [
      :name,
      :enabled_coin_toss,
      :enabled_multiple_selection,
      :event_date,
      :capacity,
      :description,
      :deadline,
      :game_name,
      :thumbnail_path,
      :password,
      :type,
      :url,
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
      :enabled_multiple_selection,
      :event_date,
      :capacity,
      :description,
      :deadline,
      :game_name,
      :thumbnail_path,
      :password,
      :type,
      :url,
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
