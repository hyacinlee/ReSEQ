#!/usr/bin/perl -w 
use strict;
#use lib "/export/personal/dingyw/software/common/perl/perl-5.26.1/lib/";
#use lib "/export/personal/mengmh/software/lib/man/man3/";
use lib "/export/personal/pengh/module/perl/PerlIO-gzip-0.20/lib64/perl5/";
use PerlIO::gzip; 
die "Usage: perl $0 [in deep file] [sampel name]  > [out file] \n" unless (@ARGV==2);
if($ARGV[0]=~m/.gz/){
	open IN,"<:gzip",$ARGV[0];
}
else{
	open IN,"<$ARGV[0]";
};
my $total;
my $covrage;
my $covrage5;
my $covrage10;
my $depth;
while(<IN>){
	#next if(/Dt/);
	chomp ;
	my $f=(split/\t/)[2];
	$total++;
	$covrage++ if($f>=1);
	$covrage5++ if($f>=5);	
	$covrage10++ if($f>=10);
	$depth+= $f if($f>=1);
}
my $covragebase=&Qianfenwei($covrage);
$covrage=sprintf ("%.2f",100*$covrage/$total);
$covrage5=sprintf ("%.2f",100*$covrage5/$total);
$covrage10=sprintf ("%.2f",100*$covrage10/$total);
$depth=sprintf ("%.2f",$depth/$total);

print "#Sample\tCovrage\tCovrage5x\tCovrage10x\tDepth\tCovrageBase\n";
print "$ARGV[1]\t$covrage\t$covrage5\t$covrage10\t$depth\t$covragebase\n";

sub Qianfenwei(){
	my $v = shift or return '0';
	$v =~ s/(?<=^\d)(?=(\d\d\d)+$)|(?<=^\d\d)(?=(\d\d\d)+$)|(?<=\d)(?=(\d\d\d)+\.)|(?<=\.\d\d\d)(?!$)|(?<=\G\d\d\d)(?!\.|$)/,/gx;
	return $v;
}
