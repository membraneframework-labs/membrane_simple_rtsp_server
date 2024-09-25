defmodule Membrane.SimpleRTSPServer.IntegrationTest do
  use ExUnit.Case

  @tag :tmp_dir
  test "Received file is the same as the sent one", %{tmp_dir: tmp_dir} do
    input_path = "test/fixtures/input.mp4"

    output_path = Path.join(tmp_dir, "output.mp4")
    Membrane.SimpleRTSPServer.start_link(input_path, port: 40_001, realtime: true)
    Process.sleep(50)
    Boombox.run(input: "rtsp://localhost:40001/", output: output_path)

    assert File.read!(input_path) == File.read!(output_path)
  end
end
