defmodule Tailwind.SourceBuilderTest do
  use ExUnit.Case, async: true

  alias Tailwind.SourceBuilder

  describe "check_rust_available/0" do
    test "returns :ok when Rust is available" do
      # This test will pass if Rust is installed on the system
      # and fail if it's not, which is useful for CI/CD
      case SourceBuilder.check_rust_available() do
        :ok -> assert true
        {:error, msg} -> flunk("Rust not available: #{msg}")
      end
    end
  end

  describe "build_from_source?/0" do
    test "returns false by default" do
      # Test the default configuration
      assert Tailwind.build_from_source?() == false
    end

    test "can be configured via Application config" do
      # Test that the configuration can be set
      Application.put_env(:tailwind, :build_from_source, true)
      assert Tailwind.build_from_source?() == true

      # Clean up
      Application.delete_env(:tailwind, :build_from_source)
      assert Tailwind.build_from_source?() == false
    end
  end

  describe "install_path/1" do
    test "returns correct path for target" do
      target = "freebsd-arm64"
      path = SourceBuilder.install_path(target)

      assert String.contains?(path, "tailwind-#{target}")
      assert String.contains?(path, "_build")
    end
  end
end
