defmodule Choracle.Factory do
  @moduledoc false

  alias Choracle.Repo

  # API

  def build!(:setup, chat_id \\ 1) do
    choracle1 = build!(:choracle, chat_id, 5)
    mr_slacker = build!(:roomie, choracle1, "Mr. Slacker", 1, 4)
    mr_clean = build!(:roomie, choracle1, "Mr. Clean", 4, 1)
    # build!(:task, 1 ...)
    # build!(:task, 1 ...)

    choracle2 = build!(:choracle, 2, 10)
    build!(:roomie, choracle2, "Mr. Slacker", 3, 7)
    mr_even = build!(:roomie, choracle2, "Mr. Even", 5, 5)
    # build!(:task, 2 ...)
    # build!(:task, 2 ...)

    choracle3 = build!(:choracle, 3, 15)
    build!(:roomie, choracle3, "Mr. Clean", 9, 6)
    build!(:roomie, choracle3, "Mr. Event", 7, 8)
    # build!(:task, 3 ...)
    # build!(:task, 3 ...)

    mr_new = build!(:roomie_pendent, choracle1, "Mr. New", 2, 3)

    %{
      mr_clean: mr_clean,
      mr_even: mr_even,
      mr_new: mr_new,
      mr_slacker: mr_slacker,
      choracle1: choracle1,
      choracle2: choracle2,
      choracle3: choracle3
    }
  end

  # Factory

  defp build!(:choracle, chat_id, max) do
    Repo.insert!(%Repo.Choracle{chat_id: chat_id, max_volume: max})
  end

  defp build!(:roomie, %Repo.Choracle{chat_id: chat_id} = choracle, name, wk, wknd) do
    roomie = %Repo.Roomie{chat_id: chat_id, name: name, weekly_volume: wk, weekend_volume: wknd}

    choracle
    |> Ecto.build_assoc(:roomies, roomie)
    |> Repo.insert!()
  end

  defp build!(:roomie_pendent, %Repo.Choracle{chat_id: chat_id} = choracle, name, wk, wknd) do
    roomie = %Repo.Roomie{chat_id: chat_id, name: name, weekly_volume: wk, weekend_volume: wknd}

    Ecto.build_assoc(choracle, :roomies, roomie)
  end
end
