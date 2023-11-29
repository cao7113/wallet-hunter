defmodule Hunter.Schema.Address do
  use Ecto.Schema
  use Endon
  import Ecto.Changeset
  alias Types.EvmAddress

  schema "addresses" do
    field :address, EvmAddress
    field :txn_count, :integer
    field :balance, :decimal
    field :fetch_at, :utc_datetime
    field :data, :map

    field :key_id, :integer
    belongs_to :key, Hunter.Schema.Key, define_field: false

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(address, attrs) do
    address
    |> cast(attrs, [:address, :key_id, :balance, :txn_count, :fetch_at, :data])
    |> validate_required([:address])
    |> unique_constraint([:address])
  end
end
