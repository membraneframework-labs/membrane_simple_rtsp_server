defmodule Membrane.SimpleRTSPServer.IntegrationTest do
  use ExUnit.Case

  @tag :tmp_dir
  test "Received file is the same as the sent one", %{tmp_dir: tmp_dir} do
    input_path = "test/fixtures/input.mp4"

    output_path = Path.join(tmp_dir, "output.mp4")
    Membrane.SimpleRTSPServer.start_link(input_path, port: 40_001)
    Process.sleep(50)
    Boombox.run(input: "rtsp://localhost:40001/", output: output_path)

    {:ok, %{size: input_size}} = File.stat(input_path)
    {:ok, %{size: output_size}} = File.stat(output_path)
    assert output_size in trunc(input_size * 0.95)..trunc(output_size * 1.05)
  end
end
