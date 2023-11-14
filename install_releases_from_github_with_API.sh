#!/usr/bin/env bash
# shellcheck disable=SC2034
#
# #***************************************************************#
# | Author: catterdx
# | Date:   2023-11-12
# | Descr:  Installing powerful command-line tools from Github release.
# # **************************************************************#
#
# You can customize the repository path by referring to lines 183 to 190.
# This script requires the 'curl, tar' command to be installed.

# ENV
# Provide your GitHub token.
GH_TOKEN=Your_Token
if [ "$GH_TOKEN" = Your_Token ]; then
    echo error: ENV \'GH_TOKEN\' is empty. Provide your GitHub token and try again.
    exit 1
fi

command -v curl &> /dev/null || {
    echo >&2 "curl is not installed.  Aborting."
    exit 1
}
command -v tar &> /dev/null || {
    echo >&2 "tar is not installed.  Aborting."
    exit 1
}

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

TIME_START=$(date '+%Y%m%d-%H%M%S')
TMP_DIR=/tmp/init_system_dir$TIME_START

# trap signals
trap "TrapSig1" 1
trap "TrapSig2" 2
trap "TrapSig3" 3
trap "TrapSig15" 15

# handle signal 1
TrapSig1() {
    echo -e "\n\n${Msg_Info}Caught Signal SIGHUP, Exiting ...\n"
    CleanUp 1
    #kill 0
    exit 1
}

# handle signal 2 (AKA SIGINT, or Ctrl+c)
TrapSig2() {
    echo -e "\n\n${Msg_Info}Caught Signal SIGINT (or Ctrl+C), Exiting ...\n"
    CleanUp 1
    #kill 0
    exit 1
}

# handle signal 3
TrapSig3() {
    echo -e "\n\n${Msg_Info}Caught Signal SIGQUIT, Exiting ...\n"
    CleanUp 1
    #kill 0
    exit 1
}

# handle signal 15 (kill)
TrapSig15() {
    echo -e "\n\n${Msg_Info}Caught Signal SIGTERM, Exiting ...\n"
    CleanUp 1
    #kill 0
    exit 1
}

ChkOSType() {
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
            OS='osx'
            ;;
        SunOS)
            OS='solaris'
            echo -e "${Msg_Failed}OS not supported by this script."
            exit 2
            ;;
        *)
            echo -e "${Msg_Failed}OS not supported by this script."
            exit 2
            ;;
    esac

    OS_type="$(uname -m)"
    case "$OS_type" in
        x86_64 | amd64)
            OS_type='x86_64'
            ;;
        i?86 | x86)
            OS_type='386'
            ;;
        aarch64 | arm64)
            OS_type='aarch64'
            ;;
        arm*)
            OS_type='arm'
            ;;
        *)
            echo -e "${Msg_Failed}OS type not supported by this script."
            exit 2
            ;;
    esac
}

MkTempDir() {
    mkdir -p "$TMP_DIR" && cd "$TMP_DIR" || return
}

CleanUp() {
    cd ~ || return
    if [ -n "$1" ] && [ "$1" -eq 1 ] && [ -d "$TMP_DIR" ]; then
        rm -rf "$TMP_DIR" && echo -e "${Msg_Info}temp file has benn cleaned." || return 1
    elif [ -d "$TMP_DIR" ]; then
        rm -rf "$TMP_DIR" && echo -e "${Msg_Success}Finished!" || echo -e "${Msg_Failed}Can not delete $TMP_DIR, Check it manaually."
    fi
}

IsCmdExits() {
    PATH="$HOME/.local/bin:$PATH" command -v "$@" &> /dev/null || test -n "$(find "$HOME"/.local/bin -name "$@" | grep .)"
}

