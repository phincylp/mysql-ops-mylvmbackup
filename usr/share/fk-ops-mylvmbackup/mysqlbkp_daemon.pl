#!/usr/bin/perl

use IO::Socket::INET;

# flush after every write
$| = 1;

my $my_pw = "x!qWJe8w"; 
my ($socket,$client_socket,$master_host);

my $Loc_host = `/bin/hostname -i`;
$socket = new IO::Socket::INET (
LocalHost => $Loc_host,
LocalPort => '24006',
Proto => 'tcp',
Listen => 5,
Reuse => 1
) or die "ERROR in Socket Creation : $!\n";


$client_socket = $socket->accept();
my $data = <$client_socket>;
if($data =~ m/\bSTAT\b/i )
{
my $slave = `/usr/bin/mysql -u ops -p$my_pw -e \"show slave status \\\G\" |grep Running | grep Slave |grep Yes |wc -l`;
chomp($slave);
if($slave > 0)
{
$master_host=`/usr/bin/mysql -u ops -p$my_pw -e \"show slave status \\\G \" |grep Master_Host | awk -F: '{print \$NF}'`;
$master_host =~ s/^\s+|\s+$//go ;
unless($master_host =~ /[a-z]/i )
{
 $master_host = gethostbyaddr(inet_aton($master_host), AF_INET);
}
$master_host =~ s/.nm.domain.com//g;
$master_host =~ s/.ch.domain.com//g;

print $client_socket "master: $master_host\n";
}
else
{
print $client_socket "master\n";
}
}
elsif($data =~ m/\bBKP\b/i )
{
chk_bkp();
system("/bin/bash /usr/bin/stop_bkp.sh");
system("/usr/bin/perl /usr/bin/fk-mylvmbackup --configfile=/etc/fk-mylvmbackup.conf &");
print $client_socket "mysql backup started\n";
$socket->close();
exit;
}
##########Added by Phincy#######
        elsif($data =~ /10./ )
                {
#                chk_bkp();
                # example $database_to_exclude == "cssdb:payment"
                my ($action, $target_host, $database_to_exclude) = split(',', $data);
#                print $client_socket    "Action is $action";
#                print $client_socket "Target is $target_host";
                system("/usr/share/fk-ops-mylvmbackup/artifactory/build-conf.sh", "$target_host", "$database_to_exclude");
                        if ( $? != 0 )
                        {
                        print $client_socket "error: Configuration build failed";
                        $socket->close();
                        exit;
                        }
                        else
                        {
#                        print $client_socket "Configuration build successful, ";
                        system("/usr/bin/stop_bkp.sh");
                        system("/usr/bin/perl /usr/bin/fk-mylvmmigrate --configfile=/etc/fk-mysql-migrate.conf &");
                        print $client_socket "started";
                        $socket->close();
                        exit;
                        }

                }

        elsif($data =~ /domain.com/ )
                {
#               chk_bkp();
                my ($action, $target_host, $database_to_exclude) = split(',', $data);
#                print $client_socket    "Action is $action";
#                print $client_socket "Target is $target_host";
                system("/usr/share/fk-ops-mylvmbackup/artifactory/build-conf.sh", "$target_host", "$database_to_exclude");
                        if ( $? != 0 )
                        {
                        print $client_socket "error: Configuration build failed";
                        $socket->close();
                        exit;
                        }
                        else
                        {
#                        print $client_socket "Configuration build successful, ";
                        system("/usr/bin/stop_bkp.sh");
                        system("/usr/bin/perl /usr/bin/fk-mylvmmigrate --configfile=/etc/fk-mysql-migrate.conf &");
                        print $client_socket "started";
                        $socket->close();
                        exit;
                        }

                }

################################





elsif($data =~ m/\bSTATUS\b/i )
{
my $lftp = `ps auxw |grep lftp|grep -v grep |wc -l `;
if($lftp > 0 )
{
print $client_socket "lftp runnning\n";
$socket->close();
exit;
}
chk_bkp();
print $client_socket "err: not runnning\n";
$socket->close();
exit;
}
else
{
print $client_socket "invalid cmd\n";
$socket->close();
exit;
}


sub chk_bkp()
{
my $pstat = `ps auxw |grep fk-mylvmbackup|grep -v grep |wc -l `;
my $df = `/sbin/lvdisplay |grep snapshot |grep dev`;
if( $pstat > 0 )
{
print $client_socket "another instance already running\n";
$socket->close();
exit;
}
elsif($df > 0 )
{
print $client_socket "snapshot already mounted\n";
$socket->close();
exit;
}
return 1;
}

