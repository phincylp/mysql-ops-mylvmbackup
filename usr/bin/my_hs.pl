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
#&populate_hash("fk-hs-db");
print "\nfk-dbs\n";
&populate_hash("fk-dbs");


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
}
close F;

sleep 90;
$obj1 = new hostdbapi;
@hsdb = split("\n",$obj1->gethostoftag('fk-hs-db'));
print "\nhs is @hsdb";
foreach my $master (keys %hash)
{
$d = 0;
foreach $i ( 0 .. $#{ $hash{$master} } ) 
{
$trig_host = $hash{$master}[$i];
#$d = grep{$_== $hash{$master}[$i]} @hsdb;
if(grep(/^$trig_host/,@hsdb))
{
$d = 1;
$stat = &trigger_bkp($hash{$master}[$i]);
if($stat == 1 )
{
$logger->info("waiting: sleeping 120s");
#sleep 120;
}
last;
}
}
unless($d)
{
print "\nNo HotDb $master";
print "\n there";
push @nohs, $master;
#exit;
}
}
}
#alert();
}

sub alert {
print Dumper(%hash);
print "\nnoh is @nohs";
$aler_str = "\nHot standby missing in hostdb for below clusters. Skipping backup. Please fix.\n\n";
foreach my $master (keys %hash)
{
print "\n\n$master -> @{$hash{$master}}";
}
foreach $nohot (@nohs)
{
print "\nar is $nohot and @{ $hash{$nohot} }";
$aler_str .= $nohot . " -> ";
foreach $hs1 (@{ $hash{$nohot} })
{
$aler_str .= $hs1 . ",";
}
$aler_str .= "\n";
print "\nst is $aler_str";
push(@alert,$aler_str);

}
print "\nal is $aler_str";
system("/bin/rm /tmp/alert");
open(F1, ">/tmp/alert");
print F1 $aler_str;
close(F1);
$count = `/usr/bin/wc -l /tmp/alert |awk \'{print \$1}\'`;
chomp($count);
print "\nc is $count";
if($count > 3 )
{
#system("cat /tmp/alert |  mailx -r nagios@domain.com -s \"Skipping backup: Hot standby missing\" ops-ninjas\@domain.com,ninjas-oncall\@domain.com");
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
print "\nTrigger is $remote_host";
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
