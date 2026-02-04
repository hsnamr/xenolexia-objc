# Scripts

## install-smallstep.sh

Builds **SmallStep** as a static library and installs headers and the library into `xenolexia-objc/include` and `xenolexia-objc/lib` so that xenolexia-objc links SmallStep as a prebuilt library instead of compiling SmallStep sources.

**Usage** (from xenolexia-objc root):

```bash
./scripts/install-smallstep.sh [path-to-SmallStep-repo]
```

- If no path is given, uses `SMALLSTEP_SRC` env or `../SmallStep`.
- Requires GNUStep environment (e.g. `source /usr/share/GNUstep/Makefiles/GNUstep.sh`).
- SmallStep is built with `make -f Makefile.install` in the SmallStep repo; that Makefile produces `libSmallStep.a` and installs headers to `DESTDIR/include` and the lib to `DESTDIR/lib`.

**Note:** Building SmallStep with `Makefile.install` may require a compiler that supports `nullable` and `weak` (e.g. clang). If the build fails on those attributes, build SmallStep with clang or adjust SmallStep headers for your toolchain.
