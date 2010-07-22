use JSON;
use Encode;
use Data::Dumper;
use LWP::UserAgent;
use HTTP::Request::Common qw(POST GET);
use DateTime;
use FindBin;
use strict;

# get arg
my $session_id = $ARGV[0];
my $my_id = $ARGV[1];

# global variable
my $url      = 'http://mxfarm.rekoo.com/get_api/';

chdir($FindBin::Bin);
&get_store();

my $git = "c:\\cygwin\\bin\\git.exe";
my $git_arg = "";
my $time = DateTime->now( time_zone => 'Asia/Tokyo' );
&log_and_system("$git commit store.dat -m $time $git_arg");
&log_and_system("$git commit store.enc.dat -m $time $git_arg");
&log_and_system("$git push");

sub get_store{
    my $res = makeReq(
        'method' => 'store.get',
        );
    my ($y, $m, $d) = (localtime)[5,4,3];
    $y += 1900; $m++;

    my $s = $res->content;
    $s =~ s/"server_now": [\d\.]+/"server_now": 0/;
    $s =~ s/"rekoo_killer": "\d+"/"rekoo_killer": "0"/;
    $s =~ s/"method": "store.get".*}/"method": "store.get"\n}/s;

    open my $LOG, '>', "store.dat" or die;
    print $LOG $s;
    close($LOG);

    $s=~s/\\u([0-9a-f]{4})/Encode::decode('utf-16be', pack('H4',$1))/eg;
    open my $LOG, '>', sprintf("store.enc.dat", $y, $m, $d) or die;
    print $LOG Encode::encode('utf-8', $s);
    close($LOG);
}

sub makeReq{
    my %formdata = @_;
    $formdata{'sessionid'} = $session_id;
    $formdata{'rekoo_killer'} = $my_id;
    my $req = POST($url, [%formdata]);

    my $ua = LWP::UserAgent->new('agent' => 'Mozilla/5.0 (Windows; U; Windows NT 5.1; ja; rv:1.9.1.3) Gecko/20090824 Firefox/3.5.3 (.NET CLR 3.5.30729)');
    my $res = $ua->request($req);

    &log_die($res->as_string) if $res->code ne 200;
    &log_die($res->as_string) if $res->as_string =~ /"return_code": 100/;
    return $res;
}

sub log_and_system {
    my $path = shift;
    &log("$path\n");
    system($path);
}

sub log{
    my $time = DateTime->now( time_zone => 'Asia/Tokyo' );
    my $str = shift;

    open my $LOG, '>>', "sunfarm.log" or die;
    print $LOG "$time $str";
    close($LOG);
    print "$time $str";
}

sub log_die{
    my $log = shift;
    &log($log);
    die $log;
}
