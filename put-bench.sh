

export BORG_REPO="/tmp/borg-test-repo"
export BORG_PASSPHRASE=abc123
export RESTIC_REPOSITORY=/tmp/restic-test-repo
export RESTIC_PASSWORD=abc123
export BUPSTASH_REPOSITORY=/tmp/bupstash-test-repo
export BUPSTASH_KEY=/tmp/bupstash.key

cat <<EOF > /tmp/prepare.sh
set -e
rm -rf $BORG_REPO $RESTIC_REPOSITORY $BUPSTASH_REPOSITORY $BUPSTASH_KEY /tmp/linux.tar.gpg.gz
bupstash init
bupstash new-key -o $BUPSTASH_KEY
restic init
borg init -e repokey
rm -rf ~/.cache/bupstash
rm -rf ~/.cache/restic
rm -rf ~/.cache/borg
EOF

hyperfine -p "sh /tmp/prepare.sh" \
  'tar -cf - /tmp/linux-5.9.8 | gzip | gpg --batch -e -r ac@acha.ninja > /tmp/linux.tar.gz.gpg' \
  'borg create $BORG_REPO::T /tmp/linux-5.9.8' \
  'bupstash put -q /tmp/linux-5.9.8' \
  'restic backup -q /tmp/linux-5.9.8'
  

rm -rf $BORG_REPO $RESTIC_REPOSITORY $BUPSTASH_REPOSITORY $BUPSTASH_KEY /tmp/linux.tar.gpg.gz