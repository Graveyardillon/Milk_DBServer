defmodule MilkWeb.RelationController do
    use MilkWeb, :controller

    alias Milk.Relations
    alias Milk.Accounts.Relation
    def create(conn,%{"relation" => params}) do
        Relations.create_relation(params)
        IO.inspect params
        json(conn,%{msg: "Succeed"})
    end
end