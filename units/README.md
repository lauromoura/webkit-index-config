# Basic systemd units for WebKitSearch

These are some units wrapping the `mozsearch/infrastructure` scripts to help to
automate the update and deployment of WebKitSearch instances.

## Unit files

* `webkit-search-indexer-setup@.service`
    * Update codebase and collect blame info
    * Oneshot
* `webkit-search-indexer-run@.service`
    * Builds the code and update the index
    * Oneshot, follows `indexer-setup`
* `webkit-search-web-router@.service`
    * Python process with the router
    * Simple daemon
* `webkit-search-web-server@.service`
    * Rust web server for the actual search service

## TODO

* [ ] Add timer units for periodic updates
* [ ] Check if we need to restart the router and server after updates
    * [ ] At least will need some step to update the index `LAST_BUILD` tag
* [ ] Script to deploy
