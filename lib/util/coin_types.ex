defmodule CoinTypes do
  @moduledoc """
  Extract info from https://github.com/satoshilabs/slips/blob/master/slip-0044.md
  Parse and write to local file
  """

  @source_url "https://raw.githubusercontent.com/satoshilabs/slips/master/slip-0044.md"
  @local_source :code.priv_dir(:hunter) |> to_string() |> Path.join("data/slip0044.md")

  @doc """
  iex>
    CoinTypes.by_symbol(:BTC)
    CoinTypes.by_symbol(:ETH)
  """
  def by_symbol(type_symbol) do
    tp = type_symbol |> to_string()

    coin_types()
    |> Enum.find(fn it ->
      tp == it.symbol
    end)
  end

  # TODO use elixir-native version
  def coin_types do
    parse_coin_types()
  end

  def fetch_doc! do
    Req.get!(@source_url).body
  end

  def load_doc! do
    unless File.exists?(@local_source) do
      File.write!(@local_source, fetch_doc!())
    end

    File.read!(@local_source)
  end

  def parse_coin_types(types_doc \\ load_doc!()) do
    head_line = "## Registered coin types"
    tail_line = "## Libraries"

    types_doc
    |> String.split(head_line, parts: 2)
    |> Enum.at(1)
    |> String.split(tail_line, parts: 2)
    |> Enum.at(0)
    |> String.split("\n")
    |> Stream.filter(fn l ->
      l =~ ~r/^\| [\d]+[\s]*\|/
    end)
    |> Stream.filter(fn l ->
      # "| Coin type  | Path component (`coin_type'`) | Symbol  | Coin                              |"
      # bad cases:
      # * "| 658        | 0x80000292                    |         |"
      parts = String.split(l, "|")
      length(parts) == 6 && Enum.at(parts, -2) |> String.trim() != "reserved"
    end)
    |> Stream.map(fn l ->
      [_, coin_type, path_component, symbol, coin_desc, _] =
        l
        |> String.split("|")

      %{
        coin_type: coin_type |> String.trim() |> String.to_integer(),
        path_component: path_component |> String.trim(),
        symbol: symbol |> String.trim(),
        coin_desc: coin_desc |> String.trim()
      }
    end)
    |> Enum.to_list()
  end
end
