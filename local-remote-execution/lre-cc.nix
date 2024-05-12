{
  pkgs,
  buildImage,
  llvmPackages,
}: let
  customStdenv = import ../tools/llvmStdenv.nix {inherit pkgs llvmPackages;};
  customClang = pkgs.callPackage ../tools/customClang.nix {
    inherit pkgs;
    stdenv = customStdenv;
  };

  # This environment is shared between toolchain autogen images and the final
  # toolchain image.
  Env = [
    # Add all tooling here so that the generated toolchains use `/nix/store/*`
    # paths instead of `/bin` or `/usr/bin`. This way we're guaranteed to use
    # binary identical toolchains during local and remote execution.
    ("PATH="
      + (pkgs.lib.strings.concatStringsSep ":" [
        "${customStdenv.cc.bintools}/bin"
        "${customClang}/bin"
        "${customStdenv}/bin"
        "${pkgs.coreutils}/bin"
        "${pkgs.findutils}/bin"
        "${pkgs.gnutar}/bin"
      ]))

    "CC=${customClang}/bin/customClang"
  ];
in
  buildImage {
    name = "lre-cc";
    maxLayers = 100;
    config = {inherit Env;};
    # Attached for passthrough to rbe-configs-gen.
    meta = {inherit Env;};

    # Don't set a tag here so that the image is tagged by its derivation hash.
    # tag = null;
  }
