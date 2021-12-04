PS1='${debian_chroot:+($debian_chroot)}\u@\h:\w\$ '
alias ll='ls -l'
alias la='ls -la'
alias ls='ls --color=auto'

if [ -f ~/.ssh/id_rsa ]; then
    eval $(keychain --eval id_rsa)
fi

PATH=$PATH:~/.composer/vendor/bin
export TERM=xterm
export COMPOSER_HOME=~/.composer
