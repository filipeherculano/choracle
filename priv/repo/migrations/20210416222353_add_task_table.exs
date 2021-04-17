defmodule Choracle.Repo.Migrations.AddTaskTable do
  use Ecto.Migration

  def up do
    create table(:task, primary_key: false) do
      add :name, :string, size: 100, primary_key: true
      add :period, :integer

      timestamps()
    end
  end

  def down do
    drop table(:task)
  end
end
