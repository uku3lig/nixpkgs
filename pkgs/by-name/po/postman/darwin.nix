{
  stdenvNoCC,
  fetchurl,
  unzip,
  pname,
  version,
  meta,
}:

let
  appName = "Postman.app";
  dist =
    {
      aarch64-darwin = {
        arch = "arm64";
        sha256 = "sha256-uhhrJk/WtM4tKsrBAn1IjHx0OeR/SpdOzy2XhoUP4sY=";
      };

      x86_64-darwin = {
        arch = "64";
        sha256 = "sha256-NYxcZoQYDyn85RkUz57b5yhzpeAK5xyyJF/7L2+3tt4=";
      };
    }
    .${stdenvNoCC.hostPlatform.system}
      or (throw "Unsupported system: ${stdenvNoCC.hostPlatform.system}");

in

stdenvNoCC.mkDerivation {
  inherit pname version meta;

  src = fetchurl {
    url = "https://dl.pstmn.io/download/version/${version}/osx_${dist.arch}";
    inherit (dist) sha256;
    name = "${pname}-${version}.zip";
  };

  nativeBuildInputs = [ unzip ];

  # Postman is notarized on macOS. Running the fixup phase will change the shell scripts embedded
  # in the bundle, which causes the notarization check to fail on macOS 13+.
  # See https://eclecticlight.co/2022/06/17/app-security-changes-coming-in-ventura/ for more information.
  dontFixup = true;

  sourceRoot = appName;

  installPhase = ''
    runHook preInstall
    mkdir -p $out/{Applications/${appName},bin}
    cp -R . $out/Applications/${appName}
    cat > $out/bin/${pname} << EOF
    #!${stdenvNoCC.shell}
    open -na $out/Applications/${appName} --args "\$@"
    EOF
    chmod +x $out/bin/${pname}
    runHook postInstall
  '';
}
