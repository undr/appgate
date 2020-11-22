defmodule AppGate.ProxyTest do
  use ExUnit.Case
  doctest AppGate.Proxy

  test "greets the world" do
    assert AppGate.Proxy.hello() == :world
  end
end
