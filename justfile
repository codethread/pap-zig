set positional-arguments

default:
    @just --list

# Private helper - handles --clean flag for any zig build command
# Pass --clean to any recipe to run `just clean` first, e.g. `just check --clean`
_zig cmd *args:
    #!/usr/bin/env sh
    shift  # skip cmd, leaving just args in $@
    if echo "$@" | grep -q -- "--clean"; then
        just clean
    fi
    zig build {{ cmd }} --summary all $(echo "$@" | sed 's/--clean//g')


all *args:
    #!/usr/bin/env sh
    just check "$@" && just test "$@" && just run "$@"

test *args:
    @printf '\033[1;36m━━━ Running Tests ━━━\033[0m\n\n'
    @just _zig test "$@"

run *args:
    @printf '\033[1;32m━━━ Running Pap ━━━\033[0m\n\n'
    @just _zig run "$@"

check *args:
    @printf '\033[1;33m━━━ Running Checks ━━━\033[0m\n\n'
    @just _zig check "$@"

clean:
    @printf '\033[1;31m━━━ Cleaning cache... ━━━\033[0m\n\n'
    @rm -rf .zig-cache
    @rm -rf zig-out

help:
    zig build --help
