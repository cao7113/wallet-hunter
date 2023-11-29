defmodule Types.EvmAddress do
  @moduledoc """
  Ethereum compatible address, 20 bytes.
  """

  use Ecto.Type

  @byte_size 20
  @hex_size @byte_size * 2
  @bits_size @byte_size * 8

  defstruct [:bytes]

  @type t :: %__MODULE__{
          bytes: <<_::_*unquote(@byte_size)>>
        }

  @impl Ecto.Type
  @spec type() :: :bytea
  def type, do: :bytea

  @impl Ecto.Type
  @spec load(term()) :: {:ok, t()} | :error
  def load(<<bytes::bytes-size(@byte_size)>>), do: {:ok, %__MODULE__{bytes: bytes}}
  def load(_), do: :error

  @impl Ecto.Type
  @spec dump(t()) :: {:ok, binary()} | :error
  def dump(%__MODULE__{bytes: <<bytes::bytes-size(@byte_size)>>}), do: {:ok, bytes}
  def dump(_), do: :error

  @impl Ecto.Type
  def equal?(term1, term2) do
    with {:ok, %{bytes: a1}} <- cast(term1),
         {:ok, %{bytes: a2}} <- cast(term2) do
      a1 === a2
    else
      _ -> false
    end
  end

  @impl Ecto.Type
  @spec cast(term()) :: {:ok, t()} | :error
  def cast(<<"0x", hex_string::bytes-size(@hex_size)>>), do: cast_hex(hex_string)
  def cast(<<hex_string::bytes-size(@hex_size)>>), do: cast_hex(hex_string)
  def cast(<<bytes::bytes-size(@byte_size)>>), do: {:ok, %__MODULE__{bytes: bytes}}

  def cast(term) when is_integer(term) and term >= 0,
    do: {:ok, %__MODULE__{bytes: <<term::8*@byte_size>>}}

  def cast(%__MODULE__{bytes: <<_::bytes-size(@byte_size)>>} = term), do: {:ok, term}
  def cast(_term), do: :error

  def cast!(term) do
    {:ok, addr} = cast(term)
    addr
  end

  defp cast_hex(hex_string) do
    case Base.decode16(hex_string, case: :mixed) do
      {:ok, bytes} -> {:ok, %__MODULE__{bytes: bytes}}
      _ -> :error
    end
  end

  def to_integer(%__MODULE__{bytes: <<n::@bits_size>>}), do: n

  def to_string(%__MODULE__{bytes: bytes}) do
    "0x" <> encode_bytes(bytes)
  end

  def to_inspect(%__MODULE__{} = a) do
    "EvmAddress<hex: \"#{a}\" >"
  end

  defp encode_bytes(nil), do: ""

  defp encode_bytes(<<bytes::bytes-size(@byte_size)>>) do
    Base.encode16(bytes, case: :lower)
  end

  def is_zero?(%__MODULE__{bytes: <<0::@bits_size>>}), do: true
  def is_zero?(_), do: false

  defimpl String.Chars do
    def to_string(hash) do
      @for.to_string(hash)
    end
  end

  defimpl Inspect do
    def inspect(hash, _opts) do
      @for.to_inspect(hash)
    end
  end

  defimpl Jason.Encoder do
    alias Jason.Encode

    def encode(hash, opts) do
      hash
      |> to_string()
      |> Encode.string(opts)
    end
  end

  ## Consider use CryptoPunk

  # def to_checksum(%__MODULE__{bytes: bytes}) do
  #   chars =
  #     bytes
  #     |> encode_bytes()
  #     |> Keccak.keccak_256()
  #     |> to_halfbytes()
  #     |> Enum.zip(Enum.map(to_halfbytes(bytes), &Integer.to_string(&1, 16)))
  #     |> Enum.map(fn
  #       {h, b} when h > 7 -> b
  #       {_, b} -> String.downcase(b)
  #     end)

  #   ["0x" | chars]
  #   |> Enum.join()
  # end

  # defp to_halfbytes(bytes) do
  #   for <<half::4 <- bytes>>, do: half
  # end
end
