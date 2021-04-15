defmodule Choracle.RoomiesTest do
  use ExUnit.Case, async: true

  alias Choracle.Repo
  alias Choracle.Repo.Roomie
  alias Choracle.Roomies

  doctest Roomies

  setup do
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(Repo)

    mr_slacker = %Roomie{name: "Mr. Slacker", weekly_volume: 2, weekend_volume: 5, max_volume: 7}
    mr_clean = %Roomie{name: "Mr. Clean", weekly_volume: 5, weekend_volume: 2, max_volume: 7}

    {:ok, _} = Repo.insert(mr_slacker)

    {:ok, mr_slacker: mr_slacker, mr_clean: mr_clean}
  end

  describe "insert/4" do
    test "smoke", %{mr_clean: mr_clean} do
      %Roomie{name: name, weekly_volume: wk, weekend_volume: wknd, max_volume: max} = mr_clean

      assert {:ok,
              %Choracle.Repo.Roomie{
                max_volume: 7,
                name: "Mr. Clean",
                weekend_volume: 2,
                weekly_volume: 5
              }} = Roomies.insert(name, wk, wknd)
    end

    test "already present roomie should fail to insert", %{mr_slacker: mr_slacker} do
      %Roomie{name: name, weekly_volume: wk, weekend_volume: wknd, max_volume: max} = mr_slacker

      assert {:error, :name_must_be_unique} = Roomies.insert(name, wk, wknd)
    end

    test "with out of range value on week volume should fail to insert", %{mr_clean: mr_clean} do
      %Roomie{name: name, weekly_volume: wk, weekend_volume: wknd, max_volume: max} = %Roomie{
        mr_clean
        | weekly_volume: -1,
          max_volume: 1
      }

      assert {:error, :out_of_range} = Roomies.insert(name, wk, wknd)
    end

    test "with out of range value on weekend volume should fail to insert", %{mr_clean: mr_clean} do
      %Roomie{name: name, weekly_volume: wk, weekend_volume: wknd, max_volume: max} = %Roomie{
        mr_clean
        | weekend_volume: -1,
          max_volume: 4
      }

      assert {:error, :out_of_range} = Roomies.insert(name, wk, wknd)
    end

    test "with out of range value on max volume should fail to insert", %{mr_clean: mr_clean} do
      %Roomie{name: name, weekly_volume: wk, weekend_volume: wknd, max_volume: max} = %Roomie{
        mr_clean
        | weekly_volume: 100,
          max_volume: 105
      }

      assert {:error, :out_of_range} = Roomies.insert(name, wk, wknd)
    end

    test "with sum of weekly volume and weekend volume not equal to max volume should fail to insert",
         %{mr_clean: mr_clean} do
      %Roomie{name: name, weekly_volume: wk, weekend_volume: wknd} = %Roomie{
        mr_clean
        | weekly_volume: 1
      }

      assert {:error, :sum_not_equal} = Roomies.insert(name, wk, wknd)
    end

    test "name must be A-Z and a-z characters", %{
      mr_clean: %{weekly_volume: wk, weekend_volume: wknd}
    } do
      name_wrong = "."

      assert {:error, :name_format} = Roomies.insert(name_wrong, wk, wknd)
    end

    test "name must not exceed 100 characters", %{
      mr_clean: %{weekly_volume: wk, weekend_volume: wknd}
    } do
      name_with_101 =
        "AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA"

      Repo.all(Roomie)

      assert {:error, :name_length} = Roomies.insert(name_with_101, wk, wknd)
    end
  end

  describe "delete/1" do
    test "smoke", %{mr_slacker: %Roomie{name: name}} do
      assert {:ok, ^name} = Roomies.delete(name)
      assert [] = Repo.all(Roomie)
    end

    test "not existing Roomie" do
      assert {:error, :not_found} = Roomies.delete("Unknown")
    end
  end

  describe "update/1" do
    test "smoke", %{mr_slacker: mr_slacker} do
      new_slacker = %{
        weekly_volume: mr_slacker.weekly_volume + 3,
        weekend_volume: mr_slacker.weekend_volume + 2,
        max_volume: mr_slacker.max_volume + 3 + 2
      }

      Roomies.update(mr_slacker.name, new_slacker)
    end

    test "with broken volume logic", %{mr_slacker: mr_slacker} do
      broke1 = %{
        weekly_volume: mr_slacker.weekly_volume + 1,
        weekend_volume: mr_slacker.weekend_volume,
        max_volume: mr_slacker.max_volume
      }

      broke2 = %{
        weekly_volume: mr_slacker.weekly_volume,
        weekend_volume: mr_slacker.weekend_volume + 1,
        max_volume: mr_slacker.max_volume
      }

      broke3 = %{
        weekly_volume: mr_slacker.weekly_volume,
        weekend_volume: mr_slacker.weekend_volume,
        max_volume: mr_slacker.max_volume + 1
      }

      assert {:error, :sum_not_equal} = Roomies.update(mr_slacker.name, broke1)
      assert {:error, :sum_not_equal} = Roomies.update(mr_slacker.name, broke2)
      assert {:error, :sum_not_equal} = Roomies.update(mr_slacker.name, broke3)
    end

    test "with unknown Roomie", %{mr_clean: mr_clean} do
      assert {:error, :not_found} = Roomies.delete(mr_clean.name)
    end
  end
end
