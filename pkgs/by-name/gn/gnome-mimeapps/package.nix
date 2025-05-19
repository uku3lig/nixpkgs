{
  stdenvNoCC,
  fetchFromGitLab,
  meson,
  ninja,
  python313,
  baobab,
  decibels,
  epiphany,
  evince,
  evolution,
  file-roller,
  gnome-boxes,
  gnome-builder,
  gnome-calendar,
  gnome-color-manager,
  gnome-connections,
  gnome-font-viewer,
  gnome-maps,
  gnome-notes,
  gnome-software,
  gnome-text-editor,
  gthumb,
  loupe,
  meld,
  nautilus,
  papers,
  seahorse,
  sysprof,
  totem,
  yelp,
}:
stdenvNoCC.mkDerivation (finalAttrs: {
  pname = "gnome-mimeapps";
  version = "0.1";

  src = fetchFromGitLab {
    domain = "gitlab.gnome.org";
    owner = "heftig";
    repo = "gnome-mimeapps";
    tag = finalAttrs.version;
    hash = "sha256-NbhQPA2TQQROxOCzZinUMbNlGDZPhtIhSu6CsTdVqKI=";
  };

  nativeBuildInputs = [
    meson
    ninja
    python313

    baobab
    decibels
    epiphany
    evince
    evolution
    file-roller
    gnome-boxes
    gnome-builder
    gnome-calendar
    gnome-color-manager
    gnome-connections
    gnome-font-viewer
    gnome-maps
    gnome-notes
    gnome-software
    gnome-text-editor
    gthumb
    loupe
    meld
    nautilus
    papers
    seahorse
    sysprof
    totem
    yelp
  ];

  postPatch = "env";
})
