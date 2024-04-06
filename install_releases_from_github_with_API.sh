#!/usr/bin/env bash
# shellcheck disable=SC2034
#
# #***************************************************************#
# | Author: catterdx
# | Date:   2024-01-30
# | Descr:  Installing powerful command-line tools from Github release.
# # **************************************************************#
#
# You can customize the repository path by referring to lines 21 to 30.
# This script requires the 'curl, tar, findutils' command to be installed.

# ENV
# Provide your GitHub Personal Access Tokens below
GH_PATS=Your_Token
if [ "$GH_PATS" = "Your_Token" ]; then
	echo error: ENV \'GH_PATS\' is empty. Provide your GitHub Personal Access Token and try again.
	exit 1
fi

git_repos=(
	ajeetdsouza/zoxide
	bootandy/dust
	BurntSushi/ripgrep # The binary file is named 'rg' instead of the fullname 'ripgrep'. This is a special case!
	dandavison/delta
	Peltoche/lsd
	sharkdp/bat
	sharkdp/fd
	# theryangeary/choose -- None-Standard File Naming Convention
)

# Colorful messages
Font_Red="\033[31m"
Font_Green="\033[32m"
Font_Yellow="\033[33m"
Font_Blue="\033[34m"
Font_Purple="\033[35m"
Font_SkyBlue="\033[36m"
Font_White="\033[37m"
Font_Suffix="\033[0m"

Msg_Info="${Font_Blue}[Info] ${Font_Suffix}"
Msg_Note="${Font_Purple}[Info] ${Font_Suffix}"
Msg_Warning="${Font_Yellow}[Warning] ${Font_Suffix}"
Msg_Debug="${Font_Yellow}[Debug] ${Font_Suffix}"
Msg_Error="${Font_Red}[Error] ${Font_Suffix}"
Msg_Success="${Font_Green}[Success] ${Font_Suffix}"
Msg_Failed="${Font_Red}[Failed] ${Font_Suffix}"

printf -v time_str "%(%Y%m%d_%H%M%S)T"
TMP_DIR=/tmp/install_git_release_$time_str

# trap signals
trap "TrapSig1" 1
trap "TrapSig2" 2
trap "TrapSig3" 3
trap "TrapSig15" 15

# handle signals
function TrapSig1 {
	echo -e "\n\n${Msg_Info}Caught Signal SIGHUP, Exiting ...\n"
	CleanUp 1
	exit 1
}

function TrapSig2 {
	echo -e "\n\n${Msg_Info}Caught Signal SIGINT (or Ctrl+C), Exiting ...\n"
	CleanUp 1
	exit 1
}

function TrapSig3 {
	echo -e "\n\n${Msg_Info}Caught Signal SIGQUIT, Exiting ...\n"
	CleanUp 1
	exit 1
}

function TrapSig15 {
	echo -e "\n\n${Msg_Info}Caught Signal SIGTERM, Exiting ...\n"
	CleanUp 1
	exit 1
}

function ChkOSType {
	OS="$(uname)"
	case $OS in
		Linux)
			OS='linux'
			;;
		FreeBSD)
			OS='freebsd'
			;;
		NetBSD)
			OS='netbsd'
			;;
		OpenBSD)
			OS='openbsd'
			;;
		Darwin)
			OS='darwin'
			;;
	esac

	[ "$OS" != "linux" ] && {
		echo -e "${Msg_Failed}OS($OS) not supported by this script."
		exit 1
	}

	OS_TYPE="$(uname -m)"
	case "$OS_TYPE" in
		x86_64 | amd64)
			OS_TYPE='x86_64'
			;;
		i?86 | x86)
			OS_TYPE='386'
			;;
		aarch64 | arm64)
			OS_TYPE='aarch64'
			;;
		arm*)
			OS_TYPE='arm'
			;;
	esac

	[ "$OS_TYPE" != "x86_64" ] && {
		echo -e "${Msg_Failed}OS type($OS_TYPE) not supported by this script."
		exit 1
	}
}

