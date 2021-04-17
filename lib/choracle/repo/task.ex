defmodule Choracle.Repo.Task do
  @moduledoc false

  use Ecto.Schema

  alias Choracle.Repo.Choracle

  import Ecto.Changeset

  require Logger

  @primary_key false
  schema "task" do
    field :name, :string, primary_key: false
    field :period, :integer
    belongs_to :choracle, Choracle, references: :chat_id
    has_one :roomie, Roomie, references: :name

    timestamps()
  end

  def registration_changeset(task, params \\ %{}) do
    task
    |> cast(params, [:name, :period])
    |> validate_required([:name, :period])
    |> validate_format(:name, ~r/[A-Za-z]/)
    |> validate_length(:name, max: 100)
    |> unique_constraint(:name, name: :task_pkey)
  end

  def delete_changeset(name), do: cast(%__MODULE__{name: name}, %{}, [])

  def update_changeset(name, params \\ %{}) do
    now = NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second)
    task = %__MODULE__{name: name}

    task
    |> cast(params, [:period])
    |> put_change(:updated_at, now)
  end
end