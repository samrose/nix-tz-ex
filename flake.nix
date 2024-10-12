{
  description = "Elixir escript application with setup command and local Mix/Hex";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
        elixir = pkgs.beam.packages.erlang.elixir;
        
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
            _ -> IO.puts("Usage: nix run .#time-in-tz <timezone>")
          end
        '';
        
        runScript = pkgs.writeShellScriptBin "run-elixir-script" ''
          # Set up local Mix and Hex
          mkdir -p .nix-mix .nix-hex
          export MIX_HOME=$PWD/.nix-mix
          export HEX_HOME=$PWD/.nix-hex
          export PATH=$MIX_HOME/bin:$HEX_HOME/bin:$PATH

          ${elixir}/bin/elixir ${elixirScript} "$@"
        '';

        setupScript = pkgs.writeShellScriptBin "elixir-setup" ''
          echo "Setting up Elixir environment..."

          # Set up local Mix and Hex
          mkdir -p .nix-mix .nix-hex
          export MIX_HOME=$PWD/.nix-mix
          export HEX_HOME=$PWD/.nix-hex
          export PATH=$MIX_HOME/bin:$HEX_HOME/bin:$PATH

          ${elixir}/bin/mix local.hex --force
          ${elixir}/bin/mix local.rebar --force
          echo "Elixir setup complete. You can now run your application."
        '';

      in
      {
        packages = {
          timeInTz = runScript;
          setup = setupScript;
        };

        apps = {
          time-in-tz = flake-utils.lib.mkApp {
            drv = runScript;
          };
          setup = {
            type = "app";
            program = "${setupScript}/bin/elixir-setup";
          };
        };

        devShells.default = pkgs.mkShell {
          buildInputs = with pkgs; [
            elixir
            beam.packages.erlang.elixir_ls
          ];
          shellHook = ''
            mkdir -p .nix-mix .nix-hex
            export MIX_HOME=$PWD/.nix-mix
            export HEX_HOME=$PWD/.nix-hex
            export PATH=$MIX_HOME/bin:$HEX_HOME/bin:$PATH
          '';
        };
      }
    );
}