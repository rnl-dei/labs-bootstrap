#!/bin/sh

# Se corre sem argumentos corre a si próprio dentro de um tmux

if [ -z $1 ] ; then
        tmux new-session -d -s cenas 'bash completeScript.sh loles'
        exit
fi

cd /downloads
script="$(find . -name run.sh)"

if [ -n "$script" ]; then
	script_dir=$(dirname ${script})
	cd "${script_dir}"
	chmod +x run.sh
	sh run.sh
else
	echo "Cannot find run.sh in /downloads"
fi
