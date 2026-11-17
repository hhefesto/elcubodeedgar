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
      fs = nixpkgs.lib.fileset;
      # what the solver's tables are made from (so the page's files can
      # change without building the tables again)
      tableFiles = [
        ./Cube.bend
        ./Coord.bend
        ./Search.bend
        ./Par.bend
        ./Solve.bend
        ./Sym.bend
        ./Kc.bend
        ./Build.bend
      ];
      tablesSrc = fs.toSource {
        root = ./.;
        fileset = fs.unions tableFiles;
      };
      # what the device's downloaded tables are made from (DevTables.bend)
      devTableFiles = [
        ./Cube.bend
        ./Coord.bend
        ./Search.bend
        ./Par.bend
        ./Solve.bend
        ./Sym.bend
        ./Lite.bend
        ./DevTables.bend
        ./Kd.bend
        ./FstTables.bend
      ];
      devTablesSrc = fs.toSource {
        root = ./.;
        fileset = fs.unions devTableFiles;
      };
      src = fs.toSource {
        root = ./.;
        fileset = fs.unions (
          tableFiles
          ++ devTableFiles
          ++ [
            ./Guard.bend
            ./Dev.bend
            ./web/Sched.bend
            ./web/solver.js
            ./web/solver-worker.js
            ./web/ways-worker.js
            ./Ways.bend
            ./web/own.js
            ./web/colors.js
            ./Photo.bend
            ./Scheme.bend
            ./Opt.bend
            ./Fast.bend
            ./TwoPhase.bend
            ./Worker.bend
            ./Server.bend
            ./Group.bend
            ./LAWS.bend
            ./PROOF.bend
            ./FIT.bend
            ./ALGS.bend
            ./web/App.bend
            ./web/index.html
            ./web/cube3d.js
            ./web/geom.js
            ./probe/Facelets.bend
            ./probe/turns.mjs
          ]
        );
      };
      # three.js r170, its one-file build, from npm
      threeFor =
        pkgs:
        pkgs.fetchurl {
          url = "https://registry.npmjs.org/three/-/three-0.170.0.tgz";
          hash = "sha256-SmCKNV3KunLg5Tg83IFDA/W2BgtDwjjN9pMtzraZI40=";
        };
      # run `script` in a writable copy of the source s, bend-frp beside it
      # (web/App.bend imports ../bend-frp/Web.bend) and bend on PATH
      inSourceOf =
        s: pkgs: name: inputs: script:
        pkgs.runCommandCC "elcubodeedgar-${name}"
          { nativeBuildInputs = [ bend-frp.packages.${pkgs.stdenv.hostPlatform.system}.bend ] ++ inputs; }
          ''
            export HOME=$TMPDIR BEND_NO_TELEMETRY=1
            cp -r ${s} w
            chmod -R u+w w
            cd w
            cp -r ${bend-frp} bend-frp
            chmod -R u+w bend-frp
            ${script}
          '';
      inSource = inSourceOf src;
    in
    {
      packages = each (
        system: pkgs: rec {
          # the web server: the page's files, and the way to the solver
          # (Server.bend)
          server = inSource pkgs "server" [ ] ''
            bend Server.bend -o cube-server
            install -Dm755 cube-server $out/bin/cube-server
          '';
          # the solver, a process of its own (Worker.bend)
          solver-bin = inSource pkgs "solver-bin" [ ] ''
            bend Worker.bend -o cube-solver
            install -Dm755 cube-solver $out/bin/cube-solver
          '';
          # the solver's tables (Build.bend): the corners' exact distances and
          # the flip, slice and twist ones by symmetry class; 3.6 GB, about 25
          # minutes on 8 cores and 5 GB of memory
          tables = inSourceOf tablesSrc pkgs "tables" [ ] ''
            bend Build.bend -o build-tables
            mkdir -p $out
            ./build-tables $out/tables.bin | tee $out/build.log
            test -s $out/tables.bin
          '';
          # the device's downloaded tables (DevTables.bend, FstTables.bend):
          # distance tables and Lite.bend's two-phase ones, brotli and gzip,
          # named by their contents (so a browser keeps them for good), and
          # tables.json, which says where each goes in the device's array
          dev-tables = inSourceOf devTablesSrc pkgs "dev-tables" [ pkgs.brotli pkgs.gzip ] ''
            bend DevTables.bend -o dev-tables
            ./dev-tables korf.bin lite.bin | tee build.log
            bend FstTables.bend -o fst-tables
            ./fst-tables fst.bin | tee -a build.log
            mkdir -p $out/t
            for f in korf fst lite; do
              h=$(sha256sum $f.bin | cut -c1-16)
              brotli -q 11 -w 24 -c $f.bin > $out/t/$f-$h.bin.br &
              gzip -9 -n -c $f.bin > $out/t/$f-$h.bin.gz &
              echo "$f $h $(stat -c %s $f.bin)" >> names
            done
            wait
            read -r _ kh ks < <(grep '^korf ' names)
            read -r _ lh ls < <(grep '^lite ' names)
            read -r _ fh fs < <(grep '^fst ' names)
            # where each goes: Dev.bend's array (dv.len words), korf (the
            # corners' distances) at Kd.bend's kd.PC, fst at kd.P, lite from
            # Lite.bend's lt.FM on
            cat > $out/tables.json <<JSON
            {"words": 39517680,
             "korf": {"at": 1048576, "words": $((ks / 4)), "br": "t/korf-$kh.bin.br", "gz": "t/korf-$kh.bin.gz"},
             "fst": {"at": 12071056, "words": $((fs / 4)), "br": "t/fst-$fh.bin.br", "gz": "t/fst-$fh.bin.gz"},
             "lite": {"at": 35000000, "words": $((ls / 4)), "br": "t/lite-$lh.bin.br", "gz": "t/lite-$lh.bin.gz"}}
            JSON
            cp build.log $out/
          '';
          # the page, bundled: index.html, App.bend and bend-frp compiled to
          # JavaScript, cube3d.js, three.js, the solver's thin JS and
          # Sched.bend; beside it, as they are, what the device's Web Workers
          # load (solver-worker.js, Dev.bend compiled), and the tables
          www = inSource pkgs "www" [ pkgs.gnutar pkgs.gzip ] ''
            tar xzf ${threeFor pkgs} -O package/build/three.module.min.js > web/three.module.min.js
            bend web/Sched.bend -o web/sched.mjs
            bend web/index.html -o $out
            bend Dev.bend -o $out/dev.mjs
            bend Scheme.bend -o $out/scheme.mjs
            bend Ways.bend -o $out/ways.mjs
            cp web/solver-worker.js web/solver.js web/own.js web/sched.mjs web/ways-worker.js $out/
            cp -r ${dev-tables}/t ${dev-tables}/tables.json $out/
          '';
          # `elcubodeedgar [PORT]` serves the page on 127.0.0.1:PORT (8093)
          default = pkgs.writeShellApplication {
            name = "elcubodeedgar";
            text = ''
              exec ${server}/bin/cube-server ${www} "''${1:-8093}"
            '';
          };
          # `elcubodeedgar-solver [PORT]` solves on 127.0.0.1:PORT (8095)
          solver = pkgs.writeShellApplication {
            name = "elcubodeedgar-solver";
            text = ''
              exec ${solver-bin}/bin/cube-solver "''${1:-8095}" ${tables}/tables.bin
            '';
          };
          # restarts the server or the solver if its /health does not answer
          # twice, 5 s apart (a systemd timer runs it); a unit is left alone
          # while it is not active (systemd restarts those) and for 2 minutes
          # after it starts (the solver reads its tables first, about 40 s)
          watchdog = pkgs.writeShellApplication {
            name = "elcubodeedgar-watchdog";
            runtimeInputs = [ pkgs.curl pkgs.coreutils ];
            text = ''
              systemctl=/run/current-system/sw/bin/systemctl
              for unit in elcubodeedgar:8093 elcubodeedgar-solver:8095; do
                name=''${unit%%:*} port=''${unit##*:}
                $systemctl --user is-active --quiet "$name.service" || continue
                since=$(date -d "$($systemctl --user show "$name.service" -p ActiveEnterTimestamp --value)" +%s)
                [ $(($(date +%s) - since)) -ge 120 ] || continue
                if ! curl -fs -m 10 -o /dev/null "http://127.0.0.1:$port/health"; then
                  sleep 5
                  if ! curl -fs -m 10 -o /dev/null "http://127.0.0.1:$port/health"; then
                    echo "$name did not answer /health twice: restarting it"
                    $systemctl --user restart "$name.service"
                  fi
                fi
              done
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
          # the color-scheme laws of the camera (FIT.bend): Bend's checker
          # only, as BendTT's kernel runs out of fuel on them
          fit = inSource pkgs "fit" [ ] ''
            bend FIT.bend --check-only 2>&1 | tee $out
            grep -q 'ALL PROOFS CHECK' $out
          '';
          # the laws of "Solve it your way" (ALGS.bend): Bend's checker only,
          # as BendTT's kernel runs out of fuel on them too
          algs = inSource pkgs "algs" [ ] ''
            bend ALGS.bend --check-only 2>&1 | tee $out
            grep -q 'ALL PROOFS CHECK' $out
          '';
          # the modules check (the servers and the table builder lean on IO
          # loops and shared arrays, @unsafe, so they are built, not checked:
          # packages.server, solver-bin, tables)
          modules = inSource pkgs "modules" [ ] ''
            for f in Cube.bend Coord.bend Search.bend Par.bend Solve.bend Sym.bend Kc.bend Opt.bend TwoPhase.bend Group.bend Guard.bend Lite.bend Kd.bend Scheme.bend Photo.bend Dev.bend Ways.bend web/Sched.bend web/App.bend; do
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
          inherit (self.packages.${system}) server www solver-bin;
        }
      );
    };
}
