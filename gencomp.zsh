#!/usr/bin/env zsh

'emulate' '-L' 'zsh'

zmodload zsh/zutil

GENCOMP_HOME=${0:h:A}
: ${GENCOMP_DIR:-$GENCOMP_HOME/completions}

fpath+=($GENCOMP_DIR)

gencomp() {
    'emulate' '-L' 'zsh'

    mkdir -p $GENCOMP_DIR

    local name=$1 man cmd force
    shift 2>/dev/null
    zparseopts -man=man -cmd:=cmd f=force

    if [[ -f $name ]]; then
        gencomp-from-manpage $name $force || return 1
    elif [[ -n $man ]]; then
        gencomp-from-manpage "$(man --path $name)" $force || return 1
    elif (( $+commands[$name] )); then
        gencomp-from-help $name "$cmd[2]" "$force" || return 1
    else
        echo "Usage: $0 command [--man] [--cmd HELP_COMMAND] [-f]"
        echo "       $0 manfile [-f]"
        return
    fi
    echo 'Finished!'
    if (( $+functions[compdef] )); then
        autoload -Uz _$name
        compdef _$name $name
    fi
}

gencomp-from-help() {
    local help=${2:---help}
    local base=$GENCOMP_HOME/lib/zsh-completion-generator

    echo "Generating completion from \`$1 $help\`"
    if [[ -e $GENCOMP_DIR/_$1 && $3 != "-f" ]]; then
        print -P "%F{yellow}$GENCOMP_DIR/_$1 exists%f"
        return 1
    else
        $1 ${(z)help} 2>&1 | python $base/help2comp.py $1 >! $GENCOMP_DIR/_$1
    fi
}

gencomp-from-manpage() {
    local file=$1
    local name=${1:t:r:r}
    [[ -f $file && -n $name ]] || return 1

    local base=$GENCOMP_HOME/lib/sh-manpage-completions
    mkdir -p $base/completions/{fish,zsh}

    echo "Generating fish completion..."
    python $base/fish-tools/create_manpage_completions.py $file -s >! $base/completions/fish/$name.fish

    echo "Building scanner..."
    make --directory $base >/dev/null || return 1

    echo "Running scanner..."
    pushd $base > /dev/null
    $base/scanner < $base/completions/fish/$name.fish > /dev/null
    popd > /dev/null
    local scanner_output=$base/zsh-converter.out

    echo "Generating zsh completion..."
    local completions=""

    for line in ${(f)"$(<$scanner_output)"}; do
        completions+=$'\t\t'$line$' \\\n'
    done
    completions=$completions[0,-4]

    local template=$(<$base/templates/zsh)
    template=${template//COMMAND/$name}
    template=${template//ARGUMENTS/$completions}

    if [[ -e $GENCOMP_DIR/_$name && $2 != "-f" ]]; then
        print -P "%F{yellow}$GENCOMP_DIR/_$name exists%f"
        return 1
    else
        print -r - $template >! $GENCOMP_DIR/_$name
    fi
}
