# Geeny App Broker Client for Elixir

## Introduction

A simple Elixir Client on top of HTTPoison that interacts with the AppBroker API of Geeny

## Installation

Just include the dependency in your `mix.exs` file.

```elixir
def deps do
  [
    {:app_broker_client_ex,
       git: "https://github.com/diegoeche/geeny_app_broker_client",
       branch: "master"
    }
  ]
end
```

## Setup & configuration

The library uses environment variable to configure the endpoints.

Environment Variables:
```
     # App Broker
     APP_BROKER_URL = <your app broker instance>
```


## Get Started

Check the `/test` folder for a complete overview of the functionality supported.

```elixir
    app = "Your App UUID"
    message = "Your message Id"
    Geeny.AppBrokerClient.describe(app, message)
    |> Enum.map(fn(shard_id) ->
      Geeny.AppBrokerClient.get_iterator(app, message, shard_id)
    end)
```

## License

Copyright (C) 2017 Telefónica Germany Next GmbH, Charlottenstrasse 4, 10969 Berlin.

This project is licensed under the terms of the [Mozilla Public License Version 2.0](LICENSE.md).

Inconsolata font is copyright (C) 2006 The Inconsolata Project Authors. This Font Software is licensed under the [SIL Open Font License, Version 1.1](OFL.txt).
