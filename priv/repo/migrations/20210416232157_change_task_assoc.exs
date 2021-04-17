defmodule Choracle.Repo.Migrations.ChangeTaskAssoc do
  use Ecto.Migration

  def change do
    alter table(:task) do
      add :chat_id, references(:choracle, type: :integer, column: :chat_id)
      add :last_worker, references(:roomie, type: :string, column: :name)
    end
  end
end
