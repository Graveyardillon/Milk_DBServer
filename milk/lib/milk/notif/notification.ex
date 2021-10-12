defmodule Milk.Notif.Notification do
  use Milk.Schema

  import Ecto.Changeset

  alias Milk.Accounts.User

  @type t :: %__MODULE__{
    body_text: String.t() | nil,
    data: String.t() | nil,
    icon_path: String.t() | nil,
    is_checked: boolean(),
    process_id: String.t() | nil,
    title: String.t(),
    user_id: integer(),
    # NOTE: timestamps
    create_time: any(),
    update_time: any()
  }

  schema "notifications" do
    field :body_text, :string
    field :data, :string
    field :icon_path, :string
    field :is_checked, :boolean, default: false
    field :process_id, :string
    field :title, :string

    belongs_to :user, User

    timestamps()
  end

  @doc false
  def changeset(notification, attrs) do
    notification
    |> cast(attrs, [:title, :body_text, :process_id, :data, :is_checked, :icon_path])
    |> validate_required([:title])
  end

  @doc false
  def update_changeset(notification, attrs) do
    notification
    |> cast(attrs, [:title, :body_text, :process_id, :data, :is_checked, :icon_path])
  end
end
