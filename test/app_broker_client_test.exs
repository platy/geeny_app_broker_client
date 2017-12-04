defmodule Dokidoki.AppBrokerClientTest do
  use ExUnit.Case
  use ExVCR.Mock, adapter: ExVCR.Adapter.Hackney

  setup do
    System.delete_env("GEENY_APPLICATION_BROKER_SUBSCRIBER_URL")

    System.put_env("GEENY_APPLICATION_BROKER_SUBSCRIBER_URL", "localhost:1319")

    on_exit fn ->
      System.delete_env("GEENY_APPLICATION_BROKER_SUBSCRIBER_URL")
    end
  end

  setup_all do
    ExVCR.Config.cassette_library_dir("fixture/vcr_cassettes")
    :ok
  end

  test "Can be configured using env variables" do
    expected_value = "http://example.com"
    System.put_env("GEENY_APPLICATION_BROKER_SUBSCRIBER_URL", expected_value)
    assert expected_value == Geeny.AppBrokerClient.host
  end

  test "Health success" do
    use_cassette "health_success" do
      result = Geeny.AppBrokerClient.health()
      assert result == :ok
    end
  end

  test "describe success" do
    use_cassette "describe_success" do
      result = Geeny.AppBrokerClient.describe("garmin", "dailies")
      assert result == ["garmin/dailies.json"]
    end
  end

  test "get_iterator success" do
    use_cassette "get_iterator_success" do
      result = Geeny.AppBrokerClient.get_iterator("garmin", "dailies", "garmin/dailies.json")
      assert result == "aab5258c-96c6-416b-8757-a6dacf5281b1"
    end
  end

  test "create_checkpoint success" do
    use_cassette "create_checkpoint_success" do
      iterator = Geeny.AppBrokerClient.create_checkpoints(
        "garmin",
        "dailies",
        [%{shard_id: "garmin/dailies.json", sequence_number: "0"}]
      )
      assert iterator == :ok
    end
  end

  test "get_messages success" do
    use_cassette "get_messages_success" do
      iterator = Geeny.AppBrokerClient.get_iterator("garmin", "dailies", "garmin/dailies.json", "LATEST", 1)
      result = Geeny.AppBrokerClient.get_messages("garmin", "dailies", iterator)

      assert result.next_iterator == "a1584acc-ff61-42d6-aa40-79a28abb6239"
      [ message | [] ] = result.messages
      assert message.thing_id == "1"
      assert message.sequence_number == "0"
      assert message.user_id == "user"
      steps_goal =
        message.value
        |> List.first
        |> fn(summary) -> summary["stepsGoal"] end.()
      assert steps_goal == 6893
    end
  end
end
