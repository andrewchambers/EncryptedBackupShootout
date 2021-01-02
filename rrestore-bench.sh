set -ex

export BORG_REPO="ssh://acha.ninja/home/ac/tmp/borg-test-repo"
export BORG_PASSPHRASE=abc123
export RESTIC_REPOSITORY=sftp://acha.ninja/tmp/restic-test-repo
export RESTIC_PASSWORD=abc123
export BUPSTASH_KEY=/tmp/bupstash.key
export BUPSTASH_REPOSITORY="ssh://acha.ninja/home/ac/tmp/bupstash-test-repo"

rm -f /tmp/bupstash.key
ssh acha.ninja -- rm -rf /home/ac/tmp/
ssh acha.ninja -- mkdir /home/ac/tmp/

bupstash init
bupstash new-key -o $BUPSTASH_KEY
restic init
borg init -e repokey

rm -rf ~/.cache/bupstash
rm -rf ~/.cache/restic
rm -rf ~/.cache/borg

restic backup -q /tmp/linux-5.9.8
borg create $BORG_REPO::T /tmp/linux-5.9.8
export bupstash_id=$(bupstash put -q /tmp/linux-5.9.8)
tar -C /tmp/linux-5.9.8 -cf - . | gzip | gpg --batch -e -r ac@acha.ninja | ssh acha.ninja -- sh -c 'cat > ~/tmp/linux.tar.gz.gpg'

rm -rf /tmp/restore
mkdir /tmp/restore
cd /tmp/restore

hyperfine -m 2 -w 1 -p 'rm -rf /tmp/restore/*'  \
  'ssh acha.ninja -- cat /home/ac/tmp/linux.tar.gz.gpg | gpg --batch -o - --decrypt - | gzip -d | tar -C /tmp/restore -xf -' \
  'restic restore --target=/tmp/restore latest' \
  'bupstash get id=$bupstash_id | tar -xf -' \
  'borg extract $BORG_REPO::T'

rm -f /tmp/bupstash.key
ssh acha.ninja -- rm -rf /home/ac/tmp/