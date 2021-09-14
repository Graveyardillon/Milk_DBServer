defmodule Maps.PushIos do
  use TypedStruct

  typedstruct do
    field :user_id, integer(), enforce: true
    field :device_token, String.t(), enforce: true
    field :process_id, String.t(), default: "COMMON"
    field :title, String.t(), default: "e-players"
    field :message, String.t(), default: ""
    field :params, map(), default: %{}
  end
end
