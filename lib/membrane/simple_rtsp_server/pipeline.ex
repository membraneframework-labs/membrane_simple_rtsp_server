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

    state = Map.merge(opts, %{tracks_playing: nil})

    {[spec: spec], state}
  end

  @impl true
  def handle_child_notification({:new_tracks, tracks}, :mp4_demuxer, _ctx, state) do
    {spec, media_types} =
      Enum.map(tracks, fn
        {id, %Membrane.AAC{}} ->
          {
            get_child(:mp4_demuxer)
            |> via_out(Pad.ref(:output, id))
            |> build_track(:audio, state.media_config),
            :audio
          }

        {id, %Membrane.H264{}} ->
          {
            get_child(:mp4_demuxer)
            |> via_out(Pad.ref(:output, id))
            |> build_track(:video, state.media_config),
            :video
          }
      end)
      |> Enum.unzip()

    {[spec: spec], %{state | tracks_playing: media_types}}
  end

  @impl true
  def handle_child_notification(_notification, _element, _ctx, state) do
    {[], state}
  end

  @impl true
  def handle_element_end_of_stream({:udp_sink, media_type}, :input, _ctx, state) do
    tracks_playing = List.delete(state.tracks_playing, media_type)

    if tracks_playing == [] do
      :gen_tcp.close(state.socket)
      {[terminate: :normal], %{state | tracks_playing: tracks_playing}}
    else
      {[], %{state | tracks_playing: tracks_playing}}
    end
  end

  @impl true
  def handle_element_end_of_stream(_child, _pad, _ctx, state) do
    {[], state}
  end

  defp build_track(builder, :audio, %{audio: config}) do
    builder
    |> child(:aac_parser, %Membrane.AAC.Parser{
      out_encapsulation: :none,
      output_config: :audio_specific_config
    })
    |> child(:aac_payloader, %Membrane.RTP.AAC.Payloader{frames_per_packet: 1, mode: :hbr})
    |> build_tail(:audio, config)
  end

  defp build_track(builder, :video, %{video: config}) do
    builder
    |> child(:h264_parser, %Membrane.H264.Parser{
      output_alignment: :nalu,
      repeat_parameter_sets: true,
      skip_until_keyframe: true,
      output_stream_structure: :annexb
    })
    |> child(:h264_payloader, Membrane.RTP.H264.Payloader)
    |> build_tail(:video, config)
  end

  defp build_track(builder, _type, _media_config) do
    builder
    |> child(Membrane.Debug.Sink)
  end

  defp build_tail(builder, type, config) do
    builder
    |> via_in(:input,
      options: [ssrc: config.ssrc, payload_type: config.pt, clock_rate: config.clock_rate]
    )
    |> child({:rtp_muxer, type}, Membrane.RTP.Muxer)
    |> child({:realtimer, type}, Membrane.Realtimer)
    |> child({:udp_sink, type}, %Membrane.UDP.Sink{
      destination_address: config.client_address,
      destination_port_no: config.client_port,
      local_socket: config.rtp_socket
    })
  end
end
