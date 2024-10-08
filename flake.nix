{
  description = "A simple Elixir script using tz library with CLI arg support";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
        
        elixirScript = pkgs.writeText "script.exs" ''
          Mix.install([
            {:tz, "~> 0.26"}
          ])

          defmodule TimezonePrinter do
            def print_time(timezone) do
              Calendar.put_time_zone_database(Tz.TimeZoneDatabase)
              DateTime.now!(timezone)
              |> IO.inspect()
            end
          end

          case System.argv() do
            [timezone] -> TimezonePrinter.print_time(timezone)
            _ -> IO.puts("Usage: elixir script.exs <timezone>")
          end
        '';

        runScript = pkgs.writeShellScriptBin "run-elixir-script" ''
          ${pkgs.beam.packages.erlang.elixir}/bin/elixir ${elixirScript} "$@"
        '';

      in
      {
        packages.default = runScript;

        apps.default = flake-utils.lib.mkApp {
          drv = runScript;
        };

        devShells.default = pkgs.mkShell {
          buildInputs = with pkgs; [
            beam.packages.erlang.elixir
            beam.packages.erlang.elixir_ls
          ];
        };
      }
    );
}