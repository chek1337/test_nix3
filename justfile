flake := "."

# Show all available commands
default:
    @just --list

alias sw := switch
alias swi := switch-interactive
alias t := test
alias ti := test-interactive
alias b := build
alias bi := build-interactive
alias d := deploy
alias di := deploy-interactive
alias up := update
alias hw := gen-hardware
alias hwi := gen-hardware-interactive

# Apply configuration for the current host
[group("deploy")]
switch hostname:
    sudo nixos-rebuild switch --flake "{{flake}}#{{hostname}}"

# Interactively select host and apply
[group("deploy")]
switch-interactive:
    just switch $(ls modules/hosts | fzf --prompt="switch > ")

# Test configuration without applying
[group("deploy")]
test hostname:
    sudo nixos-rebuild test --flake "{{flake}}#{{hostname}}"

# Test interactively
[group("deploy")]
test-interactive:
    just test $(ls modules/hosts | fzf --prompt="test > ")

# Build configuration without applying
[group("deploy")]
build hostname:
    nixos-rebuild build --flake "{{flake}}#{{hostname}}"

# Build interactively
[group("deploy")]
build-interactive:
    just build $(ls modules/hosts | fzf --prompt="build > ")

# git add . + switch
[group("deploy")]
deploy hostname:
    git add .
    just switch {{hostname}}

# git add . + interactive switch
[group("deploy")]
deploy-interactive:
    git add .
    just switch-interactive

# Generate hardware config for current machine
[group("utils")]
gen-hardware hostname:
    sudo nixos-generate-config --show-hardware-config \
        > "modules/hosts/{{hostname}}/_hardware-configuration.nix"
    @echo "Saved to modules/hosts/{{hostname}}/_hardware-configuration.nix"

# Generate hardware config interactively
[group("utils")]
gen-hardware-interactive:
    just gen-hardware $(ls modules/hosts | fzf --prompt="gen-hardware > ")

# Check flake
[group("utils")]
check:
    nix flake check

# Update all inputs
[group("utils")]
update:
    nix flake update

# Update specific input
[group("utils")]
update-input input:
    nix flake update {{input}}

# Remove old generations
[group("utils")]
gc:
    sudo nix-collect-garbage -d
    nix-collect-garbage -d

# Format all nix files
[group("utils")]
fmt:
    nixfmt-rfc-style modules/ flake.nix
