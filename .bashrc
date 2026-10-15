[[ "$-" != *i* ]] && return

export EDITOR='nvim'
export PATH="/c/Program Files/Microsoft MPI/Bin:$PATH"
export PATH="$PATH:/c/Users/$USER/.local/bin"

export PS1='\u@\h:\[\e[33m\]\w\[\e[0m\]\$ '


export HISTCONTROL=ignoreboth     
shopt -s histappend               

alias ls='ls --color=auto'
alias ll='ls -lh'
alias la='ls -A'
alias grep='grep --color=auto'


#   cmc [Debug|Release]    configure (default: Debug)
#   cmb [target]           build everything, or just one target
#   cmr [target] [args]    build, then run the executable
#   cmt                    build, then run tests (ctest)
#   cmf [Debug|Release]    fresh: delete build/ and reconfigure
#   cmrel                  shortcut for a fresh Release build

CM_BUILD_DIR=build

_cm_win() {
    [[ $PWD == /mnt/* ]]
}

cmc() {
    _cm_win && { ucrt cmc "$@"; return; }
    cmake -S . -B "$CM_BUILD_DIR" -G Ninja \
        -DCMAKE_BUILD_TYPE="${1:-Debug}" \
        -DCMAKE_EXPORT_COMPILE_COMMANDS=ON   
}

cmb() {
    _cm_win && { ucrt cmb "$@"; return; }
    [[ -d "$CM_BUILD_DIR" ]] || cmc || return
    cmake --build "$CM_BUILD_DIR" ${1:+--target "$1"}
}

cmr() {
    _cm_win && { ucrt cmr "$@"; return; }
    local target="$1"
    shift 2>/dev/null
    cmb "$target" || return

    if [[ -z "$target" ]]; then
        local exes=("$CM_BUILD_DIR"/*.exe)
        if [[ ${#exes[@]} -ne 1 || ! -f "${exes[0]}" ]]; then
            echo "cmr: specify which to run: cmr <target>"
            ls "$CM_BUILD_DIR"/*.exe 2>/dev/null
            return 1
        fi
        target=$(basename "${exes[0]}" .exe)
    fi

    "./$CM_BUILD_DIR/$target.exe" "$@"
}

cmt() {
    _cm_win && { ucrt cmt "$@"; return; }
    cmb && ctest --test-dir "$CM_BUILD_DIR" --output-on-failure
}

cmf() {
    _cm_win && { ucrt cmf "$@"; return; }
    rm -rf "$CM_BUILD_DIR" && cmc "$@"
}

cmrel() {
    _cm_win && { ucrt cmrel "$@"; return; }
    cmf Release && cmb
}
export PATH="$HOME/.local/bin:$PATH"

ucrt() {
    local helpers
    helpers="CM_BUILD_DIR=${CM_BUILD_DIR@Q}
$(declare -f _cm_win cmc cmb cmr cmt cmf cmrel)"
    /mnt/c/msys64/usr/bin/env.exe MSYSTEM=UCRT64 CHERE_INVOKING=1 \
        /usr/bin/bash -lc "$helpers
$*"
}
