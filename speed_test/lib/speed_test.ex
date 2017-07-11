require IEx;
defmodule SpeedTest do

  def read_gateway do
    File.cwd!
    |> Path.join("config/gateway.yml")
    |> YamlElixir.read_from_file
  end

  def speed_test do
    gateway_data = read_gateway()
    static_ip = gateway_data["ip"]
    default_gateway = gateway_data["default_gateway"]

    gateway_data["gateways"]
    |> Enum.each(fn(gateway) -> test_and_submit_result(gateway, gateway_data["gateway"][gateway], static_ip) end)

    change_gateway(gateway_data["gateway"][default_gateway], static_ip)
  end

  defp change_gateway(gateway_ip, static_ip) do
    IO.inspect gateway_ip
    IO.inspect System.cmd("sudo", String.split("ip route replace default via " <> gateway_ip))
  end

  defp test_and_submit_result(gateway, gateway_ip, static_ip) do
    change_gateway(gateway_ip, static_ip)
  end

  def hello do
    :world
  end
end
