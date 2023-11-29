defmodule KeyHelper do
  @moduledoc """
  EVM-like wallet account key and address helper functions.
  """

  @curve_name :secp256k1
  @key_byte_length 32

  # 32-bytes private-key, 65-bytes public-key, 42-bytes address
  @type privkey() :: <<_::256>>
  @type pubkey() :: <<_::520>>
  @type evm_address() :: <<_::336>>
  @type evm_address_bytes() :: <<_::_*20>>
  @type account() :: %{
          private_key: privkey(),
          address: evm_address()
        }

  def rand_private_key, do: gen_private_key_bytes() |> Base.encode16(case: :lower)
  def rand_public_key, do: gen_private_key_bytes() |> pubkey_from() |> Base.encode16(case: :lower)

  def rand_address(k \\ gen_private_key_bytes()) do
    k |> cast! |> pubkey_from() |> address_from()
  end

  def rand_account, do: gen_account()

  def gen_private_key_bytes(), do: :crypto.strong_rand_bytes(@key_byte_length)
  def gen_account(), do: gen_private_key_bytes() |> gen_account()

  def gen_account(k) do
    priv_bytes = cast!(k)
    as_account(priv_bytes, priv_bytes |> pubkey_from())
  end

  def gen_with_crypto_app() do
    {pub_bytes, priv_bytes} = :crypto.generate_key(:ecdh, @curve_name)
    as_account(priv_bytes, pub_bytes)
  end

  def gen_with_public_key_app() do
    {:ECPrivateKey, 1, priv_bytes, _, pub_bytes, _} =
      :public_key.generate_key({:namedCurve, @curve_name})

    as_account(priv_bytes, pub_bytes)
  end

  defp as_account(priv_bytes, pub_bytes) do
    %{
      address: pub_bytes |> address_from(),
      private_key: hex_encode(priv_bytes)
    }
  end

  @spec pubkey_from(privkey()) :: pubkey()
  def pubkey_from(k) do
    priv_bytes = cast!(k)

    :ecdh
    |> :crypto.generate_key(@curve_name, priv_bytes)
    |> elem(0)
  end

  @spec address_from(<<_::520>>) :: evm_address()
  def address_from(<<4, pub_bytes::binary-64>> = _pub_key) do
    <<_::bytes-size(12), addr_bytes::bytes-size(20)>> = keccak_256(pub_bytes)
    hex_encode_with_prefix(addr_bytes)
  end

  @spec keccak_256(bytes :: binary()) :: <<_::256>>
  defdelegate keccak_256(bytes), to: ExKeccak, as: :hash_256

  @spec cast(integer() | <<_::_*32>> | <<_::_*64>> | <<_::16, _::_*64>>) ::
          {:ok, privkey()} | :error
  def cast(int) when is_integer(int) and int > 0, do: {:ok, <<int::256>>}
  def cast(<<"0x", hex_str::binary-64>>), do: cast(hex_str)
  def cast(<<hex_str::binary-64>>), do: hex_decode(hex_str)
  def cast(<<_::binary-32>> = k), do: {:ok, k}
  def cast(_), do: :error

  def cast!(input) do
    with {:ok, bs} <- cast(input) do
      bs
    else
      _ -> raise "invalid private-key!"
    end
  end

  def hex_encode(bytes) when is_binary(bytes), do: Base.encode16(bytes, case: :lower)
  def hex_encode_with_prefix(bytes) when is_binary(bytes), do: "0x" <> hex_encode(bytes)
  def hex_decode(bytes) when is_binary(bytes), do: Base.decode16(bytes, case: :mixed)

  def as_bytes("0x" <> hex_str), do: Base.decode16!(hex_str, case: :mixed)
  def as_bytes(bs) when is_binary(bs), do: bs
  def as_bytes(int) when is_integer(int), do: :binary.encode_unsigned(int)

  def as_integer(int) when is_integer(int), do: int
  def as_integer(bin) when is_binary(bin), do: bin |> as_bytes() |> :binary.decode_unsigned()

  ## Batch gen

  def batch_gen(n \\ 3, opts \\ []) when n > 0 do
    stream_gen(opts) |> Enum.take(n)
  end

  def stream_gen(opts \\ []) do
    init_k = opts[:init_key] || gen_private_key_bytes()
    init_k_int = init_k |> cast! |> as_integer()

    Stream.iterate({1, init_k_int}, fn {i, init_int} ->
      next_i = i + 1
      {next_i, init_int + next_i}
    end)
    |> Stream.map(fn {_, ik} ->
      gen_account(ik)
    end)
  end
end
