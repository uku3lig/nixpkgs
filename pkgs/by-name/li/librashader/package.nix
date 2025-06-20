{
  fetchFromGitHub,
  lib,
  nix-update-script,
  rustPlatform,
  stdenv,
}:

rustPlatform.buildRustPackage (finalAttrs: {
  pname = "librashader";
  version = "0.6.2";

  src = fetchFromGitHub {
    owner = "SnowflakePowered";
    repo = "librashader";
    tag = "librashader-v${finalAttrs.version}";
    hash = "sha256-zkvCpQ5Cq3sDOspc12/gPmNi6hn/nBe1UfWrMGi/o0Q=";
  };

  patches = [
    ./patches/fix-optional-dep-syntax.patch
  ];

  useFetchCargoVendor = true;
  cargoHash = "sha256-9rwrbCt/obrKlRDWzzc1hm6ywHubz5x6Ujm2JMso0vg=";

  RUSTC_BOOTSTRAP = 1;

  buildPhase = ''
    runHook preBuild
    cargo run -p librashader-build-script -- --profile optimized
    runHook postBuild
  '';

  doCheck = false;

  installPhase =
    ''
      runHook preInstall
      cd target/optimized
      mkdir -p $out/lib $out/include/librashader
    ''
    + (
      if stdenv.hostPlatform.isDarwin then
        ''
          install_name_tool -id $out/lib/librashader.dylib librashader.dylib
          install -m755 librashader.dylib $out/lib/librashader.dylib
        ''
      else
        ''
          patchelf --set-soname librashader.so.2 librashader.so
          install -m755 librashader.so $out/lib/librashader.so.2
          ln -s $out/lib/librashader.so.2 $out/lib/librashader.so
        ''
    )
    + ''
      install -m644 librashader.h -t $out/include/librashader
      install -m644 ../../include/librashader_ld.h -t $out/include/librashader
      runHook postInstall
    '';

  passthru.updateScript = nix-update-script {
    extraArgs = [
      "--version-regex"
      "librashader-v(.*)"
    ];
  };

  meta = {
    description = "RetroArch Shaders for All";
    homepage = "https://github.com/SnowflakePowered/librashader";
    license = with lib.licenses; [
      mpl20
      gpl3Only
    ];
    maintainers = with lib.maintainers; [ nadiaholmquist ];
    platforms = lib.platforms.all;
  };
})
