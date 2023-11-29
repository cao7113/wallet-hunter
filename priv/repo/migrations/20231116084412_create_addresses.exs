defmodule Hunter.Repo.Migrations.CreateAddresses do
  use Ecto.Migration

  def change do
    create table(:addresses) do
      add :address, :binary, null: false
      add :key_id, :integer
      add :balance, :decimal
      add :txn_count, :integer
      add :fetch_at, :utc_datetime
      add :data, :map

      timestamps(type: :utc_datetime)
    end

    create unique_index(:addresses, :address)
    create unique_index(:addresses, :key_id)
    create index(:addresses, :txn_count)
  end
end
