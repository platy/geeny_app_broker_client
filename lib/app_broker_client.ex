defmodule Geeny.AppBrokerClient do
  require Logger
  @headers [{"Content-Type", "application/json"}]
  @options [recv_timeout: 2000]

  @iterator_types %{
    latest: "LATEST",
    earliest: "EARLIEST",
    at_sequence_number: "AT_SEQUENCE_NUMBER",
    after_sequence_number: "AFTER_SEQUENCE_NUMBER",
    last_checkpoint: "LAST_CHECKPOINT"
  }

  def host do
    System.get_env("GEENY_APPLICATION_BROKER_SUBSCRIBER_URL")
  end

  def health_url do
    Geeny.AppBrokerClient.host <> "/health"
  end

  def describe_url(app_id, message_type) do
    "#{Geeny.AppBrokerClient.host}/app/#{app_id}/messageType/#{message_type}"
  end

  def iterator_url(app_id, message_type) do
    "#{describe_url(app_id, message_type)}/iterator"
  end

  def iterator_url(app_id, message_type, iterator_id) do
    "#{describe_url(app_id, message_type)}/iterator/#{iterator_id}"
  end

  def checkpoint_url(app_id, message_type) do
    "#{describe_url(app_id, message_type)}/checkpoint"
  end

  def get(url, do: block) do
    case HTTPoison.get(url, @headers, @options) do
      {:ok, %HTTPoison.Response{status_code: 200, body: body}} ->
        block.(body)
      {_, response} ->
        Logger.error("Error calling #{url}:" <> inspect(response))
        {:error, response}
    end
  end

  # Returns (:ok or Error)
  def health do
    get(health_url()) do
      fn(_) -> :ok end
    end
  end

  # Returns ([ShardIds] or Error)
  def describe(app_id, message_type) do
    get(describe_url(app_id, message_type)) do
      fn (body) ->
        body
        |> Poison.decode!
        |> Map.fetch!("shards")
        |> Enum.map(fn (shard_obj) -> Map.fetch!(shard_obj, "shardId") end)
      end
    end
  end

  # Returns ([ShardIds] or Error)
  def get_iterator(app, message_type, shard_id, iterator_type \\ @iterator_types.earliest, batch_size \\ 100) do
    json_params = %{
      shardId: shard_id,
      iteratorType: iterator_type,
      maxBatchSize: batch_size
      # TODO:
      # startingSequenceNumber:
    } |> Poison.encode!

    url = iterator_url(app, message_type)
    Logger.info("Requesting iterator for: #{url}, #{json_params}")
    case HTTPoison.post(url, json_params, @headers, @options) do
      {:ok, %HTTPoison.Response{status_code: 200, body: body}} ->
        body
        |> Poison.decode!
        |> Map.fetch!("shardIterator")
      {_, response} ->
        Logger.error("Error creating iterator #{url}: " <> inspect(response))
        {:error, response}
    end
  end

  def get_messages(app, message_type, iterator_id) do
    get(iterator_url(app, message_type, iterator_id)) do
      fn (body) ->
        body
        |> Poison.decode!
        |> json_to_message_response
      end
    end
  end

  def json_to_message_response(json) do
    %{
      next_iterator: json["nextIterator"],
      messages: Enum.map(json["messages"], &json_to_message/1)
    }
  end

  def json_to_message(json) do
    decoded_payload =
      json["payload"]
      |> Base.decode64!
      |> Poison.decode!

    %{
      thing_id: json["thingId"],
      sequence_number: json["sequenceNumber"],
      user_id: json["userId"],
      value: decoded_payload
    }
  end

  def create_checkpoints(app, message_type, checkpoints) do
    json_params =
      checkpoints
      |> Enum.map(fn(cp) -> %{ shardId: cp.shard_id, sequenceNumber: cp.sequence_number } end)
      |> (fn (cps) -> %{ checkpoints: cps } end).()
      |> Poison.encode!

    url = checkpoint_url(app, message_type)

    case HTTPoison.post(url, json_params, @headers, @options) do
      {:ok, %HTTPoison.Response{status_code: 200}} ->
        :ok
      {_, response} ->
        Logger.error("Error checkpointing #{url}: " <> inspect(response))
        {:error, response}
    end
  end
end
