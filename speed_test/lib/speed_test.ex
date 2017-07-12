require IEx;
defmodule SpeedTest do

  def read_gateway do
    File.cwd!
    |> Path.join("config/gateway.yml")
    |> YamlElixir.read_from_file
  end

  def parse_data do
    gateway_data = read_gateway()
    static_ip = gateway_data["ip"]
    default_gateway = gateway_data["default_gateway"]
    office = gateway_data["office"]
    timestamp = System.system_time(:nanosecond)
    interval = gateway_data["interval"]
    { gateway_data, static_ip, default_gateway, office, timestamp, interval }
  end

  def speed_test do
    { gateway_data, static_ip, default_gateway, office, timestamp, interval } = parse_data

    gateway_data["gateways"]
    |> Enum.each(fn(gateway) -> test_and_submit_result(gateway, gateway_data["gateway"][gateway], static_ip, office, timestamp) end)

    change_gateway(gateway_data["gateway"][default_gateway], static_ip)
    :timer.sleep(interval)
    speed_test()
  end

  defp change_gateway(gateway_ip, static_ip) do
    System.cmd("sudo", String.split("ip route replace default via " <> gateway_ip))
  end

  defp test_and_submit_result(gateway, gateway_ip, static_ip, office, timestamp) do
    change_gateway(gateway_ip, static_ip)
    [dl, ul] =
      System.cmd(File.cwd! <> "/scripts/speedtest_cli.py", String.split("--server 603"))
      |> read_result
    write_data(dl, "Download", gateway, office, timestamp)
    write_data(ul, "Upload", gateway, office, timestamp)
  end

  defp read_result({ speeds, 0 }) do
    [dl, ul] =
      speeds
      |> String.split("\n", trim: true)
      |> Enum.map(&String.to_float/1)
  end

  defp write_data(value, type, gateway, office, timestamp) do
    influx_url = "http://localhost:8086/write?db=eanw"
    line = "network" <> ",type=#{type},office=#{office},isp=#{gateway} value=#{value} #{timestamp}"
    HTTPoison.post influx_url, line
  end

  defp read_result({ errors, _ }) do
    IO.puts "Error occured: " <> errors
  end

  def hello do
    :world
  end
end
