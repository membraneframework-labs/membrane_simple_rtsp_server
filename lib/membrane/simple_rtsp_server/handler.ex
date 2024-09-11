defmodule Membrane.SimpleRTSPServer.Handler do
  @moduledoc false

  use Membrane.RTSP.Server.Handler

  require Membrane.Logger

  alias Membrane.RTSP.Response
  @video_pt 96
  @video_clock_rate 90_000
  @audio_pt 97
  @audio_clock_rate 90_000

  @impl true
  def init(config) do
    config
    |> Map.put(:pipeline_pid, nil)
    |> Map.put(:socket, nil)
  end

  @impl true
  def handle_open_connection(conn, state) do
    %{state | socket: conn}
  end

  @impl true
  def handle_describe(_req, state) do
    sdp = """
    v=0
    m=video 0 RTP/AVP #{@video_pt}
    a=control:video
    a=rtpmap:#{@video_pt} H264/#{@video_clock_rate}
    a=fmtp:#{@video_pt} packetization-mode=1
    """

    # m=audio 0 RTP/AVP #{@audio_pt}
    # a=control:audio
    # a=rtpmap:#{@audio_pt} MP4A-LATM/#{@audio_clock_rate}

    response =
      Response.new(200)
      |> Response.with_header("Content-Type", "application/sdp")
      |> Response.with_body(sdp)

    {response, state}
  end

  @impl true
  def handle_setup(_req, state) do
    {Response.new(200), state}
  end

  @impl true
  def handle_play(configured_media_context, state) do
    media_context = configured_media_context |> Map.values() |> List.first()

    {client_rtp_port, _client_rtcp_port} = media_context.client_port

    arg = %{
      socket: state.socket,
      ssrc: media_context.ssrc,
      pt: @video_pt,
      clock_rate: @video_clock_rate,
      client_port: client_rtp_port,
      client_ip: media_context.address,
      server_rtp_socket: media_context.rtp_socket,
      mp4_path: state.mp4_path
    }

    {:ok, _sup_pid, pipeline_pid} =
      Membrane.SimpleRTSPServer.Pipeline.start_link(arg)

    {Response.new(200), %{state | pipeline_pid: pipeline_pid}}
  end

  @impl true
  def handle_pause(state) do
    {Response.new(501), state}
  end

  @impl true
  def handle_teardown(state) do
    {Response.new(200), state}
  end

  @impl true
  def handle_closed_connection(_state), do: :ok
end
