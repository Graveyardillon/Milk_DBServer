defmodule Milk.TournamentTag do

  import Ecto.Query, warn: false
  alias Milk.Repo
  alias Milk.Tournaments.{
    TagRelations,
    Tag,
  }

  def get_tag!(id), do: Repo.get!(Tag, id)
  def list(), do: Repo.all(Tag)

  def create_tag(tag_name) do
    %Tag{}
    |> Tag.changeset(%{name: tag_name})
    |> IO.inspect()
    |> Repo.insert()
  end

  def delete_tag(tag_id) do
    Tag
    |> Repo.get(tag_id)
    |> Repo.delete()
  end


  def update_relation(tournament, tag_ids) do
    TagRelations
    |> where(tournament_id: ^tournament.id)
    |> IO.inspect()
    |> Repo.delete_all()

    tags = Enum.map(tag_ids, fn(tag_id) ->
      get_tag!(tag_id)
    end)

    tournament
    |> Repo.preload(:tags)
    |> Ecto.Changeset.change()
    |> Ecto.Changeset.put_assoc(:tags, tags)
    |> Repo.update()
  end
end
