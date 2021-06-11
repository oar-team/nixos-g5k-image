
# nixos-g5k-generate.sh - generate NixOS image for Grid'5000

**nixos-g5k-generate.sh** is a tool to generate a [NixOS](https://nixos.org) system image deployable on [Grid'5000](https://www.grid5000.fr) testbed platform. It uses the [nixos-configurators](https://github.com/nix-community/nixos-generators) tool.

## Installation
Just clone the repository
```console
$ git clone git@github.com:oar-team/nixos-g5k-image.git
```

## Usage

First prepare a configuration.nix file which fits your needs (e.g. configuration.nix, configuration-webserver.nix).

A very simple one:
```console
{ pkgs, ... }:
{
  # add vim editor
  environment.systemPackages = with pkgs; [ vim ];

  users.users.root.password = "nixos";
  # note: ssh server is enable  and firewall is disable
}
```

To generate an image archive and its associated kadeploy environment description file:

```console
# commands are launched on a Grid'5000' node
SITE=$(hostname -d | cut -d'.' -f1)
./nixos-g5k-generate.sh -c configuration.nix -u http://public.$SITE.grid5000.fr/~$USER \
-I nixpkgs=channel:nixos-21.05 -d ~/public -n nixos-test
```

To deploy on Grid'5000 nodes: 
```console
SITE=$(hostname -d | cut -d'.' -f1)
 kadeploy3 -f $OAR_NODEFILE -a http://public.$SITE.grid5000.fr/~$USER/nixos-test.yaml -k
```

Variant generation with pinning (i.e. for reproducibiliy with fixed version)

```console
./nixos-g5k-generate.sh -c configuration.nix -n nixos-test -u http://public.grenoble.grid5000.fr/~$USER \
-I nixpkgs=https://github.com/nixos/nixpkgs/archive/7e9b0dff974c89e070da1ad85713ff3c20b0ca97.tar.gz -d ~/public
```
