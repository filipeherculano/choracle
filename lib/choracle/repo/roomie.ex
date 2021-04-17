defmodule Choracle.Repo.Roomie do
  @moduledoc false

  use Ecto.Schema

  alias Choracle.Repo.Choracle

  import Ecto.Changeset

  require Logger

  @type errors :: {:error, :not_found | :must_be_unique | :sum_not_equal | :out_of_range}

  @primary_key false
  schema "roomie" do
    field :name, :string, primary_key: true
    field :weekly_volume, :integer
    field :weekend_volume, :integer
    belongs_to :choracle, Choracle, references: :chat_id
    belongs_to :task, Task, references: :name

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
    |> cast(params, [:weekly_volume, :weekend_volume, :max_volume])
    |> check_constraint(:max_volume, opts(:volumes_sum_must_equal_max_volume))
    |> put_change(:updated_at, now)
  end

  def handle_errors(%{errors: [error | _]}) do
    case error do
      {:max_volume,
       {msg, [constraint: :check, constraint_name: "volumes_sum_must_equal_max_volume"]}} ->
        Logger.error(msg)
        {:error, :sum_not_equal}

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