function MkTempDir {
	mkdir -p "$TMP_DIR" && cd "$TMP_DIR" || exit 1
}

function CleanUp {
	if [ "$1" ] && [ "$1" -eq 1 ] && [ -d "$TMP_DIR" ] && cd "$HOME"; then
		rm -rf "$TMP_DIR" && echo -e "${Msg_Info}temp file has benn cleaned." || exit 1
	elif [ -d "$TMP_DIR" ]; then
		rm -rf "$TMP_DIR" && echo -e "${Msg_Success}Finished!" || echo -e "${Msg_Failed}Can not delete $TMP_DIR, Check it manaually."
	fi
}

function IsCmdExits {
	PATH="$HOME/.local/bin:$PATH" command -v "$@" &> /dev/null || test -n "$(find "$HOME"/.local/bin -name "$@" | grep .)"
}

function InvokeGitAPI {
	project_path=$1
	curl_git_api='curl -sL -H Accept: application/vnd.github+json -H X-GitHub-Api-Version: 2022-11-28'
	git_auth_param="-H Authorization: Bearer $GH_PATS"
	git_api_url="https://api.github.com/"
	repo_path="repos/$project_path/releases/latest"
	git_api_request="$curl_git_api $git_auth_param ${git_api_url}${repo_path}"

	release_info=$(
		$git_api_request \
			| grep -E "tag_name|browser_download_url" \
			| tr -d '",' \
			| awk '{ print $NF }'
	)

	# print "latest version" and "download url"
	awk -v arch="$OS_TYPE" '/^v/ {print}; /linux-gnu/ || /linux-musl/ { if ($0 ~ arch) { print;exit} }' <<< "$release_info"
}

