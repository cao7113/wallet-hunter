defmodule BitHelper do
  @moduledoc """
  Bitwise Helpers

  0b1010
  <<0b1010, 0b0::1>>
  """

  @doc """
  iex(83)> BitHelper.to_bitstring "1010"
  <<10::size(4)>>
  """
  def to_bitstring(str) when is_binary(str) do
    for <<byte::binary-1 <- str>>, into: <<>> do
      case byte do
        "0" -> <<0::1>>
        "1" -> <<1::1>>
      end
    end

    # padding to byte?
  end
end
