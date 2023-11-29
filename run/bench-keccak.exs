#! /usr/bin/env mix run

defmodule BenchKeccak do
  def abx_hash(bytes) do
    Keccak.keccak_256(bytes)
  end

  def nif_hash(bytes) do
    ExKeccak.hash_256(bytes)
  end

  def test(times, f, inputs \\ :crypto.strong_rand_bytes(100))

  def test(0, _f, inputs), do: inputs

  def test(times, f, inputs) when times > 0 and is_function(f) do
    test(times - 1, f, f.(inputs))
  end
end

Benchee.run(
  %{
    "abx-hash" => fn {times, seed} ->
      BenchKeccak.test(times, &BenchKeccak.abx_hash/1, seed)
    end,
    "nif-hash" => fn {times, seed} ->
      BenchKeccak.test(times, &BenchKeccak.nif_hash/1, seed)
    end
  },
  inputs: %{
    "Small" => {1000, :crypto.strong_rand_bytes(100)},
    "Big" => {1_000_000, :crypto.strong_rand_bytes(1000)}
  }
)
