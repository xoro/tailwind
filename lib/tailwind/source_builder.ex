defmodule Tailwind.SourceBuilder do
  @moduledoc """
  Builds Tailwind CSS from source code when binaries are not available.

  This module handles:
  - Rust dependency detection
  - Source code cloning
  - Cross-platform compilation
  - Binary installation
  """

  require Logger

  @doc """
  Builds Tailwind CSS from source for the given target platform.

  Returns `{:ok, binary_path}` on success or `{:error, reason}` on failure.
  """
    def build_for_target(target, version) do
    Logger.info("Building Tailwind CSS #{version} from source for target: #{target}")

    with :ok <- check_rust_available(),
         {:ok, source_dir} <- clone_source(version),
         {:ok, binary_path} <- build_binary(source_dir, target) do
      # Don't cleanup here - let the caller handle it after copying
      {:ok, binary_path, source_dir}
    else
      {:error, reason} ->
        Logger.error("Failed to build Tailwind from source: #{reason}")
        {:error, reason}
    end
  end

  @doc """
  Checks if Rust and Cargo are available on the system.
  """
  def check_rust_available do
    case System.find_executable("cargo") do
      nil ->
        {:error, "Rust/Cargo not found. Please install Rust to build from source."}
      _ ->
        case System.cmd("cargo", ["--version"]) do
          {version, 0} ->
            Logger.info("Found Rust: #{String.trim(version)}")
            :ok
          _ ->
            {:error, "Rust installation appears to be broken"}
        end
    end
  end

  @doc """
  Clones the Tailwind CSS source code from GitHub.
  """
  def clone_source(version) do
    temp_dir = Path.join(System.tmp_dir!(), "tailwind-source-#{version}")

    Logger.info("Cloning Tailwind CSS #{version} to #{temp_dir}")

    # Remove existing directory if it exists
    File.rm_rf(temp_dir)

    case System.cmd("git", ["clone", "--depth", "1", "--branch", "v#{version}",
                           "https://github.com/tailwindlabs/tailwindcss.git", temp_dir]) do
      {_output, 0} ->
        Logger.info("Successfully cloned Tailwind source")
        {:ok, temp_dir}
      {error, _code} ->
        Logger.error("Failed to clone Tailwind source: #{error}")
        {:error, "Failed to clone source: #{error}"}
    end
  end

  @doc """
  Builds the Tailwind binary for the target platform.
  """
  def build_binary(source_dir, target) do
    Logger.info("Building Tailwind binary for target: #{target}")

    # Build the binary (don't change directory)
    case System.cmd("cargo", ["build", "--release"], cd: source_dir) do
      {_output, 0} ->
        # Find the built binary
        binary_path = find_built_binary(source_dir, target)
        if binary_path do
          Logger.info("Successfully built Tailwind binary")
          {:ok, binary_path}
        else
          {:error, "Built binary not found"}
        end
      {error, _code} ->
        Logger.error("Failed to build Tailwind: #{error}")
        {:error, "Build failed: #{error}"}
    end
  end

    @doc """
  Finds the built binary in the target directory.
  """
  def find_built_binary(source_dir, target) do
    # The binary is typically in target/release/
    target_dir = Path.join(source_dir, "target/release")

    case File.ls(target_dir) do
      {:ok, files} ->
        Logger.debug("Files in target directory: #{inspect(files)}")

        # Look for executable files (no extension or .exe on Windows)
        binary = Enum.find(files, fn file ->
          is_executable?(file) and (
            String.contains?(file, "tailwind") or
            String.contains?(file, "tailwindcss") or
            file == "tailwindcss" or
            file == "tailwindcss.exe" or
            file == "tailwindcss-oxide" or
            file == "tailwindcss-oxide.exe"
          )
        end)

        if binary do
          Logger.debug("Found built binary for target #{target}: #{binary}")
          Path.join(target_dir, binary)
        else
          Logger.warning("No executable binary found for target #{target} in #{target_dir}")
          Logger.debug("Available files: #{inspect(files)}")
          nil
        end
      _ ->
        Logger.warning("Could not list target directory: #{target_dir}")
        nil
    end
  end

  defp is_executable?(filename) do
    # On Unix-like systems, executables typically have no extension
    # On Windows, they have .exe extension
    case :os.type() do
      {:win32, _} -> String.ends_with?(filename, ".exe")
      _ ->
        # On Unix-like systems, look for files without extensions
        # or specific known executable names
        !String.contains?(filename, ".") or
        filename in ["tailwindcss-oxide", "tailwindcss"]
    end
  end

  @doc """
  Cleans up the temporary source directory.
  """
  def cleanup_source(source_dir) do
    Logger.info("Cleaning up source directory: #{source_dir}")
    File.rm_rf(source_dir)
    :ok
  end

  @doc """
  Returns the path where the built binary should be installed.
  """
  def install_path(target) do
    name = "tailwind-#{target}"

    if Code.ensure_loaded?(Mix.Project) do
      Path.join(Path.dirname(Mix.Project.build_path()), name)
    else
      Path.expand("_build/#{name}")
    end
  end
end
