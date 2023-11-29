defmodule Hunter do
  @moduledoc """
  Hunter keeps the contexts that define your domain
  and business logic.

  Contexts are also responsible for managing your data, regardless
  if it comes from the database, an external API or others.
  """

  require Logger
  # import Ecto.Query

  alias Hunter.Repo
  alias Hunter.Schema

  def remote_hit(q \\ Schema.Key, opts \\ []) do
    wait_ms = opts[:wait_ms] || 200
    remote_api = Hunter.Remote.BscscanAPI

    Repo.loop_up(q, fn items, acc ->
      items
      |> Enum.chunk_every(20)
      |> Enum.reduce([], fn chunk, chunk_acc ->
        chunk
        |> Enum.map(fn it ->
          it.address |> to_string()
        end)
        |> remote_api.req_balances(opts)
        |> TupleHelper.ok_result!()
        |> Enum.filter(fn %{"balance" => bal} ->
          bal > 0
        end)
        |> case do
          [] -> chunk_acc
          c -> [c | chunk_acc]
        end
        |> tap(fn _ ->
          # wait a moment?
          Process.sleep(wait_ms)
        end)
      end)
      |> case do
        [] -> acc
        c -> [c | acc]
      end
    end)
  end
end
