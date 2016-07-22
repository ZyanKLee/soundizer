#!/bin/bash
#############################################################
# Mit diesem Skript koennen Daten in Toene gewandelt werden #
#############################################################
makenote()
{
	note=()

	# Dis-Moll-Tonleiter. Zur Demo ganze Tonleiter, aber wir nehmen hier
	# nur den Grundakkord. Umfang sind 3 Oktaven.
	for i in 2 3 4
	do
		#for n in 'D#' 'F' 'F#' 'G#' 'A#' 'B' 'D'
		for n in 'D#' 'F#' 'A#'
		do
			note+=("$n$i")
		done
	done

	echo ${note[$(($1 % ${#note[@]}))]}
} 

soundize()
{
	# Dezimaldump, Offset-Angabe rausschneiden, eine endlose Zeile
	# erzeugen, leere Zeilen löschen, dann die einzelnen Zahlenwerte
	# lesen (immer 3 auf einmal). Die gesamte Schleife wird in eine
	# einzige sox-Instanz geschoben, damit Effekte nicht auf einzelnen
	# Noten, sondern dem ganzen Stream arbeiten.
	(
		od -t u1 -v |
		sed 's/^[^ ]\+//' | tr ' ' '\n' | sed '/^$/d' |
		while read a
		do
			read b || break
			read c || break

			# Wie lang soll dieses Sample sein? Envelope-Parameter
			# hängen auch davon ab.
			lenint=$(( (a + b + c) % lenmod + lenadd ))
			lenfloat=$(echo "$lenint / $lendiv" | bc -l)
			fadeinoutfloat=$(echo "$lenfloat / 3" | bc -l)

			# Noten aus den 
			anote=$(makenote $a)
			bnote=$(makenote $b)
			cnote=$(makenote $c)
			echo "[$lenint/$lendiv] $anote $bnote $cnote" >&2
			sox -q -n $audioformat - \
				synth \
				$lenfloat $wave1 $anote \
				$lenfloat $wave2 $bnote \
				$lenfloat $wave3 $cnote \
				fade h $fadeinoutfloat $lenfloat $fadeinoutfloat \
				vol -8 dB
		done
 
		# Am Ende ein paar Sekunden Stille, damit es nicht abrupt
		# aufhört.
		sox -q -n $audioformat - synth 10 sine 100 vol 0
	) | sox -q $audioformat - $audioformat - flanger 0 9 reverb 100
} 

playsound()
{
	# Sound direkt abspielen.
	play -q $audioformat -
} 

wavesound()
{
	# Einen WAVE-Stream erzeugen, der dann umgeleitet werden kann.
	sox -q $audioformat - -t wav -
}


# sox kennt zwar ein spezielles Pipe-Format, aber das ist nicht dazu
# gedacht, dass man mehrere aufeinanderfolgende sox-Instanzen in eine
# einzige Ziel-Instanz piped. Deswegen verwenden wir hier "raw" und
# legen die Parameter selbst fest.
audioformat='-t raw -r 44100 -c 2 -e signed-integer -b 16'

# Wave-Typen und Längenvariation einstellbar.
wave1=saw
wave2=square
wave3=sine
lenmod=2
lenadd=2
lendiv=10
while getopts a:b:c:M:A:D: name
do
	case $name in
		a) wave1=$OPTARG ;;
		b) wave2=$OPTARG ;;
		c) wave3=$OPTARG ;;
		M) lenmod=$OPTARG ;;
		A) lenadd=$OPTARG ;;
		D) lendiv=$OPTARG ;;
	esac
done

if [ -t 0 ]
then
	# stdin ist ein Terminal, sorge also selbst für einen Datenstrom.
	getdata() { find / -type f -exec cat '{}' +; }
else
	getdata() { cat; }
fi

if [ -t 1 ]
then
	# stdout ist ein Terminal, also spiele es ab.
	final() { playsound; }
else
	final() { wavesound; }
fi

getdata | soundize | final
