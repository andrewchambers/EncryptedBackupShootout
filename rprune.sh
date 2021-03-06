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

gdir=~/src/linux/.git

rm -rf /tmp/linux
mkdir /tmp/linux 
count=50
last_borg_id=""

for commit in $(sh -c "cd ~/src/linux && git rev-list v5.9 | head -n $count | tac")
do
  git "--git-dir=$gdir" "--work-tree=/tmp/linux" checkout "$commit" > /dev/null
  last_borg_id="$commit"
  borg create $BORG_REPO::$last_borg_id /tmp/linux
  restic backup -q /tmp/linux
  bupstash put -q /tmp/linux > /tmp/bupstash_last_id
done

export last_borg_id

cat <<EOF > /tmp/prepare.sh
set -xe

if test "\$(borg list $BORG_REPO | wc -l)" != "$count"
then
  borg create $BORG_REPO::$last_borg_id /tmp/linux
fi

if test "\$(restic snapshots -c | grep snapshots | awk '{ print(\$1) }')" != "$count"
then
  restic backup --tag x -q /tmp/linux
fi

if test "\$(bupstash list | wc -l)" != "$count"
then
  bupstash put -q /tmp/linux > /tmp/bupstash_last_id
fi
EOF

hyperfine -m 2 -p "sh /tmp/prepare.sh" \
  'borg delete $BORG_REPO $last_borg_id ' \
  'bupstash rm id="$(cat /tmp/bupstash_last_id)" && bupstash gc' \
  'restic forget latest && restic prune'

ssh acha.ninja -- rm -rf /home/ac/tmp/