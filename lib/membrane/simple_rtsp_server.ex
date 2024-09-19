defmodule Membrane.SimpleRTSPServer do
  @moduledoc """
  Module for starting a simple RTSP Server that streams a MP4 file.
  """

  @spec start_link(String.t(), :inet.port_number(), :inet.ip4_address()) :: GenServer.on_start()
  def start_link(mp4_path, rtsp_port \\ 554, address \\ {127, 0, 0, 1}) do
    Membrane.RTSP.Server.start_link(
      handler: Membrane.SimpleRTSPServer.Handler,
      handler_config: %{mp4_path: mp4_path},
      port: rtsp_port,
      address: address,
      udp_rtp_port: 0,
      udp_rtcp_port: 0
    )
  end
end
