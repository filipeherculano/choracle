defmodule Choracle.Repo.Manager.Roomies do
  @moduledoc """
  This modules manages every operation on the `roomie` table.
  """
  @moduledoc since: "0.1.0"

  alias Choracle.Repo
  alias Choracle.Repo.Roomie

  require Logger

  @doc """
  Inserts new Roomie into the database, if both week and weekend volumes
  sum are equal to the maximum volume a Roomie can take.
  """
  @spec insert(non_neg_integer, String.t(), integer(), integer()) ::
          {:ok, Roomie.t()} | Roomie.errors()
  def insert(chat_id, name, week_vol, weekend_vol) do
    %Roomie{}
    |> Roomie.registration_changeset(%{
      chat_id: chat_id,
      name: name,
      weekly_volume: week_vol,
      weekend_volume: weekend_vol
    })
    |> Repo.insert()
    |> case do
      {:ok, %Roomie{name: name} = struct} ->
        Logger.info("Successfully added `#{name}` as your roomie")
        {:ok, struct}

      {:error, changeset} ->
        Roomie.handle_errors(changeset)
    end
  end

  @doc """
  Deletes a already existing Roomie.
  """
  @spec delete(String.t()) :: {:ok, Roomie.t()} | Roomie.errors()
  def delete(name) do
    name
    |> Roomie.delete_changeset()
    |> Repo.delete()
    |> case do
      {:ok, _} ->
        Logger.info("Roomie #{name} deleted")
        {:ok, name}

      {:error, changeset} ->
        Roomie.handle_errors(changeset)
    end
  rescue
    Ecto.StaleEntryError ->
      {:error, :not_found}
  end

  @doc """
  Updates existing Roomie information
  """
  @spec update(String.t(), map()) :: {:ok, Roomie.t()} | Roomie.errors()
  def update(name, params) do
    name
    |> Roomie.update_changeset(params)
    |> Repo.update([])
    |> case do
      {:ok, %Roomie{name: name} = roomie} ->
        Logger.info("Roomie #{name} updated")
        {:ok, roomie}

      {:error, changeset} ->
        Roomie.handle_errors(changeset)
    end
  rescue
    Ecto.StaleEntryError ->
      {:error, :not_found}
  end

  @spec get(String.t()) :: Roomie.t() | {:error, :not_found}
  def get(name) do
    case Repo.get(Roomie, name) do
      nil ->
        Logger.error("No roommates found with name: #{name}")

        {:error, :not_found}

      roomie ->
        {:ok, roomie}
    end
  end

  @spec all() :: list(Roomie.t())
  def all() do
    Repo.all(Roomie)
  end
end
