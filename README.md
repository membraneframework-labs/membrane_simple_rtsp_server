# Membrane Simple RTSP Server

[![Hex.pm](https://img.shields.io/hexpm/v/membrane_simple_rtsp_server.svg)](https://hex.pm/packages/membrane_simple_rtsp_server)
[![API Docs](https://img.shields.io/badge/api-docs-yellow.svg?style=flat)](https://hexdocs.pm/membrane_simple_rtsp_server)
[![CircleCI](https://circleci.com/gh/membraneframework-labs/membrane_simple_rtsp_server.svg?style=svg)](https://circleci.com/gh/membraneframework-labs/membrane_simple_rtsp_server)

A Simple RTSP server that serves a MP4 file

## Installation

The package can be installed by adding `membrane_simple_rtsp_server` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:membrane_simple_rtsp_server, "~> 0.1.2"}
  ]
end
```

## Usage

To serve a MP4 file run the following:
```elixir
Membrane.SimpleRTSPServer.start_link("path/to/file.mp4", port: 30001)
```

To receive and immediately play the stream you can use a tool like `ffplay`:
```sh
ffplay rtsp://localhost:30001
```

To receive the mp4 and store it you can use a tool like [Boombox](https://github.com/membraneframework/boombox):
```elixir
Boombox.run(input: "rtsp://localhost:30001", output: "output.mp4")
```

## Copyright and License

Copyright 2020, [Software Mansion](https://swmansion.com/?utm_source=git&utm_medium=readme&utm_campaign=membrane_template_plugin)

[![Software Mansion](https://logo.swmansion.com/logo?color=white&variant=desktop&width=200&tag=membrane-github)](https://swmansion.com/?utm_source=git&utm_medium=readme&utm_campaign=membrane_template_plugin)

Licensed under the [Apache License, Version 2.0](LICENSE)
