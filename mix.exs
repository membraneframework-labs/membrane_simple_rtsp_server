defmodule Membrane.SimpleRTSPServer.Mixfile do
  use Mix.Project

  @version "0.1.0"
  @github_url "https://github.com/membraneframework-labs/membrane_simple_rtsp_server"

  def project do
    [
      app: :membrane_simple_rtsp_server,
      version: @version,
      elixir: "~> 1.13",
      elixirc_paths: elixirc_paths(Mix.env()),
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      dialyzer: dialyzer(),

      # hex
      description: "Simple RTSP Server based on Membrane Framework",
      package: package(),

      # docs
      name: "Membrane Simple RTSP Server",
      source_url: @github_url,
      docs: docs(),
      homepage_url: "https://membrane.stream"
    ]
  end

  def application do
    [
      extra_applications: []
    ]
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_env), do: ["lib"]

  defp deps do
    [
      {:membrane_core, "~> 1.0"},
      {:membrane_rtsp_plugin,
       github: "membraneframework-labs/membrane_rtsp_plugin",
       branch: "audio-depayloading",
       override: true},
      {:membrane_rtp_plugin, "~> 0.29.0"},
      {:membrane_rtp_h264_plugin, "~> 0.19.0"},
      # {:membrane_rtp_aac_plugin, "~> 0.9.0"},
      {:membrane_file_plugin, "~> 0.17.0"},
      {:membrane_mp4_plugin, "~> 0.35.0"},
      {:membrane_h26x_plugin, "~> 0.10.0"},
      {:membrane_aac_plugin, "~> 0.19.0", override: true},
      {:ex_sdp, github: "membraneframework/ex_sdp", branch: "aac-fmtp", override: true},
      {:membrane_udp_plugin, "~> 0.14.0"},
      {:membrane_realtimer_plugin, "~> 0.9.0"},
      {:boombox, github: "membraneframework/boombox", branch: "fix-rtsp-track", only: :test},
      {:ex_doc, ">= 0.0.0", only: :dev, runtime: false},
      {:dialyxir, ">= 0.0.0", only: :dev, runtime: false},
      {:credo, ">= 0.0.0", only: :dev, runtime: false}
    ]
  end

  defp dialyzer() do
    opts = [
      flags: [:error_handling]
    ]

    if System.get_env("CI") == "true" do
      # Store PLTs in cacheable directory for CI
      [plt_local_path: "priv/plts", plt_core_path: "priv/plts"] ++ opts
    else
      opts
    end
  end

  defp package do
    [
      maintainers: ["Membrane Team"],
      licenses: ["Apache-2.0"],
      links: %{
        "GitHub" => @github_url,
        "Membrane Framework Homepage" => "https://membrane.stream"
      }
    ]
  end

  defp docs do
    [
      main: "readme",
      extras: ["README.md", "LICENSE"],
      formatters: ["html"],
      source_ref: "v#{@version}",
      nest_modules_by_prefix: [Membrane.SimpleRTSPServer]
    ]
  end
end
