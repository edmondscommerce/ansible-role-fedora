### --pre


### --main

# User specific aliases and functions

alias rm='rm -i'
alias cp='cp -i'
alias mv='mv -i'
alias ll='ls -alh --color'

# Make parent dirs if they are missing
alias mkdir='mkdir -pv'
# Lets include vim like exit commands
alias :q="exit"
alias :Q="exit"

# Handle UTF-8 with less
export LESSCHARSET=utf-8


#History
shopt -s histappend
shopt -s cmdhist
HISTCONTROL=ignoredups
export HISTFILESIZE=20000
export HISTSIZE=10000
export HISTIGNORE="&:ls:[bf]g:exit"

# Add different directories to the $PATH if they exist
## Local bin folder
if [[ -d ~/bin/ ]];
then
    PATH="$PATH:$HOME/bin"
fi

# Composer global install
if [[ -d ~/.config/composer/vendor/bin/ ]];
then
    PATH="$PATH:$HOME/.config/composer/vendor/bin/"
fi

# RVM bin folder
if [[ -d ~/.rvm/bin ]];
then
    PATH=$PATH:$HOME/.rvm/bin
fi

# Settings for interactive shell only inside this block
if [[ $- == *i* ]]
then

    #SSH Agent
    if [ -z "$SSH_AUTH_SOCK" ] ; then
        inTemp=$(find /tmp -maxdepth 2 -type s -name "agent*" -user $USER -printf '%T@ %p\n' 2>/dev/null |sort -n|tail -1|cut -d' ' -f2)
        if [[ "" != "$inTemp" ]]
        then
            SSH_AUTH_SOCK="$inTemp"
            export SSH_AUTH_SOCK
        else
            if command -v keychain >/dev/null 2>&1;
            then
                eval `keychain -q --eval id_dsa id_rsa`
            else
                eval `ssh-agent -s`
                ssh-add
            fi
        fi
    fi

    #Prompt
    function redPrompt(){
        export PS1='\[\e[1m\]$PWD\[\e[0m\]'"\n\[\033[38;5;1m\]\u\[$(tput sgr0)\]\[\033[38;5;15m\]@\[$(tput sgr0)\]\[\033[38;5;9m\]\h\[$(tput sgr0)\] "
    }
    function bluePrompt(){
        export PS1='\[\e[1m\]$PWD\[\e[0m\]'"\n\[\033[38;5;32m\]\u\[$(tput sgr0)\]\[\033[38;5;15m\]@\[$(tput sgr0)\]\[\033[38;5;32m\]\h\[$(tput sgr0)\] "
    }
    if [[ "$(whoami)" == "root" ]]
    then
        redPrompt
    else
        bluePrompt
    fi

    #Prevent Ctrl+S Freezing things
    stty -ixon

    # fix spelling errors for cd, only in interactive shell
    shopt -s cdspell

    # More useful bash completelion setting
    bind "set completion-ignore-case on" # note: bind used instead of sticking these in .inputrc
    bind "set bell-style none" # no bell
    bind "set show-all-if-ambiguous On" # show list automatically, without double tab
    complete -r cd  # completion on symlinks is unusual and a __complete__ pain in the arse. Let's remove it

    alias gti=git

    ## To install
    ## dnf -y install bash-completion
    source /usr/share/bash-completion/bash_completion
    for f in /usr/share/bash-completion/completions/*; do
        source $f 2> /dev/null
    done

    export EDITOR=vim
    alias vi="vim"

    # Lets keep all of the aliases in one place
    if [[ -f ~/.bash_aliases ]];
    then
        . ~/.bash_aliases
    fi

    # And keep functions split out as well
    if [[ -f ~/.bash_functions.bash ]];
    then
        . ~/.bash_functions.bash
    fi
fi

# Moves up a number of dirs
up(){
    local d=""
    limit=$1
    for ((i=1 ; i <= limit ; i++))
    do
        d=$d/..
    done
    d=$(echo $d | sed 's/^\///')
    if [ -z "$d" ]; then
        d=..
    fi
    cd $d
}

# Universal uncompress
function extract {
 if [ -z "$1" ]; then
    # display usage if no parameters given
    echo "Usage: extract <path/file_name>.<zip|rar|bz2|gz|tar|tbz2|tgz|Z|7z|xz|ex|tar.bz2|tar.gz|tar.xz>"
    echo "       extract <path/file_name_1.ext> [path/file_name_2.ext] [path/file_name_3.ext]"
 else
    for n in "$@"
    do
      if [ -f "$n" ] ; then
          case "${n%,}" in
            *.cbt|*.tar.bz2|*.tar.gz|*.tar.xz|*.tbz2|*.tgz|*.txz|*.tar) 
                         tar xvf "$n"       ;;
            *.lzma)      unlzma ./"$n"      ;;
            *.bz2)       bunzip2 ./"$n"     ;;
            *.cbr|*.rar)       unrar x -ad ./"$n" ;;
            *.gz)        gunzip ./"$n"      ;;
            *.cbz|*.epub|*.zip)       unzip ./"$n"       ;;
            *.z)         uncompress ./"$n"  ;;
            *.7z|*.arj|*.cab|*.cb7|*.chm|*.deb|*.dmg|*.iso|*.lzh|*.msi|*.pkg|*.rpm|*.udf|*.wim|*.xar)
                         7z x ./"$n"        ;;
            *.xz)        unxz ./"$n"        ;;
            *.exe)       cabextract ./"$n"  ;;
            *.cpio)      cpio -id < ./"$n"  ;;
            *.cba|*.ace)      unace x ./"$n"      ;;
            *)
                         echo "extract: '$n' - unknown archive method"
                         return 1
                         ;;
          esac
      else
          echo "'$n' - file does not exist"
          return 1
      fi
    done
fi
}

# Fix legacy code
camelCase() {
  vim -E -s $@ <<-EOF
  :%s#\%($\%(\k\+\)\)\@<=_\(\k\)#\u\1#g
  :update
  :quit
EOF
}
# Read a csv file in a useful way
readCsv() {

  if [[ -z $2 ]]
  then
    LINE_NUMBER=2
  else
    LINE_NUMBER=$2
  fi

  if [[ -z $3 ]]
  then
    FIELD_SEPERATOR=','
  else
    FIELD_SEPERATOR=$3
  fi

  ( echo "Header Value" ; paste <( head -n 1 $1 | sed 's#'$FIELD_SEPERATOR'#\n#g' ) <( head -n $LINE_NUMBER $1 | tail -n 1 | sed 's#'$FIELD_SEPERATOR'#\n#g') ) | column -t
}
# http_headers: get just the HTTP headers from a web page (and its redirects)
http_headers () {
  /usr/bin/curl -I -L $@ ;

}

# debug_http: download a web page and show info on what took time
debug_http () {
  /usr/bin/curl $@ -o /dev/null -w "dns: %{time_namelookup} connect: %{time_connect} pretransfer: %{time_pretransfer} starttransfer: %{time_starttransfer} total: %{time_total}\n" ;
}
# showa: to remind yourself of an alias (given some part of it)
showa () {
  grep -i -a1 $@ ~/.bash_aliases | grep -v '^\s*$' ;
}

# getcolumn: extract a particular column of space-separated output
# e.g.: lsof | getcolumn 0 | sort | uniq
getcolumn () {
  perl -ne '@cols = split; print "$cols['$1']\n"' ;
}

ticker() {
  i=1;
  sp="/-\|";
  echo -n ' ';
  while true;
  do
    printf "\rRunning the command - please wait   ${sp:i++%${#sp}:1} ";
    sleep 0.5;
  done &
  $@
  kill $!; trap 'kill $!' SIGTERM;
}

### --post
