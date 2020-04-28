#!/usr/bin/env bash

usage() {
   local exit_code="${1:0}"

   local program_name=$(basename "$0")
   echo "$program_name [STEP]"
   echo "Runs a step of the indexing process. If not step is set, all steps are run."
   echo ""
   echo "ARGUMENTS:"
   echo -e "\tSTEP\tindexer-setup, indexer-run, web-server-setup, web-server-run."
   exit $exit_code
}

for each in "$@"; do
   if [[ "$each" == "-h" || "$each" == "--help" ]]; then
      usage
   fi
done

LOG_DIR=/var/log/webkit-indexer
if [[ ! -d "$LOG_DIR" ]]; then
   echo "Couldn't find log directory : $LOG_DIR"
   exit 1
fi

LOG=$LOG_DIR/log

LOCK="$HOME/.webkit-search-lock"
if [[ -f "$LOCK" ]]; then
   # Nothing to do, job is in process.
    exit 0
else
   touch "$LOCK"
fi

function cleanup
{
   rm -f "$LOCK"
}

trap cleanup SIGHUP SIGTERM

export KEEP_WORKING=1

INDEXER_SETUP=$HOME/mozsearch/infrastructure/indexer-setup.sh
INDEXER_RUN=$HOME/mozsearch/infrastructure/indexer-run.sh
WEB_SERVER_SETUP=$HOME/mozsearch/infrastructure/web-server-setup.sh
WEB_SERVER_RUN=$HOME/mozsearch/infrastructure/web-server-run.sh

WEBKIT_INDEX_CONFIG=$HOME/webkit-index-config
WEBKIT_INDEX=$HOME/webkit-index
WEBKIT_DIR=$WEBKIT_INDEX/webkit/WebKit

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

function revision
{
   cd $WEBKIT_DIR
   revision=$(git log -1 | tail -1 | egrep -o "@[0-9]+" | tr -d '@')
   echo "r$revision"
}

function last_build
{
   cd $WEBKIT_DIR
   line=$(git log -1 --pretty="format:%h %aI %s")
   revision=$(revision)
   echo "$revision $line" | tee $HOME/.last_build
}

function format_seconds
{
    local seconds="$1"

    local h=$((seconds / 3600))
    local m=$((seconds / 60 % 60))
    local s=$((seconds % 60))

    printf '%02d:%02d:%02d' $h $m $s
}

function full_indexing
{
   local start=$(date +%s)

   indexer_setup
   indexer_run
   web_server_run
    last_build

   local end=$(date +%s)
   local delta=$((end - start))
   local time=$(format_seconds "$delta")
   success "Total time: $time"
}

# Main.

if [[ $# -eq 0 ]]; then
   full_indexing
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
            "timestamp")
            last_build
         ;;
      esac
   done
fi

cleanup
