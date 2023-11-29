#! /usr/bin/env mix run

Benchee.run(
  %{
    "custom-keypair" => fn times ->
      Stream.repeatedly(fn ->
        KeyHelper.gen_account()
      end)
      |> Enum.take(times)
    end,
    "gen_with_crypto_app" => fn times ->
      Stream.repeatedly(fn ->
        KeyHelper.gen_with_crypto_app()
      end)
      |> Enum.take(times)
    end,
    "gen_with_public_key_app" => fn times ->
      Stream.repeatedly(fn ->
        KeyHelper.gen_with_public_key_app()
      end)
      |> Enum.take(times)
    end
  },
  inputs: %{
    "Small" => 100,
    "Big" => 10_000
  }
)
