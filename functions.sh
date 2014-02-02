function sshcommand() {
    sshpass -p "$XENSERVER_PASSWORD" ssh -o StrictHostKeyChecking=no "$XENSERVER_USERNAME"@"$XENSERVER_HOST" "$@"
}

function xecommand() {
    xe -s "$XENSERVER_HOST" -u "root" -pw "$XENSERVER_PASSWORD" "$@"
}
