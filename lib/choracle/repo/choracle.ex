defmodule Choracle.Repo.Choracle do
  @moduledoc false

  use Ecto.Schema

  alias Choracle.Repo.Roomie

  import Ecto.Changeset

  @primary_key false
  schema "choracle" do
    field :chat_id, :integer, primary_key: true
    field :max_volume, :integer
    has_many :roomie, Roomie, references: :chat_id
    has_many :task, Task, references: :chat_id

    timestamps()
  end

  def registration_changeset(choracle, params \\ %{}) do
    choracle
    |> cast(params, [:chat_id, :max_volume])
    |> validate_required([:chat_id, :max_volume])
    |> unique_constraint(:chat_id, name: :choracle_pkey)
    |> check_constraint(:max_volume, name: :max_volume_range, message: "Maximum volume must be positive and no more than 200")
  end

  def delete_changeset(choracle, params \\ %{}) do
    choracle
    |> cast(params, [:chat_id])
    |> validate_required([:chat_id])
  end

  def update_changeset(choracle, params \\ %{}) do
    choracle
    |> cast(params, [:chat_id, :max_volume])
    |> validate_required([:chat_id, :max_volume])
  end
end
