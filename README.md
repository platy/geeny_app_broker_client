# Geeny App Broker Client for Elixir

A simple Client on top of HTTPoison that interacts with the AppBroker API of Geeny

## Installation

```elixir
def deps do
  [{:app_broker_client_ex, "~> 0.1.0"}]
end
```

## Usage

```
    app = "Your App UUID"
    message = "Your message Id"
    Geeny.AppBrokerClient.describe(app, message)
    |> Enum.map(fn(shard_id) ->
      Geeny.AppBrokerClient.get_iterator(app, message, shard_id)
    end)
```
