
set -ex

export BORG_REPO="/tmp/borg-test-repo"
export BORG_PASSPHRASE=abc123
export RESTIC_REPOSITORY=/tmp/restic-test-repo
export RESTIC_PASSWORD=abc123
export BUPSTASH_REPOSITORY=/tmp/bupstash-test-repo
export BUPSTASH_KEY=/tmp/bupstash.key

rm -rf /tmp/linux $BORG_REPO $RESTIC_REPOSITORY $BUPSTASH_REPOSITORY $BUPSTASH_KEY /tmp/tar-snapshots
bupstash init
bupstash new-key -o $BUPSTASH_KEY
restic init
borg init -e repokey
mkdir /tmp/tar-snapshots
rm -rf ~/.cache/bupstash
rm -rf ~/.cache/restic
rm -rf ~/.cache/borg
rm -f /tmp/test.snar

gdir=~/src/linux/.git

mkdir /tmp/linux
for n in $(seq 0 10)
do
  tag=v5.$n
  git "--git-dir=$gdir" "--work-tree=/tmp/linux" checkout "$tag" > /dev/null
  bupstash put -q --send-log /tmp/t.sendlog /tmp/linux
  borg create $BORG_REPO::$tag /tmp/linux
  restic backup -q /tmp/linux
  tar --listed-incremental /tmp/test.snar -C /tmp/linux -cf - . | gzip | gpg --batch -e -r ac@acha.ninja > /tmp/tar-snapshots/$tag.tar.gz.gpg
done

du -hs $BUPSTASH_REPOSITORY
du -hs $BORG_REPO
du -hs $RESTIC_REPOSITORY
du -hs /tmp/tar-snapshots

rm -rf /tmp/linux $BORG_REPO $RESTIC_REPOSITORY $BUPSTASH_REPOSITORY $BUPSTASH_KEY /tmp/tar-snapshots