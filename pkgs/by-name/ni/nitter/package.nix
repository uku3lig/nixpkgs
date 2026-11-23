{
  lib,
  buildNimPackage,
  fetchFromCodeberg,
  nixosTests,
  unstableGitUpdater,
}:

buildNimPackage (finalAttrs: {
  pname = "nitter";
  version = "0-unstable-2026-11-23";

  src = fetchFromCodeberg {
    owner = "shitter";
    repo = "shitter";
    rev = "40b264a103a03c0298b51d43a44db3286cad4d5d";
    hash = "sha256-1qK1ibZfmGk/ORC6hck9+ndRL6ThFhVtl1/oFyaj1FI=";
  };

  lockFile = ./lock.json;

  patches = [ ./0001-fix-move-away-from-pcre.patch ];

  nimFlags = [
    "-d:gitHash=${finalAttrs.src.rev}"
    "-d:gitDate=1970-01-01"
  ];

  postBuild = ''
    nim compile ${toString finalAttrs.nimFlags} -r tools/gencss
    nim compile ${toString finalAttrs.nimFlags} -r tools/rendermd
  '';

  postInstall = ''
    mkdir -p $out/share/nitter
    cp -r public $out/share/nitter/public
  '';

  passthru = {
    tests = { inherit (nixosTests) nitter; };
    updateScript = unstableGitUpdater { };
  };

  meta = {
    homepage = "https://github.com/zedeus/nitter";
    description = "Alternative Twitter front-end";
    license = lib.licenses.agpl3Only;
    maintainers = with lib.maintainers; [
      erdnaxe
      infinidoge
    ];
    mainProgram = "nitter";
  };
})
