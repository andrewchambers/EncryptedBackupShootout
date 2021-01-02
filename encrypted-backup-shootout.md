# Encrypted Backup Shootout

Recently I have been spending time on improving the performance of [bupstash](https://github.com/andrewchambers/bupstash) (my encrypted backup tool), and wanted to compare it to some existing tools I have used in the past.
This post compares [bupstash](https://github.com/andrewchambers/bupstash), [restic](https://restic.net/), [borg](https://www.borgbackup.org/) and plain old tar + gzip + gpg across a series of simple benchmarks.

What do all these tools have in common?

- They encrypt data at rest.
- They compress data.
- They have some form of incremental and/or deduplicated snapshotting.
- They are all pretty great backup systems.


# Benchmarks

For these tests we are using the following versions of the given software:

- GNU tar 1.32 + gzip 1.10 + gpg 2.2.23
- Bupstash 0.6.1
- Borg 1.1.14
- Restic 0.11.0

The test machine has an AMD Ryzen Threadripper 1950X 16-Core Processor with 16 GB of ram, though perhaps it is best to simply compare results relatively, as reproducing my test environment exactly would be difficult.

## Creating a fresh directory snapshot

For this benchmark we are snapshotting a copy of the linux 
5.9.8 source code.

The directory we are snapshotting is 1.1 GB comprised of 74725 files and directories.

The snapshots are all made to tmpfs so hopefully does not measure delays introduced by the network or disk activity.

```
Benchmark #1: bupstash put

  Time (mean ± σ):      3.939 s ±  0.026 s
 
  Range (min … max):    3.885 s …  3.973 s

Benchmark #2: restic backup

  Time (mean ± σ):      6.026 s ±  0.087 s
 
  Range (min … max):    5.921 s …  6.194 s

Benchmark #3: borg create

  Time (mean ± σ):     13.831 s ±  0.175 s
 
  Range (min … max):   13.610 s … 14.152 s

Benchmark #4: tar | gzip | gpg 

  Time (mean ± σ):     24.505 s ±  0.232 s
 
  Range (min … max):   24.145 s … 24.887 s

Summary

  'bupstash put' ran
    1.53x faster than 'restic backup'
    3.51x faster than 'borg create'
    6.22x faster than 'tar | gzip | gpg'

```

Bupstash is the clear winner here for raw snapshotting speed, to answer why might take another blog post to really dig into the details.

## Sending a fresh snapshot to a remote server

This benchmark is the same as the fresh local snapshot benchmark except the files are sent to a remote server hosted on google cloud via ssh. This benchmark should only be considered an approximation of the effect latency has on the tool performance as it is so dependent on network speeds.

At the time of benchmarking my connection to the remote server can be summarized as follows:

- server -> client 10MiB/s
- client -> client 2.5MiB/s
- ping 32 milliseconds

```
Benchmark #1: tar | gzip | gpg | ssh

  Time (mean ± σ):     72.640 s ±  0.560 s
 
  Range (min … max):   72.244 s … 73.036 s
 
Benchmark #2: bupstash put

  Time (mean ± σ):     121.817 s ±  1.498 s
 
  Range (min … max):   120.757 s … 122.876 s
 
Benchmark #3: borg create

  Time (mean ± σ):     143.942 s ±  1.204 s
 
  Range (min … max):   143.090 s … 144.793 s

Benchmark #4: restic backup

  Time (mean ± σ):     414.859 s ±  5.813 s
 
  Range (min … max):   410.748 s … 418.970 s

Summary

  'tar | gzip | gpg | ssh' ran
    1.68x faster than 'bupstash put'
    1.98x faster than 'borg create'
    5.71x faster than 'restic backup'

```

Plain tar takes the win again, Restic performs poorly here, it has a far more latency sensitive upload protocol.

## Creating an incremental directory snapshot

This benchmark is the same as the fresh local snapshot benchmark, except now we measure the time for an incremental snapshot using the builtin caching mechanism of the tools. What this means is each tool keeps a record of what files it has already sent, and is able to
skip doing that work again.

```
Benchmark #1: tar --listed-incremental | gzip | gpg

  Time (mean ± σ):     209.7 ms ±  11.1 ms
 
  Range (min … max):   195.1 ms … 237.6 ms

Benchmark #2: bupstash put

  Time (mean ± σ):     394.6 ms ±  12.8 ms
 
  Range (min … max):   379.4 ms … 416.9 ms 
 
Benchmark #3: restic backup

  Time (mean ± σ):      3.916 s ±  0.034 s
 
  Range (min … max):    3.855 s …  3.958 s

Benchmark #4: borg create

  Time (mean ± σ):      7.724 s ±  0.085 s
 
  Range (min … max):    7.621 s …  7.895 s
 
Summary

  'tar --listed-incremental | gzip | gpg' ran
    1.88x faster than 'bupstash put -q /tmp/linux-5.9.8'
   18.67x faster than 'restic backup -q /tmp/linux-5.9.8'
   36.82x faster than 'borg create'
```

Incremental tar is the clear winner here. Why are the other tools slower? I think this is mainly because the other tools present each snapshot to the user as a full backup and thus do extra work to spare the end user from managing incremental backups manually.

It is also interesting to me that 'bupstash put' is an order of magnitude faster than the other similar tools, though I currently can not explain clearly why that may be the case.

## Sending an incremental snapshot to a remote server

This benchmark is the same as the incremental local snapshot benchmark except the files are sent to a remote server hosted on google cloud via ssh.

Benchmark conditions are the same as the fresh remote snapshot benchmark.

```
Benchmark #1: tar --listed-incremental | gzip | gpg | ssh

  Time (mean ± σ):     779.1 ms ±   8.9 ms
 
  Range (min … max):   761.1 ms … 785.7 ms

Benchmark #2: bupstash put

  Time (mean ± σ):     999.0 ms ±  19.8 ms
 
  Range (min … max):   976.0 ms … 1046.5 ms

Benchmark #3: restic backup

  Time (mean ± σ):      6.140 s ±  0.186 s
 
  Range (min … max):    6.054 s …  6.666 s

Benchmark #4: borg create

  Time (mean ± σ):     10.672 s ±  0.319 s
 
  Range (min … max):   10.410 s … 11.504 s
 
Summary

  'tar --listed-incremental | gzip | gpg | ssh' ran
    1.28x faster than 'bupstash put'
    7.88x faster than 'restic backup'
   13.70x faster than 'borg create'
```

These results match closely with the local incremental snapshots.

## Restoring a snapshot

In this benchmark we will restore the snapshot made in the fresh local snapshot benchmark to tmpfs.

```
Benchmark #1: bupstash get | tar -x

  Time (mean ± σ):      2.712 s ±  0.056 s
 
  Range (min … max):    2.598 s …  2.809 s

Benchmark #2: gpg -d | gzip -d | tar -x

  Time (mean ± σ):      4.449 s ±  0.021 s
 
  Range (min … max):    4.428 s …  4.484 s
 
Benchmark #3: restic restore

  Time (mean ± σ):      4.890 s ±  0.026 s
 
  Range (min … max):    4.853 s …  4.944 s

Benchmark #4: borg extract

  Time (mean ± σ):      9.694 s ±  0.066 s
 
  Range (min … max):    9.579 s …  9.781 s
 
Summary

  'bupstash get | tar -x' ran
    1.64x faster than 'gpg -d | gzip -d | tar -x'
    1.80x faster than 'restic restore'
    3.57x faster than 'borg extract'
```

Bupstash is the clear winner for restoring backups.

## Restoring a snapshot from a remote server

In this benchmark we will restore the snapshot made in the fresh remote snapshot benchmark to tmpfs. The main difference from the previous benchmark is the introduction of
an internet connection between the backup repository and restore point.

Network conditions are the same as the fresh network snapshot benchmark.

```
Benchmark #1: ssh | gpg -d | gzip -d | tar -x

  Time (mean ± σ):     28.082 s ±  0.198 s
 
  Range (min … max):   27.942 s … 28.221 s

Benchmark #2: bupstash get | tar -x

  Time (mean ± σ):     48.893 s ±  1.732 s
 
  Range (min … max):   47.669 s … 50.118 s

Benchmark #3: borg extract

  Time (mean ± σ):     52.931 s ± 10.887 s
 
  Range (min … max):   45.233 s … 60.630 s

Benchmark #4: restic restore

  Time (mean ± σ):     146.098 s ±  3.045 s
 
  Range (min … max):   143.946 s … 148.251 s

Summary

  'ssh | gpg -d | gzip -d | tar -x' ran
    1.74x faster than 'bupstash get | tar -x'
    1.88x faster than 'borg extract'
    5.20x faster than 'restic restore'
```

## Pruning an old backup

In this benchmark we will be removing an old snapshot from the backup repository on the same computer. For this test we generate a backup repository with 50 different snapshots of different versions of the linux kernel source code and then time how long it takes to remove one of the snapshots.

Tar with incremental backups does not easily support pruning of old backups, so does not participate in this benchmark.

```
Benchmark #1: bupstash rm && bupstash gc

  Time (mean ± σ):      38.6 ms ±   1.0 ms
 
  Range (min … max):    37.2 ms …  40.6 ms

Benchmark #2: borg delete

  Time (mean ± σ):     497.8 ms ±  15.9 ms
 
  Range (min … max):   477.4 ms … 525.1 ms
  
Benchmark #3: restic forget && restic prune

  Time (mean ± σ):      2.030 s ±  0.017 s
 
  Range (min … max):    2.008 s …  2.067 s
 
Summary

  'bupstash rm && bupstash gc' ran
   12.91x faster than 'borg delete'
   52.63x faster than 'restic forget && restic prune'

```

The bupstash garbage collector is very fast compared to borg and restic, as the author I can say I took special care to optimize this part of bupstash so am quite happy with this result.

## Pruning an old backup on a remote server

In this benchmark we will be removing an old snapshot from the backup repository stored on a remote server. The remote server is the same as the one used in fresh remote snapshot benchmark, and the test data is the same as the local prune bench mark.

```
Benchmark #1: bupstash rm && bupstash gc

  Time (mean ± σ):      2.137 s ±  1.010 s
 
  Range (min … max):    1.422 s …  2.851 s

Benchmark #2: borg delete

  Time (mean ± σ):      3.111 s ±  0.087 s
 
  Range (min … max):    3.049 s …  3.172 s
 
Benchmark #3: restic forget && restic prune

  Time (mean ± σ):     145.540 s ±  3.075 s
 
  Range (min … max):   143.365 s … 147.715 s
 
Summary

  'bupstash rm && bupstash gc' ran
    1.46x faster than 'borg delete'
   68.12x faster than 'restic forget && restic prune'
```

## Deduplication and compression

For this benchmark we take 20 different consecutive versions of the linux kernel source code and add them all to the same directory, we then create a backup and measure the size of the resulting backup.

The linux kernel versions chosen for this test are all the consecutive git commits preceeding version 5.9.

and the resulting directory is 21GB of uncompressed files.

Results:

- bupstash 0.378 GB, 55x Compression ratio
- borg 0.476 GB, 49x Compression ratio
- restic 1.5 GB, 14x Compression ratio
- tar + gzip + gpg 3.6 GB, 5.8x Compression ratio

This benchmark shows the advantage the more sophisticated tools have over plain tarballs, They all have extremely good compression ratios when similar data is added multiple times to
a backup repository.


## Approx peak client side ram usage

For this benchmark we repeat the fresh snapshot benchmark, but measure the peak client ram usage (RSS) as reported by the 'time'. For tar we approximate this by summing the peak memory usage across tar, gpg and gzip.

Results:

- tar + gzip + gpg 10.312 MB
- bupstash 18.192 MB
- borg 96.696 MB
- restic 191.252 MB

As always the unix tools are very memory efficient, bupstash is an order of magnitude more
memory efficient than restic, probably partially due to being implemented in rust compared to Go and python/cython for borg.

# Conclusions and discussion

GNU Tar + gzip + gpg is an excellent encrypted backup option and performed better than I expected. I think tar and gpg is still a great choice for users who prefer to DIY their own backup scripts. So what are the problems with tar that the other tools address? Managing
incremental backups, deduplication and pruning and searching backups are far more difficult when using plain old incremental tar.

Bupstash is often the fastest of the tools tested. Bupstash performs especially well when there is high network latency and is two orders of magnitude faster at pruning and cycling old backups out of your backup set
then the slowest contender.

Borg offers the best deduplication of all the tools at the cost of some speed, overall it is a very well rounded encrypted backup tool.

Restic, while fast at local operation, but seems to trail the other tools when network latency is added. Restic also seems to very slow backup deletion and cycling, though this may not be an issue for users who prefer to never remove old backups.

In conclusion, I can see strengths, weaknesses and room for improvement in all the tools tested, and encourage everyone to give them a try for yourself.

As always, thank you for your time and see you next time :).