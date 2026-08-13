# Host "patch" on Debian Trixie+ rejects embedded NULs in CVE-2020-12723.patch
# (binary regex fixtures). PATCHTOOL=git needs a repo in ${S}; initialize one
# after unpack so git-apply can process those patches.
# Note: do_unpack is a Python task — use a shell postfunc, not do_unpack_append.
PATCHTOOL = "git"
do_unpack[postfuncs] += "perl_git_init_for_patchtool"
perl_git_init_for_patchtool() {
    if [ ! -d ${S}/.git ]; then
        (
            cd ${S}
            git init -q
            git config user.email "builder@openxt.local"
            git config user.name "OpenXT Builder"
            git add -A
            git commit -q --allow-empty -m "bitbake unpack base" || \
                git commit -q -m "bitbake unpack base"
        )
    fi
}

# Host configure probes under GCC 14 leave xconfig.h without many POSIX
# features that exist on Linux. Host miniperl is built from xconfig.h; without
# the directory/symlink defines, compile fails (opendir) or installperl dies
# with "The symlink function is unimplemented".
#
# Only force the filesystem ops needed for miniperl build + installperl.
# Enabling broader HAS_* (e.g. waitpid/sem) from target config.h breaks the
# host link (undefined PL_pidstatus).
do_configure_append() {
    python3 - <<'PY'
import pathlib, re
names = (
    "HAS_READDIR", "HAS_SEEKDIR", "HAS_TELLDIR", "HAS_REWINDDIR",
    "HAS_CLOSEDIR", "I_DIRENT",
    "HAS_SYMLINK", "HAS_LINK", "HAS_LSTAT", "HAS_READLINK",
    "HAS_STAT", "HAS_RENAME", "HAS_MKDIR", "HAS_RMDIR",
    "HAS_CHMOD", "HAS_FCHMOD", "HAS_TRUNCATE", "HAS_UMASK",
)
# Commented-out form from config_h.SH: /*#define NAME/ **/
pat = re.compile(
    r"/\*#define\s+(" + "|".join(names) + r")\s*/\s*\*\*/"
)
for path in pathlib.Path("${S}").glob("xconfig.h"):
    text = path.read_text()
    new = pat.sub(r"#define \1/**/", text)
    path.write_text(new)
    print(f"patched {path}: {text != new}")
    for sym in ("HAS_SYMLINK", "HAS_LINK", "HAS_READDIR", "HAS_LSTAT"):
        ok = bool(re.search(rf"(?m)^#define\s+{sym}\s*/\*\*/", new))
        print(f"  {sym}: {'ON' if ok else 'OFF'}")
PY
    if [ -f ${S}/Makefile.config ]; then
        sed -i "s|^HOSTCFLAGS = \(.*\)|HOSTCFLAGS = ${BUILD_CFLAGS} \1|" ${S}/Makefile.config || true
    fi
}
