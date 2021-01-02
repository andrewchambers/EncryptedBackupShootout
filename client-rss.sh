set -ex

export BORG_REPO="/tmp/borg-test-repo"
export BORG_PASSPHRASE=abc123
export RESTIC_REPOSITORY=/tmp/restic-test-repo
export RESTIC_PASSWORD=abc123
export BUPSTASH_REPOSITORY=/tmp/bupstash-test-repo
export BUPSTASH_KEY=/tmp/bupstash.key

rm -rf $BORG_REPO $RESTIC_REPOSITORY $BUPSTASH_REPOSITORY $BUPSTASH_KEY 
bupstash init
bupstash new-key -o $BUPSTASH_KEY
restic init
borg init -e repokey
rm -rf ~/.cache/bupstash
rm -rf ~/.cache/restic
rm -rf ~/.cache/borg

`which time` borg create $BORG_REPO::T /tmp/linux-5.9.8
`which time` bupstash put -q /tmp/linux-5.9.8
`which time` restic backup -q /tmp/linux-5.9.8
`which time` -o /tmp/tar.time -- tar -cf - /tmp/linux-5.9.8 | `which time` -o /tmp/gzip.time -- gzip | `which time` -o /tmp/gpg.time -- gpg --batch -e -r ac@acha.ninja > /tmp/linux.tar.gz.gpg

rm -rf $BORG_REPO $RESTIC_REPOSITORY $BUPSTASH_REPOSITORY $BUPSTASH_KEY 