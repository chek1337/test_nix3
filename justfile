flake := "."

# Show all available commands
default:
    @just --list

# Apply configuration for the current host
[group("deploy")]
switch hostname:
    sudo nixos-rebuild switch --flake "{{flake}}#{{hostname}}"

# Test configuration without applying services
[group("deploy")]
test hostname:
    sudo nixos-rebuild test --flake "{{flake}}#{{hostname}}"

# Build configuration without applying
[group("deploy")]
build hostname:
    nixos-rebuild build --flake "{{flake}}#{{hostname}}"

# Add all new files to git and apply configuration
[group("deploy")]
deploy hostname:
    git add .
    just switch {{hostname}}

# Generate hardware-configuration.nix for the current machine
[group("utils")]
gen-hardware hostname:
    sudo nixos-generate-config --show-hardware-config \
        > "modules/hosts/{{hostname}}/_hardware-configuration.nix"
    @echo "Saved to modules/hosts/{{hostname}}/_hardware-configuration.nix"

# Check flake configuration
[group("utils")]
check:
    nix flake check

# Update all inputs
[group("utils")]
update:
    nix flake update

# Update a specific input
[group("utils")]
update-input input:
    nix flake update {{input}}

# Remove old generations
[group("utils")]
gc:
    sudo nix-collect-garbage -d
    nix-collect-garbage -d
