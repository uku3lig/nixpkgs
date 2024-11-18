{
  lib,
  stdenv,
  fetchFromGitLab,
  atkmm,
  babl,
  cairo,
  fontconfig,
  freetype,
  gdk-pixbuf,
  gegl,
  glib-networking,
  exiv2,
  gexiv2,
  gobject-introspection,
  gtk3,
  lcms,
  libmypaint,
  librsvg,
  meson,
  mypaint-brushes1,
  ninja,
  pkg-config,
}:
stdenv.mkDerivation (finalAttrs: {
  pname = "gimp_3";
  version = "3.0.0-RC1";

  src = fetchFromGitLab {
    domain = "gitlab.gnome.org";
    owner = "GNOME";
    repo = "gimp";
    rev = "refs/tags/GIMP_3_0_0_RC1";
    hash = "sha256-UMiQuhIFsdmjsgu30WwINsFCr9lqAAj9/H/BAVPx4tc=";
  };

  nativeBuildInputs = [
    gobject-introspection
    meson
    ninja
    pkg-config
  ];

  buildInputs = [
    atkmm
    babl
    cairo
    fontconfig
    freetype
    gdk-pixbuf
    gegl
    glib-networking
    exiv2
    gexiv2
    gtk3
    lcms
    libmypaint
    librsvg
    mypaint-brushes1
  ];
})
