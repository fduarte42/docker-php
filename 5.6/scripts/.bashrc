PS1='${debian_chroot:+($debian_chroot)}\u@\h:\w\$ '
alias ll='ls -l'
alias la='ls -la'
alias ls='ls --color=auto'

if [ -e "/ssh/id_rsa.pub" ]; then
    cp /ssh/id_rsa.pub ~/.ssh/id_rsa.pub
    chmod 644 ~/.ssh/id_rsa.pub
fi

if [ -e "/ssh/id_rsa" ]; then
    cp /ssh/id_rsa ~/.ssh/id_rsa
    chmod 600 ~/.ssh/id_rsa
    eval $(keychain --eval id_rsa)
fi

export TERM=xterm
export COMPOSER_HOME=~/.composer
