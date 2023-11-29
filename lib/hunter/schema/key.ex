defmodule Hunter.Schema.Key do
  use Ecto.Schema
  use Endon
  import Ecto.Changeset
  alias Types.EvmAddress

  @derive {
    Flop.Schema,
    filterable: [:id, :address, :path, :mnemonic_id],
    sortable: [:mnemonic_id, :path, :inserted_at, :id]
  }

  schema "keys" do
    field :address, EvmAddress
    field :private_key, :string
    field :path, :string
    field :note, :string

    field :mnemonic_id, :integer
    belongs_to(:mnemonic, Hunter.Schema.Mnemonic, define_field: false)

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(key, attrs) do
    key
    |> cast(attrs, [:address, :private_key, :mnemonic_id, :path, :note])
    |> validate_required([:private_key, :address])
    |> unique_constraint(:private_key)
    |> unique_constraint(:address)
  end
end
