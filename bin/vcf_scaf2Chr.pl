#!/usr/bin/perl -w
use strict;
my %pos_start;my %pos_chr;my %strand;my %pos_end;
die "\tUsage: perl $0 < in Bed file > < in vcf file > < out vcf file > < col_contigID > <col_contigStart>\n" unless (@ARGV>=3);
#open File,"</export/personal/pengh/project/ReSequence/huasheng/ref/A.hypogaea.ctgInChr.bed";
my $col_contigID = $ARGV[3] || 4  ;
my $col_contigStart = $ARGV[4] || 6 ; 
$col_contigID --;
$col_contigStart --;

open File,"<$ARGV[0]";
while(<File>){
	chomp;
	next if /^#/;
	my @col=split /\s+/;
	$pos_start{$col[$col_contigID]}=$col[1];
	$pos_end{$col[$col_contigID]}=$col[2];
	$pos_chr{$col[$col_contigID]}=$col[0];
	$strand{$col[$col_contigID]}=$col[$col_contigStart];
             }
close File;

my $vcf=$ARGV[1];
open File1,"<$vcf";
open OUT,">$ARGV[2]";
while(<File1>){
	chomp;
	next if /^##/;
	if(/^#/){print OUT $_."\n";next;}
	my @col=split /\s+/;
	#next if (!$pos_chr{$col[0]});
	#next if($col[4] =~/,/);
	print OUT $pos_chr{$col[0]};
	my $pos;
	if($strand{$col[0]} eq "+"){
        	$pos=$pos_start{$col[0]}+$col[1]-1;
    }
	elsif($strand{$col[0]} eq "-"){
		#$pos=$pos_end{$col[0]}-($pos_start{$col[0]}+$col[1]-1)+length($col[3]);
		$pos=$pos_end{$col[0]}-$col[1]+1-length($col[3])+1;
		$col[3]=~tr/AGCTagct/TCGAtcga/;
		$col[3]=reverse $col[3];
		$col[4]=~tr/AGCTagct/TCGAtcga/;
		$col[4]=reverse $col[4];
    }
	else{
		die "cloum stand is wrong!";
	}
	print OUT "\t".$pos;	
	for(my $i=2;$i<@col;$i++){
		print OUT "\t".$col[$i];
    }
	print OUT "\n";
}
close File1;
close OUT;
