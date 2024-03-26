!#/usr/bin/env bash

IFS=$'\n'
files=($(ls ~/Music/m4a))
files_size=${#files[@]}
cd ~/Music/m4a

for (( i = 0; i < files_size; i++ ));
do
	name=${files[$i]}
	name=$(echo $name | sed 's/...$//')
	echo input ${files[$i]}
	echo output ${name}mp3
	ffmpeg -i ${files[$i]} ${name}mp3
	mv ${name}mp3 ~/Music/mp3/${name}mp3
done
