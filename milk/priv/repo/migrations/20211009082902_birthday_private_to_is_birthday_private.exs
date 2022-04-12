defmodule Milk.Repo.Migrations.BirthdayPrivateToIsBirthdayPrivate do
  use Ecto.Migration

  def change do
    rename table(:users), :birthday_private, to: :is_birthday_private
  end
end
