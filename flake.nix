{
  description = "A simple Elixir script using tz library";

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
          Calendar.put_time_zone_database(Tz.TimeZoneDatabase)
          DateTime.now!("Europe/Warsaw")
          |> IO.inspect()
        '';

        runScript = pkgs.writeShellScriptBin "run-elixir-script" ''
          ${pkgs.beam.packages.erlang.elixir}/bin/elixir ${elixirScript}
        '';

      in
      {
        packages.default = runScript;

        apps.default = {
          type = "app";
          program = "${runScript}/bin/run-elixir-script";
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