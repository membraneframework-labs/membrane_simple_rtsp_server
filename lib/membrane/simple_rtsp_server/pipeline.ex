defmodule Membrane.SimpleRTSPServer.Pipeline do
  @moduledoc false

  use Membrane.Pipeline

  @spec start_link(map()) :: Membrane.Pipeline.on_start()
  def start_link(config) do
    Membrane.Pipeline.start_link(__MODULE__, config)
  end

  @impl true
  def handle_init(_ctx, opts) do
    spec =
      child(:mp4_in_file_source, %Membrane.File.Source{
        location: opts.mp4_path,
        seekable?: true
      })
      |> child(:mp4_demuxer, %Membrane.MP4.Demuxer.ISOM{optimize_for_non_fast_start?: true})

    {[spec: spec], opts}
  end

  @impl true
  def handle_child_notification({:new_tracks, tracks}, :mp4_demuxer, _ctx, state) do
    spec =
      [child(:rtp_session_bin, Membrane.RTP.SessionBin)] ++
        Enum.map(tracks, fn
          {id, %Membrane.AAC{}} ->
            get_child(:mp4_demuxer)
            |> via_out(Pad.ref(:output, id))
            |> build_track(:audio, state.media_config, state.realtime)

          {id, %Membrane.H264{}} ->
            get_child(:mp4_demuxer)
            |> via_out(Pad.ref(:output, id))
            |> build_track(:video, state.media_config, state.realtime)
        end)

    {[spec: spec], state}
  end

  @impl true
  def handle_child_notification(_notification, _element, _ctx, state) do
    {[], state}
  end

  @impl true
  def handle_element_end_of_stream({:udp_sink, :video}, :input, _ctx, state) do
    :gen_tcp.close(state.socket)
    {[terminate: :normal], state}
  end

  @impl true
  def handle_element_end_of_stream(_child, _pad, _ctx, state) do
    {[], state}
  end

  defp build_track(builder, :audio, %{audio: config}, realtime) do
    builder
    |> child(:aac_parser, %Membrane.AAC.Parser{
      out_encapsulation: :none,
      output_config: :audio_specific_config
    })
    |> via_in(Pad.ref(:input, config.ssrc),
      options: [payloader: %Membrane.RTP.AAC.Payloader{frames_per_packet: 1, mode: :hbr}]
    )
    |> build_tail(:audio, config, realtime)
  end

  defp build_track(builder, :video, %{video: config}, realtime) do
    builder
    |> child(:h264_parser, %Membrane.H264.Parser{
      output_alignment: :nalu,
      repeat_parameter_sets: true,
      skip_until_keyframe: true,
      output_stream_structure: :annexb
    })
    |> via_in(Pad.ref(:input, config.ssrc),
      options: [payloader: Membrane.RTP.H264.Payloader]
    )
    |> build_tail(:video, config, realtime)
  end

  defp build_track(builder, _type, _media_config, _realtime) do
    builder
    |> child(Membrane.Debug.Sink)
  end

  defp build_tail(builder, type, config, realtime) do
    builder
    |> get_child(:rtp_session_bin)
    |> via_out(Pad.ref(:rtp_output, config.ssrc),
      options: [
        payload_type: config.pt,
        clock_rate: config.clock_rate
      ]
    )
    |> then(
      &if realtime,
        do: &1 |> child({:realtimer, type}, Membrane.Realtimer),
        else: &1
    )
    |> child({:udp_sink, type}, %Membrane.UDP.Sink{
      destination_address: config.client_address,
      destination_port_no: config.client_port,
      local_socket: config.rtp_socket
    })
  end
end
