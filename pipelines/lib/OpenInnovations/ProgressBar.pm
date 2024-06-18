# ==============================
# Very simple progress bar

package OpenInnovations::ProgressBar;

use utf8;
use warnings;
use Data::Dumper;
binmode STDOUT, 'utf8';
binmode STDERR, 'utf8';
use List::Util qw(min);

require 'sys/ioctl.ph';


our $VERSION = '0.1';

sub new {
	my ($class, %args) = @_;
	my $pkg = caller;
	my $self = \%args;
	bless $self, $class;

	# Get terminal size
	die "no TIOCGWINSZ" unless defined &TIOCGWINSZ;
	open(TTY, "+</dev/tty") or die "No tty: $!";
	unless (ioctl(TTY, &TIOCGWINSZ, $winsize='')) {
		die sprintf "$0: ioctl TIOCGWINSZ (%08x: $!)\n", &TIOCGWINSZ;
	}
	($row, $col, $xpixel, $ypixel) = unpack('S4', $winsize);
	$self->{'row'} = $row;
	$self->{'col'} = $col;
	$self->{'value'} = 0;
	$self->{'counter'} = 0;
	$self->{'steps'} = min(100,$col-10);


	return $self;
}
sub max {
	my $self = shift;
	$self->{'max'} = shift;
	return $self;
}
sub reset {
	my $self = shift;
	$self->{'value'} = 0;
	$self->{'counter'} = 0;
	return $self;
}
sub update {
	my $self = shift;
	$t = shift;
	$self->{'value'} = $t;

	$i = int($self->{'steps'}*($t/$self->{'max'}));
	if($i > $self->{'counter'}){
		$self->{'counter'} = $i;
		if($self->{'value'} > 0){
			print STDERR "\b" x ($self->{'steps'} + 7);
		}
		print STDERR sprintf("%3d",$i)."% [";
		print STDERR "#" x $i;
		print STDERR " " x ($self->{'steps'} - $i);
		print STDERR "]";
	}
	if($i == $self->{'steps'}){
		print STDERR "\n";
	}
	
	return $self;
}
1