InvokeGitAPI() {
    response_code=$(curl -X GET \
        --url "https://api.github.com/octocat" \
        -H "Authorization: Bearer $GH_TOKEN" \
        -H "X-GitHub-Api-Version: 2022-11-28" \
        -m 3 -s -w "%{http_code}" -o /dev/null)
    if [ "$response_code" -ne 200 ]; then
        echo "Authenticating to the REST API went wrong."
        exit 1
    fi

    # shellcheck disable=SC2016
    api_command='curl -sL \
    -H "Accept: application/vnd.github+json" \
    -H "Authorization: Bearer $GH_TOKEN" \
    -H "X-GitHub-Api-Version: 2022-11-28" \
    https://api.github.com/repos/'

    release_info=$(eval "$api_command$1"/releases/latest | grep -E "tag_name|browser_download_url" |
        tr -d '",' | awk '{ print $NF }')
    # return "latest version" and "download url"
    awk -v pattern="$OS_type" '/^v/ {print}; /linux-gnu/ || /linux-musl/ { if ($0 ~ pattern) { print;exit} }' <<< "$release_info"
}

GetGitRelease() {
    if ! [ -d ~/.local/bin ]; then mkdir -p ~/.local/bin; fi

    git_repos=(
        sharkdp/bat
        sharkdp/fd
        ajeetdsouza/zoxide
        bootandy/dust
        Peltoche/lsd
        # theryangeary/choose -- None-Standard File Naming Convention
    )

    echo -e "${Msg_Info}Searching pre-built binaries from github..."

    for repo_path in "${git_repos[@]}"; do
        app_info=$(InvokeGitAPI "$repo_path")
        app_name=${repo_path##*/}
        latest_ver=$(awk 'NR==1' <<< "$app_info")
        latest_ver_num=${latest_ver:1}
        download_url=$(awk 'END{print $NF}' <<< "$app_info")
        downloaded_file=${download_url##*/}
        if IsCmdExits "$app_name"; then
            if cur_ver="$("$HOME/.local/bin/$app_name" --version 2> /dev/null)" ||
                cur_ver="$("$HOME/.local/bin/$app_name" -v 2> /dev/null)" ||
                cur_ver="$("$app_name" --version 2> /dev/null)" ||
                cur_ver="$("$app_name" -v 2> /dev/null)"; then
                if grep -q "$latest_ver_num" <<< "$cur_ver"; then
                    echo -e "${Msg_Success}$Font_Purple$app_name$Font_Suffix is already the lastest version($latest_ver_num)."
                    continue
                fi
            fi
        fi

        echo -e "${Msg_Info}\"$app_name\"($latest_ver) Got it! downloading..."
        if [ "$download_url" ]; then
            curl -SfLO --progress-bar "$download_url" &&
                tar -axf "$downloaded_file" &&
                rm "$downloaded_file" &&
                if InstallRelease; then echo -e "${Msg_Success}\"$app_name\"($latest_ver) installed successfully."; fi || echo -e "${Msg_Failed}: unable to download $app_name."
        else
            echo -e "${Msg_Failed}: Download URL cannot be found. -> $app_name"
        fi
    done
}

InstallRelease() {
    mkdir -p ~/.local/share/{bash,zsh}-completion/completions || return
    mkdir -p ~/.local/share/man/man{1..10} || return
    find . -name "*ps1" -print0 | xargs -0 rm -f
    if file_bin_path=$(find . -iname "$app_name" -type f | grep .) && [ "$file_bin_path" ]; then
        chown "${SUDO_USER:-$USER}:${SUDO_USER:-$USER}" "$file_bin_path" && chmod 0755 "$file_bin_path" && mv -f "$file_bin_path" ~/.local/bin/
    fi
    if file_man_path=$(find . -iname "${app_name}*.1" -type f | grep .) && [ -d ~/.local/share/man/man1 ] && [ "$file_man_path" ]; then
        echo "$file_man_path" | xargs chown "${SUDO_USER:-$USER}:${SUDO_USER:-$USER}" && echo "$file_man_path" | xargs -I % mv -f % ~/.local/share/man/man1/
        # shellcheck disable=SC2181
        if [ $? -eq 0 ]; then
            if ! [ -f ~/.manpath ]; then
                tee ~/.manpath <<- EOF > /dev/null
					MANDATORY_MANPATH ~/.local/share/man
				EOF
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
    return
}

ChkOSType
MkTempDir
GetGitRelease
CleanUp
