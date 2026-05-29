########################
# Locale
########################
export LANG=en_US.UTF-8
export LC_ALL=en_US.UTF-8

ZSH_DISABLE_COMPFIX=true

########################
# zsh起動時にtmuxも自動起動
########################
[[ -z "$TMUX" && ! -z "$PS1" && -t 0 ]] && { tmux a || tmux new-session; exit }

########################
# Powerlevel10kにより自動生成
########################
# Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.zshrc.
# Initialization code that may require console input (password prompts, [y/n]
# confirmations, etc.) must go above this block; everything else may go below.
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
    source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

########################
# alias
########################
alias ll='ls -alF --time-style="+%Y/%m/%d %H:%M:%S"'
alias gitg='git log --graph --oneline --decorate=full --date=short --format="%C(yellow)%h%C(reset) %C(magenta)[%ad]%C(reset)%C(auto)%d%C(reset) %s %C(cyan)@%an%C(reset)" $args'
alias sail='[ -f sail  ] && sh sail || sh vendor/bin/sail'
# サーバー一覧は`speedtest -L`で表示できる。詳しくは`speedtest -h`で。
# alias speedtest='speedtest -s 48463'
alias pbcopy='xsel --clipboard --input'
alias here='open .'
alias py='python3'
alias python='python3'

# フォルダサイズを取得
function sz(){
    if [ $# -eq 0 ]; then
        du -shx . *(D)
    else
        du -shx $1
    fi
}

# mkdir -p && touch (途中のフォルダがなければ生成)
tp() {
  mkdir -p "$(dirname "$1")" && touch "$1"
}

########################
# PATH
########################
export PATH=$HOME/.local/bin:$PATH
export PATH=$HOME/Downloads/nvim-linux64/bin:$PATH
export PATH=$PATH:/usr/local/go/bin
export PATH=$PATH:$HOME/go/bin
export PATH=$PATH:/usr/bin/python3

########################
# cd移動時に自動でllする
########################
chpwd() {
    if [[ $(pwd) != $HOME && $(pwd) != /mnt/c/Users/shimoda ]]; then
        ll
    fi
}

# cdを省略
setopt auto_cd

########################
# 履歴設定（tmux全paneで共有）
########################
HISTFILE=$HOME/.zsh_history
HISTSIZE=100000
SAVEHIST=100000
setopt SHARE_HISTORY       # 全paneでリアルタイム共有
setopt HIST_IGNORE_DUPS    # 連続重複コマンドを保存しない
setopt HIST_REDUCE_BLANKS  # 余分なスペースを除去して保存

########################
# nvmインストール時に自動で追加されたもの（遅延ロードに変更）
########################
export NVM_DIR="$HOME/.nvm"
# デフォルトnodeのbinをPATHに追加（claudeなどグローバルnpmパッケージを即時使えるようにする）
() {
    local version="$NVM_DIR/alias/default"
    [[ -f "$version" ]] && version=$(cat "$version")
    while [[ -n "$version" && -f "$NVM_DIR/alias/$version" ]]; do
        version=$(cat "$NVM_DIR/alias/$version")
    done
    [[ -n "$version" && -d "$NVM_DIR/versions/node/$version/bin" ]] && \
        export PATH="$NVM_DIR/versions/node/$version/bin:$PATH"
}
nvm() {
    unset -f nvm node npm npx
    [ -s "$NVM_DIR/nvm.sh" ] && source "$NVM_DIR/nvm.sh"
    [ -s "$NVM_DIR/bash_completion" ] && source "$NVM_DIR/bash_completion"
    nvm "$@"
}
node() { nvm; node "$@"; }
npm()  { nvm; npm  "$@"; }
npx()  { nvm; npx  "$@"; }

########################
# Added by Zinit's installer (Zinitインストールで自動追加されたもの)
########################
if [[ ! -f $HOME/.local/share/zinit/zinit.git/zinit.zsh ]]; then
    print -P "%F{33} %F{220}Installing %F{33}ZDHARMA-CONTINUUM%F{220} Initiative Plugin Manager (%F{33}zdharma-continuum/zinit%F{220})…%f"
    command mkdir -p "$HOME/.local/share/zinit" && command chmod g-rwX "$HOME/.local/share/zinit"
    command git clone https://github.com/zdharma-continuum/zinit "$HOME/.local/share/zinit/zinit.git" && \
        print -P "%F{33} %F{34}Installation successful.%f%b" || \
        print -P "%F{160} The clone has failed.%f%b"
fi

source "$HOME/.local/share/zinit/zinit.git/zinit.zsh"
autoload -Uz _zinit
(( ${+_comps} )) && _comps[zinit]=_zinit
ZINIT[COMPINIT_OPTS]=-u

# Load a few important annexes, without Turbo
# (this is currently required for annexes)
zinit light-mode for \
    zdharma-continuum/zinit-annex-as-monitor \
    zdharma-continuum/zinit-annex-bin-gem-node \
    zdharma-continuum/zinit-annex-patch-dl \
    zdharma-continuum/zinit-annex-rust

### End of Zinit's installer chunk

##############
# Load Plugins
##############
### Load pure theme
# zinit ice pick"async.zsh" src"pure.zsh" # with zsh-async library thats bundled with it.
# zinit light sindresorhus/pure
# zstyle :prompt:pure:git:stash show yes # turn on git stash status

zinit ice wait'!0'; zinit load zsh-users/zsh-syntax-highlighting # 実行可能なコマンドに色付け
zinit ice wait'!0'; zinit load zsh-users/zsh-completions # 補完
zinit ice wait'!0'; zinit load chrissicool/zsh-256color # 256色使えるようにする
zinit ice wait'!0'; zinit load zsh-users/zsh-autosuggestions # 過去の入力履歴を検索しサジェストを表示
zinit ice depth=1; zinit light romkatv/powerlevel10k # theme編集ソフト
zinit ice wait'!0'; zinit light Aloxaf/fzf-tab # 補完選択メニューをfzfに置き換え

##########
# autoload
##########
### 補完（24時間ごとにのみフル再生成、それ以外はキャッシュ使用）
autoload -Uz compinit
if [[ -n ~/.zcompdump(#qN.mh+24) ]]; then
    compinit
else
    compinit -C
fi
zinit cdreplay -q
zstyle ':completion:*:default' menu select=1 # 補完候補を一覧表示したとき、Tabや矢印で選択できるようにする
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Z}' # 小文字でも大文字ディレクトリ、ファイルを補完できるようにする

#######
# fzf
#######
# source /usr/share/doc/fzf/examples/key-bindings.zsh # Ctrl+tショートカットを使えるようにする設定だけどもう不要っぽい
# export FZF_CTRL_T_COMMAND='rg --files --hidden --follow --glob "!.git/*"' # --followはシンボリックを含める
export FZF_CTRL_T_COMMAND='rg --files --hidden --glob "!.git/*"'
export FZF_CTRL_T_OPTS='--preview "bat  --color=always --style=header,grid --line-range :100 {}"'

########################
# Powerlevel10kにより自動生成
########################
# To customize prompt, run `p10k configure` or edit ~/.p10k.zsh.
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh

[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh
