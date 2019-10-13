#
# collon
#
# zsh simple theme
# by Alisue <lambdalisue@hashnote.net>
#
if type timeout >/dev/null 2>&1; then
  collon::util::timeout() { timeout "$@" }
elif type gtimeout >/dev/null 2>&1; then
  collon::util::timeout() { gtimeout "$@" }
elif type perl >/dev/null 2>&1; then
  collon::util::timeout() { command perl -e 'alarm shift; exec @ARGV' "$@" }
else
  collon::util::timeout() { command "$@" }
fi

collon::util::git() {
  collon::util::timeout 1 command git "$@" 2>/dev/null
}

collon::util::is_git_worktree() {
  collon::util::git rev-parse --is-inside-work-tree >/dev/null 2>&1
}

collon::util::eliminate_empty_elements() {
  for element in ${1[@]}; do
    [[ -n "$element" ]]; echo -en $element
  done
}

collon::component() {
  local text="$1"
  local fcolor=$2
  local kcolor=$3
  if [ -n "$fcolor" -a -n "$kcolor" ]; then
    echo -n "%{%K{$kcolor}%F{$fcolor}%}$text%{%k%f%}"
  elif [ -n "$fcolor" ]; then
    echo -n "%{%F{$fcolor}%}$text%{%f%}"
  elif [ -n "$kolor" ]; then
    echo -n "%{%K{$kcolor}%}$text%{%k%}"
  else
    echo -n "$text"
  fi
}

collon::component::root() {
  local fcolor='white'
  local kcolor='red'
  # Show username only when the user is root
  if [ $(id -u) -eq 0 ]; then
    collon::component "%{%B%} %n %{%b%}" $fcolor $kcolor
  fi
}

collon::component::host() {
  local fcolor='67'
  # Show hostname only when user connect to a remote machine
  if [ -n "${REMOTEHOST}${SSH_CONNECTION}" ]; then
    collon::component "%m" $fcolor
  fi
}

collon::component::time() {
  local fcolor=245
  local date="%D{%H:%M:%S}"
  collon::component "$date" $fcolor
}

collon::component::symbol() {
  local fcolor_normal='blue'
  local fcolor_error='red'
  if [[ $1 > 0 ]]; then
    collon::component "%{%B%}:%{%b%}" $fcolor_error
  else
    collon::component "%{%B%}:%{%b%}" $fcolor_normal
  fi
}

collon::component::exitstatus() {
  local fcolor='red'
  if [[ $1 > 0 ]]; then
    collon::component "[!] $1" $fcolor $kcolor
  fi
}

collon::component::cwd() {
    local fcolor='blue'
    local lock='[x]'
    local PWD="$(pwd)"
    # current path state
    local pwd_state
    if [[ ! -O "$PWD" ]]; then
        if [[ -w "$PWD" ]]; then
            pwd_state="%{%F{blue}%}$lock "
        elif [[ -x "$PWD" ]]; then
            pwd_state="%{%F{yellow}%}$lock "
        elif [[ -r "$PWD" ]]; then
            pwd_state="%{%F{red}%}$lock "
        fi
    fi
    if [[ ! -w "$PWD" && ! -r "$PWD" ]]; then
        pwd_state="%{%F{red}%}$lock "
    fi
    local pwd_path="%50<...<%~"
    collon::component "%{%B%}$pwd_state$pwd_path%{%f%b%}" $fcolor
}

collon::component::vcs() {
    local fcolor_normal='green'
    local fcolor_error='red'
    vcs_info 'collon'

    local -a messages
    [[ ! "$vcs_info_msg_0_" =~ "^[ ]*$" ]] \
      && messages+=( $(collon::component "$vcs_info_msg_0_" $fcolor_normal ) )
    [[ ! "$vcs_info_msg_1_" =~ "^[ ]*$" ]] \
      && messages+=( $(collon::component " %{%B%}$vcs_info_msg_1_%{%b%}" ) )
    [[ ! "$vcs_info_msg_2_" =~ "^[ ]*$" ]] \
      && messages+=( $(collon::component " $vcs_info_msg_2_" $fcolor_error ) )
    echo -n "${(j: :)messages}"
}

