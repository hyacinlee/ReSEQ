#!/usr/bin/perl -w
use strict;
my %pos;my %pos_chr;my %strand;
die "\tUsage: perl $0 < in Bed file > < in vcf file > < out vcf file >\n" unless (@ARGV==3);
#open File,"</export/personal/pengh/project/ReSequence/huasheng/ref/A.hypogaea.ctgInChr.bed";
open File,"<$ARGV[0]" or die ;
while(<File>){
	chomp;
	next if /^#/;
	my @col=split /\s+/;
	$pos{$col[0]}{$col[1]}=$col[2];
	$pos_chr{$col[0]}{$col[1]}=$col[3];
	$strand{$col[0]}{$col[1]}=$col[5];
             }
close File;

my $vcf=$ARGV[1];
open File1,"<$vcf";
open OUT,">$ARGV[2]";
while(<File1>){
	chomp;
	next if /^##/;
	if(/^#/){print $_."\n";next;}
	my @col=split /\s+/;
	my $pos;my $strand;my $chr;
	foreach my $f(keys %{$pos{$col[0]}}){
		if($col[1]>=$f&&$col[1]<=$pos{$col[0]}{$f}){
			print OUT $pos_chr{$col[0]}{$f};
			if($strand{$col[0]}{$f} eq "+"){
				$pos=$col[1]-$f+1;
            }
			else{
				$pos=$pos{$col[0]}{$f}-($col[1]+length($col[3])-1)+1;
				$col[3]=~tr/AGCTagct/TCGAtcga/;
				$col[3]=reverse $col[3];
				$col[4]=~tr/AGCTagct/TCGAtcga/;
				$col[4]=reverse $col[4];
                                                            }
			
			next;
                                                           }

                                            }
	print OUT "\t".$pos;	
	
	for(my $i=2;$i<@col;$i++){
		print OUT "\t".$col[$i];
                                 }
	print OUT "\n";
              }
close File1;
close OUT;
