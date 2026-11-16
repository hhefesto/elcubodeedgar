{
  description = "El cubo de Edgar, a Rubik's cube: an optimal solver in Bend, its laws, and a bend-frp page with a three.js cube";

  # bend-frp brings the pinned Bend (2.0.39, with BendTT for --verdict) and
  # the web layer the page is written in
  inputs.bend-frp.url = "github:hhefesto/bend-frp";
  inputs.nixpkgs.follows = "bend-frp/nixpkgs";

  outputs =
    { self, nixpkgs, bend-frp }:
    let
      systems = [ "x86_64-linux" ];
      each = f: nixpkgs.lib.genAttrs systems (system: f system nixpkgs.legacyPackages.${system});
      src = nixpkgs.lib.fileset.toSource {
        root = ./.;
        fileset = nixpkgs.lib.fileset.unions [
          ./Cube.bend
          ./Coord.bend
          ./Search.bend
          ./Par.bend
          ./Solve.bend
          ./Server.bend
          ./Group.bend
          ./LAWS.bend
          ./PROOF.bend
          ./web/App.bend
          ./web/index.html
          ./web/cube3d.js
          ./web/geom.js
          ./probe/Facelets.bend
          ./probe/turns.mjs
        ];
      };
      # three.js r170, its one-file build, from npm
      threeFor =
        pkgs:
        pkgs.fetchurl {
          url = "https://registry.npmjs.org/three/-/three-0.170.0.tgz";
          hash = "sha256-SmCKNV3KunLg5Tg83IFDA/W2BgtDwjjN9pMtzraZI40=";
        };
      # run `script` in a writable copy of the source, bend-frp beside it
      # (web/App.bend imports ../bend-frp/Web.bend) and bend on PATH
      inSource =
        pkgs: name: inputs: script:
        pkgs.runCommandCC "elcubodeedgar-${name}"
          { nativeBuildInputs = [ bend-frp.packages.${pkgs.stdenv.hostPlatform.system}.bend ] ++ inputs; }
          ''
            export HOME=$TMPDIR BEND_NO_TELEMETRY=1
            cp -r ${src} w
            chmod -R u+w w
            cd w
            cp -r ${bend-frp} bend-frp
            chmod -R u+w bend-frp
            ${script}
          '';
    in
    {
      packages = each (
        system: pkgs: rec {
          # the server: the tables, the solver, the page's files (Server.bend)
          server = inSource pkgs "server" [ ] ''
            bend Server.bend -o cube-server
            install -Dm755 cube-server $out/bin/cube-server
          '';
          # the page, bundled: index.html, App.bend and bend-frp compiled to
          # JavaScript, cube3d.js, three.js
          www = inSource pkgs "www" [ pkgs.gnutar pkgs.gzip ] ''
            tar xzf ${threeFor pkgs} -O package/build/three.module.min.js > web/three.module.min.js
            bend web/index.html -o $out
          '';
          # both: `elcubodeedgar [PORT]` serves the page and the solver on
          # 127.0.0.1:PORT (8093)
          default = pkgs.writeShellApplication {
            name = "elcubodeedgar";
            text = ''
              exec ${server}/bin/cube-server ${www} "''${1:-8093}"
            '';
          };
        }
      );

      checks = each (
        system: pkgs: {
          # the laws hold: Bend's checker, then BendTT's kernel
          proofs = inSource pkgs "proofs" [ ] ''
            bend PROOF.bend --verdict 2>&1 | tee $out
            grep -q 'ALL PROOFS CHECK' $out
          '';
          # the page's code checks (the server's leans on its accept loop,
          # @unsafe, so it is built, not checked: packages.server)
          modules = inSource pkgs "modules" [ ] ''
            for f in Cube.bend Coord.bend Search.bend Par.bend Solve.bend Group.bend web/App.bend; do
              echo "== $f"
              bend $f --check-only 2>&1 | tee log
              grep -q 'ALL PROOFS CHECK' log
              cat log >> $out
            done
          '';
          # the 3D view turns stickers as Cube.bend does, for every move
          turns = inSource pkgs "turns" [ pkgs.nodejs ] ''
            bend probe/Facelets.bend > facelets.txt
            node probe/turns.mjs < facelets.txt | tee $out
          '';
          inherit (self.packages.${system}) server www;
        }
      );
    };
}
