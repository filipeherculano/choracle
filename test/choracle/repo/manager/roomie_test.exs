defmodule Choracle.Repo.Manager.RoomieTest do
  use ExUnit.Case, async: true

  alias Choracle.Repo
  alias Choracle.Repo.Roomie
  alias Choracle.Repo.Manager.Roomie, as: RoomieManager

  setup do
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(Repo)

    choracle = %Choracle.Repo.Choracle{chat_id: 1, max_volume: 7}
    mr_slacker = %Roomie{name: "Mr. Slacker", weekly_volume: 2, weekend_volume: 5}
    mr_clean = %Roomie{name: "Mr. Clean", weekly_volume: 5, weekend_volume: 2}

    # TODO insert choracle using the library once implemented
    {:ok, choracle} = Repo.insert(choracle)
    {:ok, mr_slacker} = choracle |> Ecto.build_assoc(:roomies, mr_slacker) |> Repo.insert()

    {:ok, mr_slacker: mr_slacker, mr_clean: mr_clean, choracle: choracle}
  end

  describe "insert/4" do
    test "smoke", %{mr_clean: mr_clean, choracle: %{chat_id: chat_id}} do
      %Roomie{name: name, weekly_volume: wk, weekend_volume: wknd} = mr_clean

      assert {:ok,
              %Roomie{chat_id: ^chat_id, name: ^name, weekly_volume: ^wk, weekend_volume: ^wknd}} =
               RoomieManager.insert(chat_id, name, wk, wknd)
    end

    test "already present roomie should fail to insert", %{
      mr_slacker: mr_slacker,
      choracle: %{chat_id: chat_id}
    } do
      %Roomie{name: name, weekly_volume: wk, weekend_volume: wknd} = mr_slacker
      assert {:error, :name_must_be_unique} = RoomieManager.insert(chat_id, name, wk, wknd)
    end

    test "with out of range value on week volume should fail to insert", %{
      mr_clean: mr_clean,
      choracle: %{chat_id: chat_id}
    } do
      %Roomie{name: name, weekly_volume: wk, weekend_volume: wknd} = %Roomie{
        mr_clean
        | weekly_volume: -1
      }

      assert {:error, :out_of_range} = RoomieManager.insert(chat_id, name, wk, wknd)
    end

    test "with out of range value on weekend volume should fail to insert", %{
      mr_clean: mr_clean,
      choracle: %{chat_id: chat_id}
    } do
      %Roomie{name: name, weekly_volume: wk, weekend_volume: wknd} = %Roomie{
        mr_clean
        | weekend_volume: -1
      }

      assert {:error, :out_of_range} = RoomieManager.insert(chat_id, name, wk, wknd)
    end

    test "name must be A-Z and a-z characters", %{
      mr_clean: %{weekly_volume: wk, weekend_volume: wknd},
      choracle: %{chat_id: chat_id}
    } do
      name_wrong = "."

      assert {:error, :name_format} = RoomieManager.insert(chat_id, name_wrong, wk, wknd)
    end

    test "name must not exceed 100 characters", %{
      mr_clean: %{weekly_volume: wk, weekend_volume: wknd},
      choracle: %{chat_id: chat_id}
    } do
      name_with_101 =
        "AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA"

      Repo.all(Roomie)

      assert {:error, :name_length} = RoomieManager.insert(chat_id, name_with_101, wk, wknd)
    end
  end

  describe "delete/1" do
    test "smoke", %{mr_slacker: %Roomie{name: name}} do
      assert {:ok, ^name} = RoomieManager.delete(name)
      assert [] = Repo.all(Roomie)
    end

    test "with unknown Roomie" do
      assert {:error, :not_found} = RoomieManager.delete("Unknown")
    end
  end

  describe "update/1" do
    test "smoke", %{mr_slacker: %{name: name, weekly_volume: wk, weekend_volume: wknd}} do
      wk = wk + 2
      wknd = wknd - 2
      new_slacker = %{weekly_volume: wk, weekend_volume: wknd}

      assert {:ok, %{name: ^name, weekly_volume: ^wk, weekend_volume: ^wknd}} =
               RoomieManager.update(name, new_slacker)
    end

    test "with unknown Roomie" do
      assert {:error, :not_found} = RoomieManager.delete("Unknown")
    end
  end
end
