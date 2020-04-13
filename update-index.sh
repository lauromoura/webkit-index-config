#!/usr/bin/env bash

LOG_DIR=/var/log/webkit-indexer
if [[ ! -d "$LOG_DIR" ]]; then
	echo "Couldn't find log directory : $LOG_DIR"
	exit 1
fi

LOG=$LOG_DIR/log

export KEEP_WORKING=1

INDEXER_SETUP=$HOME/mozsearch/infrastructure/indexer-setup.sh
INDEXER_RUN=$HOME/mozsearch/infrastructure/indexer-run.sh
WEB_SERVER_SETUP=$HOME/mozsearch/infrastructure/web-server-setup.sh
WEB_SERVER_RUN=$HOME/mozsearch/infrastructure/web-server-run.sh

WEBKIT_INDEX_CONFIG=$HOME/webkit-index-config
WEBKIT_INDEX=$HOME/webkit-index

function log {
	local msg="$1"
	echo $msg >> $LOG
}

function last_sha {
	cd "$WEBKIT_INDEX/webkit/WebKit"
	local sha=$(git log -1 --pretty="format:%h")
	echo $sha
}

function fatal {
	local msg="$1"
	local now=$(date)
	local sha=$(last_sha)	
	log "($now): Fail $msg (SHA: $sha)"
	exit 1
}

function success {
	local msg="$1"
	local now=$(date)
	local sha=$(last_sha)
	log "($now): Success $msg (SHA: $sha)"
}

function indexer_setup {
	$INDEXER_SETUP $WEBKIT_INDEX_CONFIG config.json $WEBKIT_INDEX
	if [[ $? != 0 ]]; then
		fatal "indexer-setup"
	else
		success "indexer-setup"
	fi
}

# Indexer run.
function indexer_run {
	$INDEXER_RUN $WEBKIT_INDEX_CONFIG $WEBKIT_INDEX
	if [[ $? != 0 ]]; then
		fatal "indexer-run"
	else
		success "indexer-run"
	fi
}

function web_server_setup {
	$WEB_SERVER_SETUP $WEBKIT_INDEX_CONFIG config.json $WEBKIT_INDEX $HOME
	if [[ $? != 0 ]]; then
		fatal "web-server-setup"
	else
		success "web-server-setup"
	fi
}

function web_server_run {
	$WEB_SERVER_RUN $WEBKIT_INDEX_CONFIG $WEBKIT_INDEX $HOME
	if [[ $? != 0 ]]; then
		fatal "web-server-run"
	else
		success "web-server-run"
	fi
}

if [[ $# -eq 0 ]]; then
	indexer_setup
	indexer_run
	web_server_run
else
	for each in "$@"; do
		case "$each" in
			"indexer-setup")
				indexer_setup
			;;
			"indexer-run")
				indexer_run
			;;
			"web-server-setup")
				web_server_setup
			;;
			"web-server-run")
				web_server_run
			;;
		esac
	done
fi
