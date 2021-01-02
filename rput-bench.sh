set -e

export BORG_REPO="ssh://acha.ninja/home/ac/tmp/borg-test-repo"
export BORG_PASSPHRASE=abc123
export RESTIC_REPOSITORY=sftp://acha.ninja/tmp/restic-test-repo
export RESTIC_PASSWORD=abc123
export BUPSTASH_KEY=/tmp/bupstash.key
export BUPSTASH_REPOSITORY="ssh://acha.ninja/home/ac/tmp/bupstash-test-repo"

cat <<EOF > /tmp/prepare.sh
set -xe

rm -f /tmp/bupstash.key
ssh acha.ninja -- rm -rf /home/ac/tmp/
ssh acha.ninja -- mkdir /home/ac/tmp/
bupstash new-key -o $BUPSTASH_KEY
bupstash init
restic init
borg init -e repokey
rm -rf ~/.cache/bupstash
rm -rf ~/.cache/restic
rm -rf ~/.cache/borg
EOF

hyperfine -m 2 -p "sh /tmp/prepare.sh" \
  'tar -cf - /tmp/linux-5.9.8 | gzip | gpg --batch -e -r ac@acha.ninja | ssh acha.ninja -- sh -c "cat  /tmp/linux.tar.gz.gpg > ~/tmp/backup.tar.gz.gpg"' \
  'bupstash put -q /tmp/linux-5.9.8' \
  'restic backup -q /tmp/linux-5.9.8' \
  'borg create ::T /tmp/linux-5.9.8' 

ssh acha.ninja -- rm -rf /home/ac/tmp/
