defmodule Membrane.SimpleRTSPServer do
  @moduledoc """
  Module for starting a simple RTSP Server that streams a MP4 file.
  """

  @spec start_link(String.t(),
          port: :inet.port_number(),
          address: :inet.ip4_address()
        ) ::
          GenServer.on_start()
  def start_link(mp4_path, opts) do
    Membrane.RTSP.Server.start_link(
      handler: Membrane.SimpleRTSPServer.Handler,
      handler_config: %{mp4_path: mp4_path},
      port: Keyword.get(opts, :port, 554),
      address: Keyword.get(opts, :address, {127, 0, 0, 1}),
      udp_rtp_port: 0,
      udp_rtcp_port: 0
    )
  end
end
