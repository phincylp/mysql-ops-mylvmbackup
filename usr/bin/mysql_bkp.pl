#!/usr/bin/perl

use Getopt::Long;
use IO::Socket;
use Log::Log4perl;
use Data::Dumper;

use hostdbapi;

my %opts;
my %hash;
my $HFLAG = 0;
my $STAT_DIR = "/var/log/fk-ops-bkp-server/status/current/";
my $LOG = "/var/log/fk-ops-bkp-server/backup.log";
my $JOBS = 10;
my $PORT = 24006;
my $TIME = time;

if(! -d "$STAT_DIR")
{
`mkdir -p $STAT_DIR `;
}

Log::Log4perl->init(\<<CONFIG);
log4perl.rootLogger = DEBUG, screen, file

log4perl.appender.screen = Log::Log4perl::Appender::Screen
log4perl.appender.screen.stderr = 0
log4perl.appender.screen.layout = PatternLayout
log4perl.appender.screen.layout.ConversionPattern = %d %p> %F{1}:%L %M - %m%n

log4perl.appender.file = Log::Log4perl::Appender::File
log4perl.appender.file.filename = $LOG
log4perl.appender.file.mode = append
log4perl.appender.file.layout = PatternLayout
log4perl.appender.file.layout.ConversionPattern = %d %p> %F{1}:%L %M - %m%n
CONFIG

my $logger = Log::Log4perl->get_logger();

main();


sub main
{

 my $all = '';
&GetOptions( \%opts, 'host=s', 'all' => \$all);
unless ( $opts{'host'} || $all  ) {
    &usage;


}

if($opts{'host'})
{
$host = $opts{'host'};
$HFLAG = 1;
&trigger_bkp($host);
exit;
}

if($all)
{
print "\nhot\n";
&populate_hash("fk-hs-db");
print Dumper(%hash);
print "\nfk-dbs\n";
&populate_hash("fk-dbs");
print Dumper(%hash);
print "\ndumper\n";
print Dumper(%hash);
print "\n here";


$dir = "/etc/fk-ops-bkp";
$servers = $dir . "/" . "mysql";
unless(-d $dir)
{
`mkdir -p $dir`;
}

open(F,">$servers");

foreach my $master (keys %hash)
{
print "\n\n$master -> @{$hash{$master}}";
my $str = $master . ":" . join(",",@{$hash{$master}});
print F "$str\n";
print "\ns is $str";
}
close F;

sleep 60;
foreach my $master (keys %hash)
{
foreach $i ( 0 .. $#{ $hash{$master} } ) 
{
my $stat = &trigger_bkp($hash{$master}[$i]);
print "\n hs is $hash{$master}[$i] and $stat\n";
if($stat == 1 )
{
$logger->info("waiting: sleeping 120s");
#sleep 120;
last;
}
}
}

print "\n there";
exit;
}

}


sub populate_hash
{
my $tag = shift;
my $obj = new hostdbapi;
my @hosts = split("\n",$obj->gethostoftag($tag));
foreach my $host (@hosts)
{
my $stat  = get_master($host);
}
}


sub get_master
{
$remote_host = shift;
print "\nrt is $remote_host\n ";
$line = `echo "STAT\n" |  /bin/nc -w 10 $remote_host $PORT`;
$logger->info("$remote_host: reply ->  $line");
if($line =~ m/master:(.*)/i)
{
 push @{ $hash{"$1"} }, $remote_host;
}
else
{
$logger->error("$remote_host: Err");
}
}

sub fork_file
{
$file = shift;
if(-r $file )
{
open(F, "$file") || die "Cant open $file";   
my @hosts = <F>;   
close(F);
foreach my $host (@hosts)
{
chomp($host);
my $stat = &get_master($host);
}
return 1;
}
else
{
$logger->error("$file: Read error");
}
}

sub trigger_bkp
{

$remote_host = shift;
$line = `echo "BKP\n" |  /bin/nc -w 10 $remote_host $PORT`;
$logger->info("$remote_host: reply ->  $line");
if($line =~ /started/mi )
{
$logger->info("$remote_host: Backup started");
return 1;
}
return 3;
}

sub usage 
{

  print "\n  Usage:\n\n";
  print "  $0 --host <hostname> \n";
  print "  $0 --all - Backs up all clusters\n";
  print "
  Example:

  $0 --host w3-web1 
  $0 --all\n\n";

  exit 1;

}
