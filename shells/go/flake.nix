{
  description = "Go dev shell";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

  outputs =
    { nixpkgs, ... }:
    let
      system = "x86_64-linux";
      pkgs = nixpkgs.legacyPackages.${system};
    in
    {
      devShells.${system}.default = pkgs.mkShell {
        packages = with pkgs; [
          go
          gopls # language server
          gotools # goimports, godoc, ...
          go-tools # staticcheck
          delve # dlv debugger
          golangci-lint
        ];

        env = {
          # Use the Go from nixpkgs; don't auto-fetch a toolchain from go.mod.
          GOTOOLCHAIN = "local";
        };

        shellHook = ''
          export PATH="$(go env GOPATH)/bin:$PATH"
        '';
      };
    };
}