collon::configure_vcsstyles() {
    autoload -Uz vcs_info 
    local branchfmt="%b%m"
    local actionfmt="%a%f"

    # $vcs_info_msg_0_ : Normal
    # $vcs_info_msg_1_ : Warning
    # $vcs_info_msg_2_ : Error
    zstyle ':vcs_info:*:collon:*' max-exports 3

    zstyle ':vcs_info:*:collon:*' enable git svn hg bzr
    zstyle ':vcs_info:*:collon:*' formats "%s$branchfmt"
    zstyle ':vcs_info:*:collon:*' actionformats "%s$branchfmt" '%m' '<!%a>'

    if is-at-least 4.3.10; then
        zstyle ':vcs_info:git:collon:*' formats "$branchfmt" '%m'
        zstyle ':vcs_info:git:collon:*' actionformats "$branchfmt" '%m' '<!%a>'
    fi

    if is-at-least 4.3.11; then
        zstyle ':vcs_info:git+set-message:collon:*' hooks \
            git-hook-begin \
            git-status \
            git-push-status \
            git-pull-status

        function +vi-git-hook-begin() {
            if ! collon::util::is_git_worktree; then
                # stop further hook functions
                return 1
            fi
            return 0
        }

        function +vi-git-status() {
            # do not handle except the 2nd message of zstyle formats, actionformats
            if [[ "$1" != "1" ]]; then
                return 0
            fi
            local gitstatus="$(collon::util::git status --ignore-submodules --porcelain)"
            if [[ $? == 0 ]]; then
                local staged="$(command echo $gitstatus | grep -E '^([MARC][ MD]|D[ M])' | wc -l | tr -d ' ')"
                local unstaged="$(command echo $gitstatus | grep -E '^([ MARC][MD]|DM)' | wc -l | tr -d ' ')"
                local untracked="$(command echo $gitstatus | grep -E '^\?\?' | wc -l | tr -d ' ')"
                #local indicator="•"
                local indicator=":"
                local -a messages
                [[ $staged > 0    ]] && messages+=( "%{%F{blue}%}$indicator%{%f%}" )
                [[ $unstaged > 0  ]] && messages+=( "%{%F{red}%}$indicator%{%f%}" )
                [[ $untracked > 0 ]] && messages+=( "%{%F{yellow}%}$indicator%{%f%}" )
                hook_com[misc]+="%{%B%}${(j::)messages}%{%b%}"
            fi
        }

        function +vi-git-push-status() {
            # do not handle except the 2nd message of zstyle formats, actionformats
            if [[ "$1" != "1" ]]; then
                return 0
            fi

            # get the number of commits ahead of remote
            local ahead
            ahead=$(collon::util::git log --oneline @{upstream}.. | wc -l | tr -d ' ')

            if [[ "$ahead" -gt 0 ]]; then
                #hook_com[misc]+="%{%B%F{green}%}⋀%{%b%f%}"
                hook_com[misc]+="%{%B%F{green}%}^%{%b%f%}"
            fi
        }

        function +vi-git-pull-status() {
            # do not handle except the 2nd message of zstyle formats, actionformats
            if [[ "$1" != "1" ]]; then
                return 0
            fi

            # get the number of commits behind remote
            local behind
            behind=$(collon::util::git log --oneline ..@{upstream} | wc -l | tr -d ' ')

            if [[ "$behind" -gt 0 ]]; then
                #hook_com[misc]+="%{%B%F{green}%}⋁%{%b%f%}"
                hook_com[misc]+="%{%B%F{green}%}v%{%b%f%}"
            fi
        }
    fi
}

collon::prompt_precmd() {
  local exitstatus=$?
  collon_prompt_1st_bits=(
    "$(collon::component::root)"
    "$(collon::component::host)"
    "$(collon::component::time)"
    "$(collon::component::exitstatus $exitstatus)"
    "$(collon::component::symbol $exitstatus)"
  )
  collon_prompt_2nd_bits=(
    "$(collon::component::vcs)"
    "$(collon::component::cwd)"
  )
  # Remove empty elements
  collon_prompt_1st_bits=${(M)collon_prompt_1st_bits:#?*}
  collon_prompt_2nd_bits=${(M)collon_prompt_2nd_bits:#?*}
  # Array to String
  collon_prompt_1st_bits=${(j: :)collon_prompt_1st_bits}
  collon_prompt_2nd_bits=${(j: :)collon_prompt_2nd_bits}
}

prompt_collon_setup() {
  # load required modules
  autoload -Uz terminfo
  autoload -Uz is-at-least
  autoload -Uz add-zsh-hook

  # prompt_subst   - http://www.csse.uwa.edu.au/programming/linux/zsh-doc/zsh_17.html#IDX501
  # prompt_percent - http://www.csse.uwa.edu.au/programming/linux/zsh-doc/zsh_17.html#IDX499
  prompt_opts=(subst percent)

  collon::configure_vcsstyles

  add-zsh-hook precmd collon::prompt_precmd

  PROMPT="\$collon_prompt_1st_bits "
  RPROMPT=" \$collon_prompt_2nd_bits"
}

prompt_collon_setup "$@"
