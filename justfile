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
alias bo := boot
alias boi := boot-interactive
alias up := update
alias hw := gen-hardware
alias hwi := gen-hardware-interactive

# Stage all changes
[private]
stage:
    git add .

# Apply configuration for the current host
[group("deploy")]
switch hostname: stage
    sudo nixos-rebuild switch --flake "{{flake}}#{{hostname}}"

# Interactively select host and apply
[group("deploy")]
switch-interactive: stage
    just switch $(ls modules/hosts | fzf --prompt="switch > ")

# Test configuration without applying
[group("deploy")]
test hostname: stage
    sudo nixos-rebuild test --flake "{{flake}}#{{hostname}}"

# Test interactively
[group("deploy")]
test-interactive: stage
    just test $(ls modules/hosts | fzf --prompt="test > ")

# Build configuration without applying
[group("deploy")]
build hostname: stage
    nixos-rebuild build --flake "{{flake}}#{{hostname}}"

# Build interactively
[group("deploy")]
build-interactive: stage
    just build $(ls modules/hosts | fzf --prompt="build > ")

# Apply configuration on next boot
[group("deploy")]
boot hostname: stage
    sudo nixos-rebuild boot --flake "{{flake}}#{{hostname}}"

# Apply configuration on next boot interactively
[group("deploy")]
boot-interactive: stage
    just boot $(ls modules/hosts | fzf --prompt="boot > ")

# Generate hardware config for current machine
[group("utils")]
gen-hardware hostname: stage
    sudo nixos-generate-config --show-hardware-config \
        > "modules/hosts/{{hostname}}/_hardware-configuration.nix"
    @echo "Saved to modules/hosts/{{hostname}}/_hardware-configuration.nix"

# Generate hardware config interactively
[group("utils")]
gen-hardware-interactive: stage
    just gen-hardware $(ls modules/hosts | fzf --prompt="gen-hardware > ")

# Check flake
[group("utils")]
check: stage
    nix flake check

# Update all inputs
[group("utils")]
update: stage
    nix flake update

# Update specific input
[group("utils")]
update-input input: stage
    nix flake update {{input}}

# Remove old generations
[group("utils")]
gc: stage
    sudo nix-collect-garbage -d
    nix-collect-garbage -d

# Format all nix files
[group("utils")]
fmt:
    find . -name "*.nix" -not -path "./.git/*" | xargs nixfmt
    just stage
