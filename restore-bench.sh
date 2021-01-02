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

restic backup -q /tmp/linux-5.9.8
borg create $BORG_REPO::T /tmp/linux-5.9.8
export bupstash_id=$(bupstash put -q /tmp/linux-5.9.8)
tar -C /tmp/linux-5.9.8 -cf - . | gzip | gpg --batch -e -r ac@acha.ninja > /tmp/linux.tar.gz.gpg

rm -rf /tmp/restore
mkdir /tmp/restore
cd /tmp/restore

hyperfine -w 1 -p 'rm -rf /tmp/restore/*' \
  'gpg --batch -o - --decrypt /tmp/linux.tar.gz.gpg | gzip -d | tar -C /tmp/restore -xf -' \
  'restic restore --target=/tmp/restore latest' \
  'bupstash get id=$bupstash_id | tar -xf -' \
  'borg extract $BORG_REPO::T'

rm -rf $BORG_REPO $RESTIC_REPOSITORY $BUPSTASH_REPOSITORY $BUPSTASH_KEY 