#!/usr/bin/env zsh

GENCOMP_HOME=${0:h}
: ${GENCOMP_DIR:-$GENCOMP_HOME/completions}

fpath+=($GENCOMP_DIR)

gencomp() {
    mkdir -p $GENCOMP_DIR

    if [[ -f $1 && $1 == *man/man1/*.gz ]]; then
        gencomp-from-manpage $1 || return 1
    elif [[ $2 == '--man' ]]; then
        gencomp-from-manpage /usr/share/man/man1/$1.1.gz || return 1
    elif (( $+commands[$1] )); then
        gencomp-from-help $1 $2 || return 1
    else
        print 'Usage: $0 command [--man|HELP_COMMAND]'
        print '       $0 manfile'
    fi
    print 'Finished!'
    if (( $+functions[compdef] )); then
        autoload -Uz _$1
        compdef _$1 $1
    fi
}

gencomp-from-help() {
    local help=${2:---help}
    local base=$GENCOMP_HOME/lib/zsh-completion-generator

    echo "Generating completion from \`$1 $help\`"
    $1 $help 2>&1 | python $base/help2comp.py $1 >! $GENCOMP_DIR/_$1
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
    $base/scanner < $base/completions/fish/$name.fish > /dev/null
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

    print -r - $template >! $GENCOMP_DIR/_$name
}
