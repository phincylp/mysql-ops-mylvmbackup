#!/usr/bin/perl

# Copyright (C) 2011 DeNA Co.,Ltd.
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc.,
# 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA

use strict;
use warnings FATAL => 'all';
use Inline C => 'DATA';

#my @target_dirs = ( '/var/lib/mysql', '/var/lib/mysql/innodb_logs' );
my @target_dirs = ( '/var/lib/mysql');
my @fully_unmap_logs = ('ib_logfile');
my $binary_log_name = 'mysqld-bin';
my $relay_log_name = 'mysqld-relay-bin';

&main();

sub unmap_binary_logs {
  my $binlog_name = shift;
  foreach my $dir (@target_dirs) {
	print "\nUnmapping binlogs from  $dir";
    opendir DIR, $dir;
    my @files =
      grep { m/$binlog_name\.[0-9][0-9][0-9][0-9][0-9][0-9]/ } readdir DIR;
    @files = sort @files;
    for ( my $i = 0 ; $i < $#files + 1 ; $i++ ) {
      my $fpath = $dir . "/" . $files[$i];

      # The tail of the latest binary/relay logs are read from binlog dump
      # thread or SQL thread. To keep the tail in cache, we don't
      # unmap all area, but unmap 90% of the file (the 10% tail is cached).
      if ( $i == $#files ) {
        my $filesize = -s $fpath;
        unmap_log( $fpath, 0, int( $filesize * 0.9 ) );
      }
      else {
        unmap_log_all($fpath);
      }
    }
    closedir DIR;

    #binlog is under this directry. We don't need to search more
    last if ( $#files + 1 > 0 );
  }
}

sub unmap_logs {
  foreach my $dir (@target_dirs) {
    opendir DIR, $dir;
    foreach my $target (@fully_unmap_logs) {
      my @files = grep { m/$target/ } readdir DIR;
      foreach my $file (@files) {
        my $fpath = $dir . "/" . $file;
        unmap_log_all($fpath);
      }
    }
  }
}

sub main {
  unmap_binary_logs($binary_log_name);
  unmap_binary_logs($relay_log_name);
  unmap_logs();
}

__DATA__
__C__

#define _XOPEN_SOURCE 600
#define _FILE_OFFSET_BITS 64
#include <fcntl.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <fcntl.h>
#include <stdlib.h>
#include <stdio.h>

int unmap_log(const char *fpath, size_t start, size_t len)
{
  int fd = open(fpath, O_RDONLY);
  if (fd < 0) {
    fprintf(stderr, "Failed to open %s\n", fpath);
    return 1;
  }
  int r = posix_fadvise(fd, start, len, POSIX_FADV_DONTNEED);
  if (r != 0) {
    fprintf(stderr, "posix_fadvice failed for %s\n", fpath);
  }
  close(fd);
  return 0;
}

int unmap_log_all(const char *fpath)
{
  return unmap_log(fpath, 0, 0);
}
