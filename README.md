# collon.zsh

![Screenshot](https://user-images.githubusercontent.com/546312/66715009-08b17d00-edf9-11e9-992f-0539c9c650fc.png)

Lightweight ZSH theme.

## Install

Clone the repository and add the path to `fpath`.

```
git clone https://github.com/lambdalisue/collon.zsh ~/.collon

echo "fpath+=(~/.collon)"
```

## Usage

Enable `promptinit` first.

```
autoload -U promptinit; promptinit
```

Then select `collon`.

```
prompt collon
```