function GetGitRelease {
	! [ -d ~/.local/bin ] && mkdir -p ~/.local/bin

	echo -e "${Msg_Info}Searching pre-built binaries from github..."

	for repo_path in "${git_repos[@]}"; do
		if ! app_info=$(InvokeGitAPI "$repo_path"); then
			echo -e "${Msg_Warning}$repo_path failed."
			continue
		fi
		app_name=${repo_path##*/}
		if [ "$app_name" = "ripgrep" ]; then
			app_name=rg
		fi
		download_url=$(awk 'END{print $NF}' <<< "$app_info")
		latest_ver=$(awk 'NR==1' <<< "$app_info")
		prefix_ver_char=0
		if ! grep -q '^v' <<< "$latest_ver"; then
			latest_ver=$(grep -Eo '/[[:digit:]]+\.[[:digit:]]+(\.[[:digit:]])+?/' <<< "$download_url" | tr -d '/')
			prefix_ver_char=1
		fi
		if [ "$prefix_ver_char" = 1 ]; then
			latest_ver_num=$latest_ver
		else
			latest_ver_num=${latest_ver:1}
		fi
		downloaded_file=${download_url##*/}
		if IsCmdExits "$app_name"; then
			if cur_ver="$("$HOME/.local/bin/$app_name" --version 2> /dev/null)" \
				|| cur_ver="$("$HOME/.local/bin/$app_name" -v 2> /dev/null)" \
				|| cur_ver="$("$app_name" --version 2> /dev/null)" \
				|| cur_ver="$("$app_name" -v 2> /dev/null)"; then
				if grep -q "$latest_ver_num" <<< "$cur_ver"; then
					echo -e "${Msg_Success}$Font_Purple$app_name$Font_Suffix is already the lastest version($latest_ver_num)."
					continue
				fi
			fi
		fi

		echo -e "${Msg_Info}\"$app_name\"($latest_ver): $download_url\n Got it! downloading..."
		if [ "$download_url" ]; then
			curl -SfLO --progress-bar "$download_url" \
				&& tar -axf "$downloaded_file" \
				&& rm "$downloaded_file" \
				&& if InstallRelease; then echo -e "${Msg_Success}\"$app_name\"($latest_ver) installed successfully."; fi \
				|| echo -e "${Msg_Failed}: unable to download $app_name."
		else
			echo -e "${Msg_Failed}: Download URL cannot be found. -> $app_name"
		fi
	done

	if ! [[ $PATH =~ "$HOME"/\.local/bin ]]; then
		echo -e "${Msg_Warning}You should add '\$HOME/.local/bin' to env \$PATH."
	fi
}

function InstallRelease {
	mkdir -p ~/.local/share/{bash,zsh}-completion/completions || return 1
	mkdir -p ~/.local/share/man/man{1..10} || return 1
	find . -name "*ps1" -print0 | xargs -0 rm -f
	file_bin_path=$(find . -iname "$app_name" -type f | grep .)
	if [ "$file_bin_path" ]; then
		chown "${SUDO_USER:-$USER}:${SUDO_USER:-$USER}" "$file_bin_path" \
			&& chmod 0755 "$file_bin_path" \
			&& mv -f "$file_bin_path" ~/.local/bin/
	fi
	if file_man_path=$(find . -iname "${app_name}*.1" -type f | grep .) && [ -d ~/.local/share/man/man1 ] && [ "$file_man_path" ]; then
		echo "$file_man_path" | xargs chown "${SUDO_USER:-$USER}:${SUDO_USER:-$USER}" && echo "$file_man_path" | xargs -I % mv -f % ~/.local/share/man/man1/
		status=$?
		if [ $status -eq 0 ]; then
			if ! [ -f ~/.manpath ]; then
				echo 'MANDATORY_MANPATH ~/.local/share/man' > ~/.manpath
			fi
		fi
	fi

	auto_complete_path=(~/.local/share/bash-completion/completions ~/.local/share/zsh-completion/completions)
	for auto_path in "${auto_complete_path[@]}"; do
		if [ -d "$auto_path" ] && fix_name=$(grep -Eo "zsh" <<< "$auto_path"); then
			if file_cplt_path=$(find . -iname "*.$fix_name" -o -iname "*_*" -type f | grep .) && [ "$file_cplt_path" ]; then
				if [ "$fix_name" = zsh ]; then
					if find . -type f | grep -qE "autocomplete/_\w+$" | grep .; then
						chown "${SUDO_USER:-$USER}:${SUDO_USER:-$USER}" "$file_cplt_path" && chmod 0644 "$file_cplt_path"
						mv -f "$file_cplt_path" "$auto_path"
					else
						fix_prefix_name=$(basename "$file_cplt_path" | sed -E 's@(.*)(\..*)@_\1@')
						chown "${SUDO_USER:-$USER}:${SUDO_USER:-$USER}" "$file_cplt_path" && chmod 0644 "$file_cplt_path"
						mv -f "$file_cplt_path" "$auto_path"/"$fix_prefix_name"
					fi
				fi
			fi
		elif [ -d "$auto_path" ] && fix_name=$(grep -Eo "bash" <<< "$auto_path"); then
			if file_cplt_path=$(find . -iname "*.$fix_name" -type f | grep .) && [ "$file_cplt_path" ]; then
				chown "${SUDO_USER:-$USER}:${SUDO_USER:-$USER}" "$file_cplt_path" && chmod 0644 "$file_cplt_path"
				mv -f "$file_cplt_path" "$auto_path"
				continue
			fi
		fi
	done
}

# Main start
ChkOSType

commands="tar curl find"
for cmd in $commands; do
	command -v "$cmd" &> /dev/null || {
		echo -e "${Msg_Failed}Missing command: ${Font_Red}$cmd${Font_Suffix}, aborting." >&2
		exit 1
	}
done

response_code=$(curl -X GET \
	--url "https://api.github.com/octocat" \
	-H "Authorization: Bearer $GH_PATS" \
	-H "X-GitHub-Api-Version: 2022-11-28" \
	-m 3 -s -w "%{http_code}" \
	-o /dev/null)

if [ "$response_code" -ne 200 ]; then
	echo "Authenticating to the REST API went wrong."
	exit 1
fi

MkTempDir
GetGitRelease
CleanUp
