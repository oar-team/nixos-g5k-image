#!/usr/bin/env nix-shell
#! nix-shell -i bash 


# ./nixos-g5k-generate.sh -c configuration.nix -b http://public.grenoble.grid5000.fr/~orichard


set -euo pipefail

readonly libexec_dir="${0%/*}"
readonly example_dir=$libexec_dir/

configuration=$libexec_dir/configuration.nix

format_path="$libexec_dir/format/g5k-image.nix"

target_system=
name=
file_image_baseurl=
destination_image_path=
run_vm=

kaenv_desc="kaenv.yaml"
outlink="result"
                
show_usage() {
  cat <<USAGE
Usage: $0 [options]

Options:

* --help: shows this help
* -c, --configuration PATH:
    select the nixos configuration to build. Default: $configuration
* -o, --out-link: specify the outlink location for nix-build
* --run-vm: generate and run on qemu the correspondant vm-image (NOT YET IMPLEMENTED)
* --system: specify the target system (eg: x86_64-linux, aarch64-linux), by default it is the same of building platform.
* -I KEY=VALUE: add a key to the Nix expression search path (ex: -I nixpkgs=channel:nixos-20.09).
* -d, --destination-image-path PATH: destination path to copy resultin image archive (no copy by default)
 (NOT YET IMPLEMENTED) 
* -n, --name: environment name
* -b, file-image-baseurl: file baseurl for env descripion (ex http://public.grenoble.grid5000.fr/~fnietzsche)

example:
    ./nixos-g5k-generate.sh -c configuration.nix -u http://public.grenoble.grid5000.fr/~orichard -I nixpkgs=channel:nixos-20.09


USAGE
}

abort() {
  echo "aborted: $*" >&2
  exit 1
}

while [[ $# -gt 0 ]]; do
    case "$1" in
        --help)
            show_Usage
            exit
            ;;
        -c | --configuration)
            configuration="$2"
            shift
            ;;
        --system)
            echo "Not yet implemented / tested"
            exit
            target_system=$2
            shift
            ;;
        -I)
            nixos_generate_args+=(-I "$2")
            shift
            ;;
        -o | --out-link)
            outlink="$2"
            shift
            ;;
        --run-vm)
            run_vm=true
            ;;
        -d | --destination-image-path)
            destination_image_path="$2"
            shift
            ;;
        -n | --name)
            name="$2"
            shift
            ;;
        -u | --file-image-baseurl)
            file_image_baseurl="$2"
            shift
            ;;
        *)
            abort "unknown option $1"
            ;;
    esac
    shift
done

if [[ -n $target_system ]]; then
  nixos_generate_args+=(--system "$target_system")
fi

if [[ -n $name ]]; then
    export KAENV_NAME=$name
fi

if [[ -n $file_image_baseurl ]]; then
    export FILE_IMAGE_BASEURL=$file_image_baseurl
fi 

if [[ -n $run_vm ]]; then
   nixos_generate="nixos-generate -c $configuration  --cores 4 ${nixos_generate_args[@]} --run"
   echo $nixos_generate
   $nixos_generate
else
   nixos_generate_args+=(-o $outlink)
   nixos_generate="nixos-generate -c $configuration --cores 4 ${nixos_generate_args[@]} --format-path $format_path" 
   echo $nixos_generate
   $nixos_generate

   if [[ -n $destination_image_path ]]; then
       cp $outlink/*.tar.xz $outlink/*.yaml $destination_image_path/
   fi
fi

