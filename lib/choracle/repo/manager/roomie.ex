defmodule Choracle.Repo.Manager.Roomie do
  @moduledoc """
  This modules manages every operation on the `roomie` table. Also
  handles database errors that might come up and translate them to
  specific Roomie.errors().
  """

  alias Choracle.Repo
  alias Choracle.Repo.Choracle, as: ChoracleAlias
  alias Choracle.Repo.Roomie

  require Logger

  @type crud :: :insert | :get | :all | :delete | :update

  @doc """
  Inserts new Roomie into the database.
  """
  @spec insert(integer(), String.t(), integer(), integer()) ::
          {:ok, %Roomie{}} | Roomie.errors()
  def insert(chat_id, name, week_vol, weekend_vol) do
    params = %{name: name, weekly_volume: week_vol, weekend_volume: weekend_vol}

    # TODO use library once built
    with choracle <- Repo.get(ChoracleAlias, chat_id),
         {:ok, %Roomie{name: name} = roomie} <-
           choracle
           |> Ecto.build_assoc(:roomies)
           |> Roomie.registration_changeset(params)
           |> Repo.insert() do
      Logger.info("Successfully added `#{name}` as your roomie")
      {:ok, roomie}
    else
      nil ->
        {:error, :not_found}

      {:error, changeset} ->
        Roomie.handle_errors(changeset)
    end
  end

  @doc """
  Deletes a already existing Roomie.
  """
  @spec delete(String.t()) :: {:ok, %Roomie{}} | Roomie.errors()
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
  @spec update(String.t(), map()) :: {:ok, %Roomie{}} | Roomie.errors()
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

  @doc """
  Get a user by it's name.
  """
  @spec get(String.t()) :: %Roomie{} | {:error, :not_found}
  def get(name) do
    case Repo.get(Roomie, name) do
      nil ->
        Logger.error("No roommates found with name: #{name}")

        {:error, :not_found}

      roomie ->
        {:ok, roomie}
    end
  end

  @doc """
  Get all users names.
  """
  @spec all() :: list(%Roomie{})
  def all() do
    Repo.all(Roomie)
  end
end
