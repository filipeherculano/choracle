defmodule Choracle.Repo.Roomie do
  @moduledoc false

  use Ecto.Schema

  alias Choracle.Repo.Choracle, as: ChoracleAlias

  import Ecto.Changeset

  require Logger

  @type errors :: {:error, :out_of_range | :name_must_be_unique | :name_length | :name_format}

  schema "roomie" do
    field :name, :string
    field :weekly_volume, :integer
    field :weekend_volume, :integer
    belongs_to :choracle, ChoracleAlias, foreign_key: :chat_id, references: :chat_id

    timestamps()
  end

  @spec registration_changeset(%__MODULE__{}, map()) :: Changeset.t()
  def registration_changeset(roomie, params) do
    roomie
    |> cast(params, [:chat_id, :name, :weekly_volume, :weekend_volume])
    |> validate_required([:chat_id, :name, :weekly_volume, :weekend_volume])
    |> validate_format(:name, ~r/[A-Za-z]/)
    |> validate_length(:name, max: 100)
    |> unique_constraint([:chat_id, :name], opts(:roomie_chat_id_name_index))
    |> check_constraint(:weekly_volume, opts(:weekly_volume_ranges))
    |> check_constraint(:weekend_volume, opts(:weekend_volume_ranges))
  end

  @spec delete_changeset(%__MODULE__{}) :: Changeset.t()
  def delete_changeset(roomie), do: validate_required(roomie, [:chat_id, :name])

  @spec update_changeset(%__MODULE__{}, map()) :: Changeset.t()
  def update_changeset(roomie, params) do
    roomie
    |> cast(params, [:chat_id, :name, :weekly_volume, :weekend_volume])
    |> validate_required([:chat_id, :name])
  end

  @spec handle_errors(map()) :: errors()
  def handle_errors(%{errors: [error | _]}) do
    case error do
      {:name, {msg, opts}} ->
        Logger.error(msg)

        case opts[:validation] do
          :length ->
            {:error, :name_length}

          :format ->
            {:error, :name_format}
        end

      {:chat_id, {msg, _opts}} ->
        Logger.error(msg)
        {:error, :name_must_be_unique}

      {_, {msg, _opts}} ->
        Logger.error(msg)
        {:error, :out_of_range}
    end
  end

  defp opts(:roomie_chat_id_name_index = constraint),
    do: [
      name: constraint,
      message: "Cannot insert two roomies with the same name under the same chat"
    ]

  defp opts(:weekly_volume_ranges = constraint),
    do: [name: constraint, message: "Weekly volume must be positive and no more than 100"]

  defp opts(:weekend_volume_ranges = constraint),
    do: [name: constraint, message: "Weekend volume must be positive and no more than 100"]
end
