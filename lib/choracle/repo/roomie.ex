defmodule Choracle.Repo.Roomie do
  @moduledoc false

  use Ecto.Schema

  alias Choracle.Repo.Choracle, as: ChoracleAlias
  alias Choracle.Repo.Task

  import Ecto.Changeset

  require Logger

  @type validation_errors :: {:error, :name_must_be_unique, :name_length, :name_format}
  @type errors :: {:error, :out_of_range} | validation_errors()

  @primary_key false
  schema "roomie" do
    field :name, :string, primary_key: true
    field :weekly_volume, :integer
    field :weekend_volume, :integer
    belongs_to :choracle, ChoracleAlias, foreign_key: :chat_id, references: :chat_id
    has_many :tasks, Task, foreign_key: :last_worker_name, references: :name

    timestamps()
  end

  def registration_changeset(roomie, params \\ %{}) do
    roomie
    |> cast(params, [:name, :weekly_volume, :weekend_volume])
    |> validate_required([:name, :weekly_volume, :weekend_volume])
    |> validate_format(:name, ~r/[A-Za-z]/)
    |> validate_length(:name, max: 100)
    |> unique_constraint(:name, name: :roomie_pkey)
    |> check_constraint(:weekly_volume, opts(:weekly_volume_ranges))
    |> check_constraint(:weekend_volume, opts(:weekend_volume_ranges))
  end

  def delete_changeset(name), do: cast(%__MODULE__{name: name}, %{}, [])

  def update_changeset(name, params \\ %{}) do
    now = NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second)
    roomie = %__MODULE__{name: name}

    roomie
    |> cast(params, [:weekly_volume, :weekend_volume])
    |> put_change(:updated_at, now)
  end

  def handle_errors(%{errors: [error | _]}) do
    case error do
      {:name, {msg, opts}} ->
        Logger.error(msg)

        case opts[:validation] do
          nil ->
            {:error, :name_must_be_unique}

          :length ->
            {:error, :name_length}

          :format ->
            {:error, :name_format}
        end

      _ ->
        {:error, :out_of_range}
    end
  end

  defp opts(:weekly_volume_ranges = constraint),
    do: [name: constraint, message: "Weekly volume must be positive and no more than 100"]

  defp opts(:weekend_volume_ranges = constraint),
    do: [name: constraint, message: "Weekend volume must be positive and no more than 100"]
end
