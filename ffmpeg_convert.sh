#!/usr/bin/env bash
# shellcheck disable=SC2086
# Convert the given file to given format using ffmpeg.

declare -a input_file_s
declare input_dir input_file output_folder encoder_type crf codec suffix_name ext_name
declare GLOBAL_OUTPUT_FOLDER
get_opts() {
	while getopts :d:f:o:s:t: opt; do
		case "$opt" in
			d) input_dir="$OPTARG" ;;
			f) input_file="$OPTARG" ;;
			o)
				output_folder="${OPTARG%/}"
				check_folder_can_write "$output_folder"
				GLOBAL_OUTPUT_FOLDER="$output_folder"
				;;
			s) scale="$OPTARG" ;;
			t) encoder_type="$OPTARG" ;;
			*)
				echo "Unknown option: $opt" >&2
				usage
				exit 1
				;;
		esac
	done

	shift $((OPTIND - 1))

	if [ "$input_dir" ] && [ -d "$input_dir" ]; then
		if [ -z "$output_folder" ]; then
			echo "The '-d' and '-o' options must be used together." >&2
			usage
			exit 1
		fi
		if [ "$input_file" ]; then
			echo "The '-d' option can not used with '-f' together." >&2
			usage
			exit 1
		fi
		input_dir=${input_dir%/}
		mapfile -d '' -t input_file_s < <(find "$input_dir" -maxdepth 1 -type f -print0)

		printf "=%.0s" {1..30}
		echo
		for i in "${input_file_s[@]}"; do
			ls -1 "$i"
		done
		printf "=%.0s" {1..30}
		echo

		read -n1 -rp "Proceed? "
		[[ $REPLY =~ [yY] ]] || exit 1
	fi

	for param in "$@"; do
		if [[ "$param" =~ ^- ]] || [[ "$input_file" ]]; then
			echo "Wrong: extra parameter -> $*" >&2
			usage
			exit 1
		elif [ -f "$param" ]; then
			input_file_s+=("$param")
		elif [ -d "$param" ]; then
			echo "Use the '-d' options to spefify folders." >&2
			usage
			exit 1
		else
			echo -e "Error: $param\nThis parameter is not a standard file.\n" >&2
			usage
			exit 1
		fi
	done

	case $encoder_type in
		264)
			output_file="${input_file%.*}_h264.mp4"
			ext_name=_h264.mp4
			codec=libx264
			crf=24
			;;
		265)
			output_file="${input_file%.*}_h265.mp4"
			ext_name=_h265.mp4
			codec=libx265
			crf=28
			;;
		av1)
			output_file="${input_file%.*}_av1.mp4"
			ext_name=_av1.mp4
			codec=libsvtav1
			crf=30
			;;
		*)
			suffix_name=_h264.mp4
			echo -e "Warning: Seems you did not provide an encoder type.\n"
			echo -e "Using the default: codec -> libx264, crf -> 24\n"
			# read -n1 -p "Are you sure? [y|Y]"
			# case $REPLY in
			# y | Y) ;;
			# *) return 1 ;;
			# esac
			;;
	esac

	if [ -n "$scale" ]; then
		scale_opt="-vf scale=-2:$scale"
		# else
		# scale_opt="-autoscale"
	fi
}

get_output_folder() {
	target_dest="$1"
	output_folder=$(dirname "${target_dest}")
}

check_folder_can_write() {
	if [ ! -d "$output_folder" ] || [ ! -w "$output_folder" ]; then
		echo "The output folder which your specified: <$output_folder> is not allowed." >&2
		exit 1
	fi
}

ffconvert() {
	if [ -f "$input_file" ]; then
		[ -z "$GLOBAL_OUTPUT_FOLDER" ] || get_output_folder "$input_file"
		check_folder_can_write "$output_folder"
		ffmpeg -hide_banner \
			-i "$input_file" \
			-c:v ${codec:-libx264} -crf ${crf:-24} \
			${scale_opt:- } \
			-movflags faststart \
			-c:a aac -b:a 128K \
			"${GLOBAL_OUTPUT_FOLDER:-${output_folder}}/${output_file:-${input_file%.*}}$suffix_name"
	elif [[ $(declare -p input_file_s 2> /dev/null) =~ "declare -a" && ${#input_file_s[@]} -ge 1 ]]; then
		for target_file in "${input_file_s[@]}"; do
			if [ -z "$GLOBAL_OUTPUT_FOLDER" ]; then
				get_output_folder "$target_file"
				check_folder_can_write "$output_folder"
			fi
			new_name=$(basename "${target_file}")
			new_name=${new_name%.*}
			ffmpeg -hide_banner \
				-i "$target_file" \
				-c:v ${codec:-libx264} \
				-crf ${crf:-24} \
				${scale_opt:- } \
				-movflags faststart \
				-c:a aac \
				-b:a 128K \
				"${GLOBAL_OUTPUT_FOLDER:-${output_folder}}/${new_name}$suffix_name$ext_name"
		done
	fi

}

usage() {
	echo "Usage: $0 [-f <input_file>] [-d <source_folder>] [-t <encoder_type>] [-s <scale>] [-o <output_folder>] FILE1 FILE2 ..."
	echo "Default: $0 file is equivalent to : $0 -f input_file.avi -t 264 -s 1024 -o /path/output_dir"
	echo "Example: $0 -d /source_dir -o /path/output_dir"
	echo "Example: $0 -o /path/output_dir input_file1 input_file2 ..."
	echo "Options with '-' must appear before the first path name."
}

if [ $# -lt 1 ]; then
	usage
	exit 1
fi

commands="ffmpeg find"
for cmd in $commands; do
	command -v "$cmd" &> /dev/null || {
		echo "FAIL: Missing command '$cmd', aborting." >&2
		exit 1
	}
done

get_opts "$@"
ffconvert
