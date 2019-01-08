#!/usr/bin/perl -w 
use strict;
use File::Basename qw(basename dirname);
die "\tUsage: perl $0 < fastp result dir > \n" unless (@ARGV==1);
my @f=glob "$ARGV[0]/*json";
open OUT,">$ARGV[0]/DataStat.xls";
print OUT "#\tRaw Data\t\t\t\t\tClean Data\t\t\t\t\tFilter Result\n";
print OUT "#Sample\tReads\tBase\tQ20\tQ30\tCG\tReads\tBase\tQ20\tQ30\tCG\tLow Quality\tToo Many N\tToo short\n";
foreach my $f (@f){
	my $sample=basename($f);
	$sample=~s/.json//g;
	print OUT "$sample\t";
	my @data=split/\n/,`head -26 $f`;
	foreach my $l (@data){
		next if($l=~/}|{/);
		next if($l=~/q20_bases/);
		next if($l=~/q30_bases/);
		next if($l=~/passed_filter_reads/);
		$l=~s/\s+//g;
		$l=~s/,//;
		my ($tag,$num)=split/:/,$l;
		if($tag=~/q20/ || $tag=~/q30/ || $tag=~/gc/){
			$num=sprintf("%.2f",100*$num);
		}
		else{
			$num=&Qianfenwei($num);		
		}
		print OUT "$num\t";
	
	}
	print OUT "\n";
}

sub Qianfenwei(){
	    my $v = shift or return '0';
	    $v =~ s/(?<=^\d)(?=(\d\d\d)+$)|(?<=^\d\d)(?=(\d\d\d)+$)|(?<=\d)(?=(\d\d\d)+\.)|(?<=\.\d\d\d)(?!$)|(?<=\G\d\d\d)(?!\.|$)/,/gx;
	    return $v;
}
