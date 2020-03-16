# gencomp

Generate zsh completion functions from [manpage](https://github.com/nevesnunes/sh-manpage-completions) or [`--help`](https://github.com/RobSis/zsh-completion-generator).

# Install

**Manual**

First, clone this repository

```zsh
git clone https://github.com/Aloxaf/gencomp ~/somewhere
```

Then add the following line to your `~/.zshrc`

```zsh
source ~/somewhere/gencomp.plugin.zsh
```

**Antigen**

```zsh
antigen bundle Aloxaf/gencomp
```

**Zinit**

```zsh
zinit light Aloxaf/gencomp
```

**Oh-My-Zsh**

Clone this repository to your custom directory and then add `gencomp` to your plugin list.

```zsh
git clone https://github.com/Aloxaf/gencomp ~ZSH_CUSTOM/plugins/gencomp
```

# Usage

**From manpage**
```zsh
gencomp fzf --man
gencomp /usr/share/man/man1/rlwrap.1.gz
```

**From `--help`**
```zsh
gencomp bat
```

# Related project

- https://github.com/nevesnunes/sh-manpage-completions
- https://github.com/RobSis/zsh-completion-generator
