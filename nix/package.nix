{
  bash,
  bat,
  bc,
  coreutils,
  curl,
  delta,
  diffutils,
  findutils,
  git,
  gnugrep,
  gnused,
  gum,
  jq,
  less,
  lib,
  makeWrapper,
  nodejs,
  stdenv,
  util-linux,
  wget,
  xclip,
  xsel,
}:

let
  manifest = builtins.fromJSON (builtins.readFile ./package-manifest.json);
  sourceRoot = lib.cleanSource ../upstream;
  licenseMap = {
    "MIT" = lib.licenses.mit;
  };
  resolvedLicense =
    if builtins.hasAttr manifest.meta.licenseSpdx licenseMap
    then licenseMap.${manifest.meta.licenseSpdx}
    else lib.licenses.unfree;
  runtimeInputs =
    [
      bash
      bat
      bc
      coreutils
      curl
      delta
      diffutils
      findutils
      git
      gnugrep
      gnused
      gum
      jq
      less
      nodejs
      util-linux
      wget
    ]
    ++ lib.optionals stdenv.hostPlatform.isLinux [
      xclip
      xsel
    ];
in
stdenv.mkDerivation {
  pname = manifest.binary.name;
  version = manifest.package.version;
  src = sourceRoot;

  nativeBuildInputs = [ makeWrapper ];
  dontBuild = true;

  installPhase = ''
    runHook preInstall

    shareRoot="$out/share/${manifest.binary.name}"
    mkdir -p "$shareRoot"
    cp -R . "$shareRoot"/
    chmod +x "$shareRoot/${manifest.binary.entrypoint}"
    patchShebangs "$shareRoot/${manifest.binary.entrypoint}"

    mkdir -p "$out/bin"
    makeWrapper "$shareRoot/${manifest.binary.entrypoint}" "$out/bin/${manifest.binary.name}" \
      --prefix PATH : ${lib.makeBinPath runtimeInputs}

    runHook postInstall
  '';

  meta = with lib; {
    description = manifest.meta.description;
    homepage = manifest.meta.homepage;
    license = resolvedLicense;
    mainProgram = manifest.binary.name;
    platforms = platforms.linux ++ platforms.darwin;
  };
}
