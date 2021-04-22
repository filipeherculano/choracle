defmodule Choracle.Repo.Manager.Roomie do
  @moduledoc """
  This modules manages every operation on the `roomie` table. Also
  handles database errors that might come up and translate them to
  specific Roomie.errors().
  """

  alias Choracle.Repo
  alias Choracle.Repo.Choracle, as: ChoracleAlias
  alias Choracle.Repo.Roomie

  import Ecto.Query

  require Logger

  @type errors :: {:error, :not_found} | Roomie.errors()
  @type crud :: :insert | :get_all | :get_one | :delete | :update

  @doc """
  Inserts new Roomie into the database.
  """
  @spec insert(integer(), String.t(), integer(), integer()) :: {:ok, %Roomie{}} | errors()
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
      {:error, changeset} ->
        Logger.warn("Failed to insert #{name}` as your roomie")
        Roomie.handle_errors(changeset)
    end
  rescue
    # For choracle unknown
    _ ->
      {:error, :not_found}
  end

  @doc """
  Deletes a already existing Roomie.
  """
  @spec delete(integer(), String.t()) :: {:ok, %Roomie{}} | errors()
  def delete(chat_id, name) do
    {:ok, roomie} = get_one(chat_id, name)

    roomie
    |> Repo.delete()
    |> case do
      {:ok, roomie} ->
        Logger.info("Roomie #{name} deleted")
        {:ok, roomie}

      {:error, changeset} ->
        Logger.error("Failed to delete roomie #{name}")
        Roomie.handle_errors(changeset)
    end
  rescue
    _ ->
      {:error, :not_found}
  end

  @doc """
  Updates existing Roomie information
  """
  @spec update(integer(), String.t(), map()) :: {:ok, %Roomie{}} | errors()
  def update(chat_id, name, params) do
    {:ok, roomie} = get_one(chat_id, name)
    params = params |> Map.put_new(:chat_id, chat_id) |> Map.put_new(:name, name)

    roomie
    |> Roomie.update_changeset(params)
    |> Repo.update([])
    |> case do
      {:ok, %Roomie{name: name} = roomie} ->
        Logger.info("Roomie #{name} updated")
        {:ok, roomie}

      {:error, changeset} ->
        Logger.error("Failed to update roomie #{name}")
        Roomie.handle_errors(changeset)
    end
  rescue
    _ ->
      {:error, :not_found}
  end

  @doc """
  Get a user by it's name.
  """
  @spec get_one(integer(), String.t()) :: %Roomie{} | errors()
  def get_one(chat_id, name) do
    case Repo.all(from r in Roomie, where: [chat_id: ^chat_id, name: ^name]) do
      [] ->
        Logger.error("No roommates found with name: #{name} on chat_id: #{chat_id}")

        {:error, :not_found}

      [roomie] ->
        {:ok, roomie}
    end
  end

  @doc """
  Get all users.
  """
  @spec get_all(integer()) :: list(%Roomie{}) | errors()
  def get_all(chat_id) do
    from(c in ChoracleAlias,
      where: [chat_id: ^chat_id],
      join: r in assoc(c, :roomies),
      preload: [roomies: r]
    )
    |> Repo.all()
    |> case do
      [] ->
        Logger.error("No choracle bots found with chat_id: #{chat_id}")

        {:error, :not_found}

      [%ChoracleAlias{roomies: roomies}] ->
        {:ok, roomies}
    end
  end
end
