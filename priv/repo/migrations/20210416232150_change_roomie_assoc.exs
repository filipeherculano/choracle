defmodule Choracle.Repo.Migrations.ChangeRoomieAssoc do
  use Ecto.Migration

  def change do
    alter table(:roomie) do
      add :chat_id, references(:choracle, type: :integer, column: :chat_id)
      add :last_worker, references(:task, type: :string, column: :name)
    end

    create unique_index(:roomie, [:last_worker])
  end
end
