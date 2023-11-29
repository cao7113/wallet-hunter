defmodule ChainSigils do
  @doc """
  Generate a bip39 mnemonic
  """
  def sigil_m(len, []) do
    len
    |> String.to_integer()
    |> Cryptopunk.create_mnemonic()
  end

  @doc """
  Generate ether key
  """
  def sigil_k(key_int, []) do
    key_int
    |> String.to_integer()
    |> KeyHelper.cast!()
    |> KeyHelper.gen_account()
  end

  @doc """
  Generate ether address
  iex>  ~a/0/i
  """
  def sigil_a(addr, [?i]) do
    addr
    |> String.to_integer()
    |> Types.EvmAddress.cast!()
  end

  def sigil_a(addr, [?c]) do
    addr
    |> Types.EvmAddress.cast!()
    |> to_string()
    |> Cryptopunk.Crypto.Ethereum.ChecksumEncoding.encode()
  end
end
