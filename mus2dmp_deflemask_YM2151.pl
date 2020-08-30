#!/usr/bin/perl
#--------------------------------------------------------------------
# X68000のmusファイルの音色データを
# DefleMaskのdmpフォーマットに変換しファイル出力するスクリプト
# mdxからmusへの変換はtmdx2musを使ってます。
#
# https://nfggames.com/X68000/Mirrors/x68pub/x68tools/SOUND/MXDRV/TMDX2MUS.LZH
# https://deflemask.com/DMP_SPECS.txt
#--------------------------------------------------------------------
#DMP format
#	1 Byte:   FILE_VERSION, must be 11 (0x0B) for DefleMask v0.12.0
#	1 Byte:  System:
#	1 Byte:   Instrument Mode (1=FM, 0=STANDARD)
#		//IF INSTRUMENT MODE IS FM ( = 1)
#			1 Byte: LFO (FMS on YM2612, PMS on YM2151)
#			1 Byte: FB
#			1 Byte: ALG(CON)
#			1 Byte: LFO2 (AMS on YM2612, AMS on YM2151)
#
#			Repeat this TOTAL_OPERATORS times
#				1 Byte: MULT
#				1 Byte: TL(OL)
#				1 Byte: AR
#				1 Byte: DR
#				1 Byte: SL
#				1 Byte: RR
#				1 Byte: AM(AME)
#				1 Byte: RS(KS)
#				1 Byte: DT (DT2<<4 | DT on YM2151)
#				1 Byte: D2R(SR)
#				1 Byte: SSGEG_Enabled <<3 | SSGEG
#
#	FILE_VERSION/system/mode/OP1/OP3/OP2/OP4	 51(3+4+11x4)byte
#
#--------------------------------------------------------------------
#YM2151 mus format
# @N = {
#    AR, DR, SR, RR, SL, OL, KS, ML,DT1,DT2,AME, ;オペレータ1用
#    AR, DR, SR, RR, SL, OL, KS, ML,DT1,DT2,AME, ;オペレータ2用
#    AR, DR, SR, RR, SL, OL, KS, ML,DT1,DT2,AME, ;オペレータ3用
#    AR, DR, SR, RR, SL, OL, KS, ML,DT1,DT2,AME, ;オペレータ4用
#   CON, FL, OP
#}
#--------------------------------------------------------------------

use File::Basename;

#引数で指定したファイルを読み込む
unless (@ARGV[0]) {
	print "usage: $0 \[file.mus\]\n";
	exit 0;
}

my $musfile = @ARGV[0];
my ($base,$dir,$suf) = fileparse($musfile, ".mus");

#ファイルから音色データを見つけて、配列に格納する(音色番号とデータ47個)
open(MUS, '<', $musfile)
  or die "Can't open $musfile:$!";

while(my $line = <MUS>) {
	if ($line =~ /^@/) {
		$line .= <MUS>;
		$line .= <MUS>;
		$line .= <MUS>;
		$line .= <MUS>;
		$line =~ s/(\r\n|\r|\n|\s)//g; 		# 改行コード除去
		print "$line\n";
		if ($line =~ /(\d+)\=\{(.+)\}/) { 
			my $dmpfile = "$base"."_"."$1.dmp";			# ファイル名作成	
			my @pgm = split(/,/,$2);		# パラメータを配列に格納

#配列を出力順に並び替える
			my @out = ();
			push(@out,12);		# deflemask ver 0.12 = 12
			push(@out,8);		# ym2151=8
			push(@out,1);		# FM=1

			push(@out,0);			# LFO(AMS)
			push(@out,@pgm[45]);	# FB
			push(@out,@pgm[44]);	# CON(ALG)
			push(@out,0);			# LFO(PMS)

			foreach my $op (0,2,1,3) {		# OPの並び
				push(@out,@pgm[$op*11+7]);	# MULTI
				push(@out,@pgm[$op*11+5]);	# TL(OL)
				push(@out,@pgm[$op*11+0]);	# AR
				push(@out,@pgm[$op*11+1]);	# D
				push(@out,@pgm[$op*11+4]);	# S
				push(@out,@pgm[$op*11+3]);	# R
				push(@out,@pgm[$op*11+10]);	# AME
				push(@out,@pgm[$op*11+6]);	# RS(KS)
				push(@out,@pgm[$op*11+9]<<4+@pgm[$op*11+8]);	# DT2+DT
				push(@out,@pgm[$op*11+2]);	# SR
				push(@out,0);				# SSGEG(not use)
			}

			print "$dmpfile : @out\n";
			my $length = @out;
#			print "$length\n";

			#バイナリデータを出力する
			open(OUT, '>', $dmpfile)
			  or die "Can't open $dmpfile:$!";

			# バイナリモードに変更
			binmode OUT;

			# バイナリデータを書き込み
			my $buf = pack("c51",@out);
			print(OUT $buf);

			# ファイルをクローズ
			close OUT;
		}
	}
}
exit 0;
