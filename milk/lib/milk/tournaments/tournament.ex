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
    TournamentChatTopic
  }

  schema "tournaments" do
    field :capacity, :integer
    field :deadline, EctoDate
    field :description, :string
    field :event_date, EctoDate
    field :name, :string
    field :type, :integer
    field :url, :string
    field :thumbnail_path, :string
    field :password, :string
    field :count, :integer, default: 0
    field :game_name, :string
    field :is_started, :boolean, default: false
    field :start_recruiting, EctoDate

    belongs_to :platform, Platform
    belongs_to :game, Game
    belongs_to :master, User
    has_many :lives, Live
    has_many :entrant, Entrant
    has_many :assistant, Assistant
    has_many :tournament_chat_topics, TournamentChatTopic

    timestamps()
  end

  @doc false
  def create_changeset(tournament, attrs) do
    tournament
    |> cast(attrs, [
      :name,
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
      :start_recruiting
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
      :start_recruiting
    ])
    |> validate_required([:name, :event_date, :capacity, :deadline])
    |> foreign_key_constraint(:platform_id)
    |> foreign_key_constraint(:game_id)
    |> foreign_key_constraint(:master_id)
    |> put_password_hash()
  end
end
