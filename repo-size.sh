
set -ex

export BORG_REPO="/tmp/borg-test-repo"
export BORG_PASSPHRASE=abc123
export RESTIC_REPOSITORY=/tmp/restic-test-repo
export RESTIC_PASSWORD=abc123
export BUPSTASH_REPOSITORY=/tmp/bupstash-test-repo
export BUPSTASH_KEY=/tmp/bupstash.key

rm -rf ~/tmp/linux $BORG_REPO $RESTIC_REPOSITORY $BUPSTASH_REPOSITORY $BUPSTASH_KEY /tmp/tar-snapshots
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

mkdir -p ~/tmp/linux
for commit in $(git --git-dir="$gdir" rev-list v5.9 | head -n 20 | tac)
do
  mkdir ~/tmp/linux/$commit
  git "--git-dir=$gdir" archive "$commit" | tar -C ~/tmp/linux/$commit -xf -
done

du -hs ~/tmp/linux
bupstash put -q --send-log /tmp/t.sendlog ~/tmp/linux
du -hs $BUPSTASH_REPOSITORY
rm -rf $BUPSTASH_REPOSITORY

borg create $BORG_REPO::TEST ~/tmp/linux
du -hs $BORG_REPO
rm -rf $BORG_REPO

restic backup -q ~/tmp/linux
du -hs $RESTIC_REPOSITORY
rm -rf $RESTIC_REPOSITORY

tarsz=$(tar -C ~/tmp/linux -cf - . | gzip | gpg --batch -e -r ac@acha.ninja | wc -c)
echo "tgz size $tarsz"

rm -rf /tmp/tar-snapshots ~/tmp/linux $BUPSTASH_KEY