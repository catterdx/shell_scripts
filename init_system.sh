#!/usr/bin/env bash
#
# #***************************************************************#
# | Author: catterdx
# | Date:   2024-03-09
# | Descr:  init system: zsh, zsh plugins, .vimrc, powerfull modern utils(lsd fd bat. etc..).
# # **************************************************************#
#

VIMRC_GIT="https://raw.githubusercontent.com/amix/vimrc/master/vimrcs/basic.vim"

VIMRC_THEME_GIT="https://github.com/dracula/vim.git"

OMZ_INSTALL_SH="https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh"

ZSH_PLUGINS=(https://github.com/zsh-users/zsh-autosuggestions
	https://github.com/zsh-users/zsh-completions
	https://github.com/zsh-users/zsh-syntax-highlighting
	https://github.com/zsh-users/zsh-history-substring-search
	https://github.com/MichaelAquilina/zsh-you-should-use)

GIT_APPS=(https://github.com/sharkdp/bat
	https://github.com/sharkdp/fd
	https://github.com/ajeetdsouza/zoxide
	https://github.com/bootandy/dust
	https://github.com/Peltoche/lsd)

RPM_PRE_PKGS=(langpacks-en dnf-plugins-core epel-release epel-next-release)

RPM_PKGS=(langpacks-en man-db man-pages wget findutils vim-enhanced virt-what
	zsh bash-completion git tree tar unzip gzip zip bzip2 xz bc dos2unix
	iotop htop iftop tmux screen nmap-ncat net-tools util-linux-user
	python38 bind-utils iperf3 gcc)

# iperf3 pops up an extra prompt, so I rip it.
DEB_PKGS=(passwd language-pack-en man-db manpages wget findutils zsh bash-completion git virt-what
	tar unzip zip gzip bzip2 xz-utils tree net-tools nmap mtr vim bind9-dnsutils
	iftop htop iotop screen tmux dos2unix bc python3-pip python3-dev)

# The variable 'USER' is not defined within docker and podman linux-dist images.
command -v id &> /dev/null && [[ $(id -un) = root ]] && USER=${USER:-root}

TIME_START=$(date '+%Y%m%d-%H%M%S')
TMP_DIR=/tmp/init_system_dir$TIME_START
Font_Red="\033[31m"
Font_Green="\033[32m"
Font_Yellow="\033[33m"
Font_Blue="\033[34m"
Font_Purple="\033[35m"
Font_SkyBlue="\033[36m"
Font_White="\033[37m"
Font_Suffix="\033[0m"
Msg_Info="${Font_Blue}[Info] $Font_Suffix"
Msg_Note="${Font_Purple}[Info] $Font_Suffix"
Msg_Warning="${Font_Yellow}[Warning] $Font_Suffix"
Msg_Debug="${Font_Yellow}[Debug] $Font_Suffix"
Msg_Error="${Font_Red}[Error] $Font_Suffix"
Msg_Success="${Font_Green}[Success] $Font_Suffix"
Msg_Failed="${Font_Red}[Failed] $Font_Suffix"

SetupColor() {
	if ! IsTTY; then
		FMT_RAINBOW=""
		FMT_RED=""
		FMT_GREEN=""
		FMT_YELLOW=""
		FMT_BLUE=""
		FMT_BOLD=""
		FMT_RESET=""
		return
	fi
	if IsTrueCol; then
		FMT_RAINBOW="
                $(printf '\033[38;2;255;0;0m')
                $(printf '\033[38;2;255;97;0m')
                $(printf '\033[38;2;247;255;0m')
                $(printf '\033[38;2;0;255;30m')
                $(printf '\033[38;2;77;0;255m')
                $(printf '\033[38;2;168;0;255m')
                $(printf '\033[38;2;245;0;172m')
                "
	else
		FMT_RAINBOW="
                $(printf '\033[38;5;196m')
                $(printf '\033[38;5;202m')
                $(printf '\033[38;5;226m')
                $(printf '\033[38;5;082m')
                $(printf '\033[38;5;021m')
                $(printf '\033[38;5;093m')
                $(printf '\033[38;5;163m')
                "
	fi
	FMT_RED=$(printf '\033[31m')
	FMT_GREEN=$(printf '\033[32m')
	FMT_YELLOW=$(printf '\033[33m')
	FMT_BLUE=$(printf '\033[34m')
	FMT_BOLD=$(printf '\033[1m')
	FMT_RESET=$(printf '\033[0m')
}

trap "TrapSig1" 1
trap "TrapSig2" 2
trap "TrapSig3" 3
trap "TrapSig15" 15

TrapSig1() {
	echo -e "\n\n${Msg_Info}Caught Signal SIGHUP, Exiting ...\n"
	CleanUp 1
	exit 1
}

TrapSig2() {
	echo -e "\n\n${Msg_Info}Caught Signal SIGINT (or Ctrl+C), Exiting ...\n"
	CleanUp 1
	exit 1
}

TrapSig3() {
	echo -e "\n\n${Msg_Info}Caught Signal SIGQUIT, Exiting ...\n"
	CleanUp 1
	exit 1
}

TrapSig15() {
	echo -e "\n\n${Msg_Info}Caught Signal SIGTERM, Exiting ...\n"
	CleanUp 1
	exit 1
}

IsTrueCol() {
	case "$COLORTERM" in
		truecolor | 24bit) return 0 ;;
	esac
	case "$TERM" in
		iterm | \
			tmux-truecolor | \
			linux-truecolor | \
			xterm-truecolor | \
			screen-truecolor) return 0 ;;
	esac
	return 1
}

CleanUp() {
	if [ "$1" ] && [ "$1" -eq 1 ] && [ -d "$TMP_DIR" ] && cd "$HOME"; then
		rm -rf "$TMP_DIR" && echo -e "${Msg_Info}temp file has been cleaned."
	elif [ -d "$TMP_DIR" ]; then
		rm -rf "$TMP_DIR" && echo -e "${Msg_Success}Finished!" || echo -e "${Msg_Failed}Can not delete $TMP_DIR, Check it manaually."
	fi
}

SetRealHome() {
	if [ "$USER" = "root" ] && [ "$SUDO_USER" = "root" ]; then
		export real_home='/root'
		export HOME=$real_home
	elif [ "$SUDO_USER" ]; then
		real_home=$(sudo -u "$SUDO_USER" bash -c 'echo $HOME')
		export HOME=$real_home
		set_sudo_conf=1
		# if [ "$HOME" = /root ]; then
		#   echo -e "${Msg_Warning}Several pre-build binaries will be installed into the home directory, located at:"
		#   echo -e "\n========>\t$HOME/.local/bin\n"
		#   echo -e "${Msg_Warning}Current user is $Font_Purple$SUDO_USER$Font_Suffix, Are you sure?\n"
		#   echo -e "You can enter 'c' to change to HOME environment to $real_home."
		#   echo -e "info: Proceed with $Font_Purple$HOME$Font_Suffix [yY]"
		#   if [ "$SUDO_USER" != "root" ]; then
		#     echo -e "info: Change into  $Font_Purple$real_home$Font_Suffix [cC]"
		#   fi
		#   echo -e "info: Cancel installation [qQ]"
		#   while [ -z "$very_important" ]; do
		#     read -rp "> " very_important
		#     case $very_important in
		#       y | Y) ;;
		#       c | C)
		#         export HOME=$real_home
		#         set_sudo_conf=1
		#         ;;
		#       q | Q) exit 1 ;;
		#       *)
		#         echo -e "${Msg_Info}acceptable value: 'y' 'c' 'q'"
		#         unset very_important
		#         ;;
		#     esac
		#   done
		# fi
	else
		export real_home="$HOME"
	fi
}

SetSudoConf() {
	[ "$set_sudo_conf" ] || return
	sudo_conf=/etc/sudoers.d/$SUDO_USER
	stamp_time_out=360
	if ! [ -e "$sudo_conf" ]; then
		tee /etc/sudoers.d/"$SUDO_USER" <<- EOF > /dev/null
			Defaults timestamp_timeout=$stamp_time_out
		EOF
		if [ -s "$sudo_conf" ]; then
			chmod 0644 /etc/sudoers.d/"$SUDO_USER"
			echo -e "${Msg_Success}Set sudo conf for $SUDO_USER successfully."
		fi
	fi
}

ChgTimeZone() {
	if [ -f /etc/localtime ] && [ -d /usr/share/zoneinfo/ ]; then
		rm -f /etc/localtime
		ln -s /usr/share/zoneinfo/Asia/Shanghai /etc/localtime
	fi
}

MkTempDir() {
	{ mkdir -p "$TMP_DIR" && cd "$TMP_DIR"; } || {
		echo "${Msg_Failed}Can not Make tmp dir."
		exit 1
	}
}

ChkDist() {
	local cmd
	cmd="cat /etc/os-release"
	if $cmd | grep -Eqi "debian"; then
		os_release="debian"
	elif $cmd | grep -Eqi "ubuntu"; then
		os_release="ubuntu"
	elif $cmd | grep -Eqi "centos|rocky|almalinux|fedora"; then
		os_release="centos"
	else
		. /etc/os-release
		os_release="$NAME"
	fi
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

ChgEthName() {
	FILE_PATH=/etc/systemd/network/
	FILE_NAME=70-custom-ifnames.link
	MAC=$(ip link show | grep link/ether | awk '{print $2}')
	mkdir -p $FILE_PATH && cat > $FILE_PATH$FILE_NAME <<- EOF
		[Match]
		MACAddress=$MAC

		[Link]
		Name=eth0
	EOF
}

CmdExists() {
	PATH="$real_home/.local/bin:$PATH" command -v "$@" &> /dev/null || test -n "$(find "$real_home"/.local/bin -name "$@" | grep .)"
}

ChkPM() {
	local status
	if [ "$os_release" = "centos" ]; then
		if CmdExists dnf; then
			pkg_manager=dnf
		else
			status=1
		fi
	elif [ "$os_release" = ubuntu ] || [ "$os_release" = debian ]; then
		if CmdExists apt; then
			pkg_manager=apt
		else
			status=1
		fi
	else
		status=1
	fi
	if [ "$status" ]; then
		echo -e "${Msg_Error}Package manager command ${Font_Yellow}$pkg_manager${Font_Suffix} not found."
		echo -e "${Msg_Info}Your current os is: ${Font_Yellow}$os_release${Font_Suffix}, supporting OS: CentOS 8+, RockyLinux, AlmaLinux, Ubuntu 14.04+, Debian 8+"
		exit 1
	fi
}

RPMInPkgs() {
	echo -e "${Msg_Info}Updating dnf repo..."
	dnf update -y
	echo -e "${Msg_Info}Checking epel package..."
	if ! grep -q "ID=fedora" /etc/os-release; then
		for pre_pack in "${RPM_PRE_PKGS[@]}"; do
			if rpm -q --quiet "$pre_pack"; then
				continue
			elif rpm -q "$pre_pack" |& grep -qi "is not"; then
				echo -e "${Msg_Info}Installing $pre_pack package..."
				dnf -qy install "$pre_pack" && echo -e "$Msg_Success$pre_pack installed successfully."
			else
				echo -e "$Msg_Failed"
				echo -e "${Msg_Info}epel or epel-next package can not be installed."
				exit 1
			fi
		done
	fi
	if dnf repolist all | grep -q crb; then
		dnf config-manager --set-enabled crb
	elif dnf repolist all | grep -q powertools; then
		dnf config-manager --set-enabled powertools
	fi
	if [ -f /etc/yum.repos.d/rocky.repo ]; then
		if ! grep -q "edu\.cn" /etc/yum.repos.d/rocky*.repo; then
			while [ -z "$ch_mirror" ]; do
				read -rp "Optimize repositories?(y|n) " is_desired
				case $is_desired in
					[yY] | [yY][eE][sS])
						ch_mirror=1
						;;
					[nN] | [nN][oO])
						ch_mirror=0
						;;
					*) echo -e "${Msg_Info}acceptable values: Y,y,Yes,yes,YES,N,n,NO,No,no" ;;
				esac
			done
			if [ "$ch_mirror" -eq 1 ]; then
				sed -e 's|^mirrorlist=|#mirrorlist=|g' \
					-e 's|^#baseurl=http://dl.rockylinux.org/$contentdir|baseurl=https://mirror.nju.edu.cn/rocky|g' \
					-e 's|^name=Rocky Linux|name=Rocky Linux(NJ Edu)|' \
					-i.bak \
					/etc/yum.repos.d/rocky*.repo
				sed -e 's|^metalink=|#metalink=|g' \
					-e 's|^#baseurl=https://download.example/pub|baseurl=https://mirrors.tuna.tsinghua.edu.cn|g' \
					-e 's|^name=Extra Packages for Enterprise Linux|name=Extra Packages for Enterprise Linux(Tsinghua Edu)|' \
					-i.bak \
					/etc/yum.repos.d/epel{,-next,-testing,-next-testing}.repo
			fi
		fi
	fi
	echo -e "${Msg_Info}Building DNF cache..."
	dnf clean all &> /dev/null
	dnf makecache
	echo -e "${Msg_Info}Installing desired packages..."
	for rpm_pack in "${RPM_PKGS[@]}"; do
		if rpm -q --quiet "$rpm_pack"; then
			echo -e "${Msg_Info}Package: $Font_Purple$rpm_pack$Font_Suffix is already installed."
			continue
		elif rpm -q "$rpm_pack" |& grep -qi "is not"; then
			echo -e "${Msg_Info}Installing $rpm_pack package..."
			dnf install --allowerasing -qy "$rpm_pack"
			if [ "$rpm_pack" = vim ]; then continue; fi
			if ! rpm -q --quiet "$rpm_pack"; then
				if dnf -C list --available "$rpm_pack" |& grep -qi "no match"; then
					echo -e "$Msg_Failed"
					echo -e "${Msg_Info}Package: $rpm_pack can not be found in your DNF repositories" | sudo -u "${SUDO_USER:-$USER}" tee -a ~/fail.log
				else
					echo -e "$Msg_Success$rpm_pack installed successfully."
				fi
			fi
		else
			echo -e "$Msg_Failed"
			echo -e "${Msg_Info}Package: $rpm_pack can not be installed." | sudo -u "${SUDO_USER:-$USER}" tee -a ~/fail.log
		fi
	done
	echo -e "${Msg_Success}Dnf task done."
	dnf alias add b='--disablerepo="*" --enablerepo=extras --enablerepo=baseos --enablerepo=appstream' &> /dev/null
}

DEBInPkgs() {
	echo -e "${Msg_Info}Updating apt repo..."
	apt update
	echo -e "${Msg_Info}Installing desired packages..."
	for deb_pack in "${DEB_PKGS[@]}"; do
		[[ $deb_pack == "language-pack-en" ]] && [[ $os_release = "debian" ]] && continue
		if dpkg -s "$deb_pack" | grep -qi "installed"; then
			echo -e "${Msg_Info}Package: $Font_Purple$deb_pack$Font_Suffix is already installed."
			continue
		elif dpkg -s "$deb_pack" |& grep -Eqi "deinstall|not installed" &> /dev/null; then
			apt install -qy "$deb_pack" && echo -e "$Msg_Success$Font_Purple$deb_pack$Font_Suffix installed successfully."
			if ! dpkg -s "$deb_pack" &> /dev/null; then
				echo -e "$Msg_Failed"
				echo -e "${Msg_Info}Package: $deb_pack can not be installed." | tee -a ~/fail.log
			fi
		else
			echo -e "$Msg_Failed"
			echo -e "${Msg_Info}Package: $deb_pack can not be installed." | tee -a ~/fail.log
		fi
	done
	echo -e "${Msg_Success}Apt task done."
}

InstallPkgs() {
	if [[ "$pkg_manager" = "dnf" ]]; then
		RPMInPkgs
	elif [[ "$pkg_manager" = "apt" ]]; then
		DEBInPkgs
	fi
}

PipPacks() {
	local status
	echo -e "${Msg_Info}Verifying pip packages..."
	if CmdExists pip3; then
		py_pkgs=(thefuck tldr)
		for py_pack in "${py_pkgs[@]}"; do
			if sudo -i -u "${SUDO_USER:-$USER}" pip3 show -q "$py_pack"; then
				echo -e "$Msg_Info$Font_Purple$py_pack$Font_Suffix is already installed."
				continue
			else
				echo -e "${Msg_Info}Installing $py_pack ..."
				if [ "$os_release" = "debian" ]; then
					apt install -qy "$py_pack"
					status=$?
				else
					sudo -i -u "${SUDO_USER:-$USER}" pip3 -q install --user "$py_pack"
					status=$?
				fi
				if [ "$status" -eq 0 ]; then
					echo -e "${Msg_Success}python util: $Font_Purple$py_pack$Font_Suffix installed successfully."
				else
					echo -e "$Msg_Failed\"$py_pack\" can not be installed "
				fi
			fi
		done
		echo -e "${Msg_Success}Pip task done."
	fi
}

InstallOhMyZsh() {
	if ! [ -d ~/.oh-my-zsh ]; then
		curl -fsSL "$OMZ_INSTALL_SH" | sudo -u "${SUDO_USER:-$USER}" bash > /dev/null
		omz_dir_exists=1
	fi
}

SetupZsh() {
	if [ "$omz_dir_exists" = 1 ] || ! grep -q "${SUDO_USER-$USER}"'.*zsh$' /etc/passwd; then
		echo -e "${Msg_Info}Installer called from a subshell will not change the default shell."
		echo -e "${Msg_Info}Installer called from a subshell will not run zsh after the install."
		echo -e "${Msg_Info}Do you want to change your default shell to zsh? [Y/n]"
		read -r opt
		case $opt in
			y* | Y* | "") ;;
			n* | N*)
				echo -e "${Msg_Info}Modify the default shell skipped."
				return
				;;
			*)
				echo -e "${Msg_Warning}Invalid choice. Modify the default shell skipped."
				return
				;;
		esac
		if zsh=$(command -v zsh); then
			if CmdExists chsh; then
				sudo -k chsh -s "$zsh" "${SUDO_USER:-$USER}"
			else
				chsh -s "$zsh" "${SUDO_USER:-$USER}"
			fi
			if ! grep -q "${SUDO_USER:-$USER}"'.*zsh' /etc/passwd; then
				echo -e "$Msg_Failed: Change your default shell manually."
			else
				export SHELL="$zsh"
				echo -e "${Msg_Success}successfully changed login shell to '$zsh'"
				PrintSuccess
				exec sudo -i -u "${SUDO_USER:-$USER}" zsh -l
			fi
		else
			echo -e "$Msg_Failed can no find zsh binary"
			exit 1
		fi
	fi
}

ZshPlugins() {
	if ! [ -d ~/.oh-my-zsh/custom/plugins/you-should-use ]; then
		zsh_dir=${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/
		for plugin in "${ZSH_PLUGINS[@]}"; do
			suffix_dir=$(echo "$plugin" | awk -F/ '{print $NF}')
			if [ "$suffix_dir" = zsh-you-should-use ]; then
				suffix_dir="you-should-use"
				echo -e "${Msg_Info}cloning omzsh plugin: $Font_Purple$suffix_dir$Font_Suffix..."
				sudo -u "${SUDO_USER:-$USER}" git clone --progress --depth=1 "$plugin" "$zsh_dir$suffix_dir"
			else
				echo -e "${Msg_Info}cloning omzsh plugin: $Font_Purple$suffix_dir$Font_Suffix..."
				sudo -u "${SUDO_USER:-$USER}" git clone --progress --depth=1 "$plugin" "$zsh_dir$suffix_dir"
			fi
		done
		echo -e "${Msg_Success}omz plugins task done."
	fi
}

ModifyZshRC() {
	if [ -f ~/.zshrc ]; then
		if grep -qi "Custom lines start" ~/.zshrc; then
			:
		else
			sed -i '/^plugins=/c \plugins=( git tmux screen zsh-autosuggestions you-should-use zsh-completions zsh-history-substring-search zsh-syntax-highlighting )' ~/.zshrc
			cat >> ~/.zshrc <<- 'EOF'
				# Custom lines start

				# term color conf start
				case "$TERM" in
				xterm||*kitty)
				export TERM=xterm-256color
				;;
				screen)
				export TERM=screen-256color
				;;
				esac
				# end term color conf

				# custom prompt start
				#local ret_status="%(?:%{$fg_bold[green]%}➜ :%{$fg_bold[red]%}➜ )"
				#PROMPT='${ret_status} %{$fg[cyan]%}%c%{$reset_color%} $(git_prompt_info)'
				#RPROMPT="%{$fg[magenta]%}[%D{%m/%f/%y}|%*]%{$reset_color%}"
				# end custom prompt

				# custom env start
				export EDITOR=vim
				export HIST_STAMPS="dd.mm.yyyy"
				#export HISTTIMEFORMAT='%d/%m %T '
				export _ZO_ECHO=1
				export LANG=en_US.UTF-8
				#export MANPATH="~/.local/share/man:$(manpath -g)"
				export PATH="$HOME/.local/bin:$PATH"
				export ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE="fg=8,bg=236,dim,standout"
				#MANROFFOPT="-c"
				#export MANPAGER="sh -c 'col -bx | bat -l man -p'"
				# end custom env end

				# custom alias start
				alias cat='bat -pp --tabs 4 --theme Dracula'
				alias sc='sudo cat'
				alias sb='sudo bash'
				alias sv='sudoedit'
				alias pstree='pstree -p'
				alias man='batman'
				alias h='history -f'
				alias l='lsd -a --permission octal --sort time --blocks=permission,user,group,links,size,name'
				alias l.="lsd -dl --group-directories-first .[!.]* 2>/dev/null || echo No hidden file in current directory."
				alias ls='lsd --hyperlink auto'
				alias ll='lsd -lAF --group-directories-first --sort time'
				alias lf="lsd -dl */ 2>/dev/null || echo No folder in current directory."
				alias lt='lsd -a --tree --depth 2 --icon never'
				alias cltmp='rm ~/tmp/* -rf;rm ~/tmp/.* -rf'
				alias vimzrc='vim $HOME/.zshrc'
				alias vimrc='vim $HOME/.bashrc'
				# end custom alias

				# eval conf start
				eval "$(thefuck --alias)"
				eval "$(zoxide init --cmd cd zsh)"
				# end eval conf omz

				autoload -Uz compinit && compinit -u

				# bindkey start
				bindkey '^[f' autosuggest-accept
				bindkey '^[p' history-substring-search-up
				bindkey '^[n' history-substring-search-down
				# end bindkey

				# End custom lines
			EOF
		fi
		chown -R "${SUDO_USER:-$USER}:${SUDO_USER:-$USER}" ~/.zshrc
	fi
}

ModifyVimRC() {
	[ -d ~/.SpaceVim ] && return 0
	if [ -f ~/.vimrc ] && ! [ -d ~/.vim ]; then
		if ! grep -Eq "Custom" ~/.vimrc; then
			rm -f ~/.vimrc
			sudo -u "${SUDO_USER:-$USER}" mkdir -p ~/.vim/pack/themes/start || return
			git clone "$VIMRC_THEME_GIT" ~/.vim/pack/themes/start/dracula && echo -e "${Msg_Success}Dracula theme for vim OK!"
			curl -sSfL "$VIMRC_GIT" > ~/.vimrc && echo -e "$Msg_Success.vimrc replaced!"
			sed -i '$a \packadd! dracula\nset background=dark\ncolorscheme dracula' ~/.vimrc
		fi
	elif ! [ -f ~/.vimrc ]; then
		sudo -u "${SUDO_USER:-$USER}" mkdir -p ~/.vim/pack/themes/start || return
		git clone "$VIMRC_THEME_GIT" ~/.vim/pack/themes/start/dracula && echo -e "${Msg_Success}Dracula theme for vim OK!"
		curl -sSfL "$VIMRC_GIT" > ~/.vimrc && echo -e "$Msg_Success.vimrc replaced!"
		sed -i '$a \packadd! dracula\nset background=dark\ncolorscheme dracula' ~/.vimrc
	fi
	chown "${SUDO_USER:-$USER}:${SUDO_USER:-$USER}" ~/.vimrc
	chown -R "${SUDO_USER:-$USER}:${SUDO_USER:-$USER}" ~/.vim
}

Is404() {
	curl -m 3 -s -w "%{http_code}" -o /dev/null "$1" | grep -q "404"
}

Proxy() {
	export hostip
	hostip=$(grep -oP '(?<=nameserver\ ).*' /etc/resolv.conf)
	export https_proxy="http://$hostip:7890"
	export http_proxy="http://$hostip:7890"
	export all_proxy="sock5://$hostip:7891"
	sudo -i -u "${SUDO_USER:-$USER}" git config --global http.proxy "$hostip:7890"
	sudo -i -u "${SUDO_USER:-$USER}" git config --global https.proxy "$hostip:7890"
	echo "HTTP Proxy on: $hostip"
}

NoProxy() {
	unset http_proxy
	unset https_proxy
	unset all_proxy
	git config --global --unset http.proxy
	git config --global --unset https.proxy
	echo "HTTP Proxy off"
}

UpdateApps() {
	if ! [ -d ~/.local/bin ]; then sudo -u "${SUDO_USER:-$USER}" mkdir -p ~/.local/bin; fi
	echo -e "${Msg_Info}Searching pre-built binaries from github..."
	# if ! curl -o /dev/null https://github.com &> /dev/null; then
	#   Proxy
	#   proxy_flag=1
	# fi
	for git_app in "${GIT_APPS[@]}"; do
		app_name=${git_app##*/}
		latest_ver=$(curl -ILs "$git_app/releases/latest" | grep -EA 10 '302 ?'$(printf $'\r\n') | grep "location:" | awk -F/ '{ gsub(/\r/, "");printf $NF}')
		latest_ver_tr=${latest_ver:1}
		if CmdExists "$app_name"; then
			if current_version="$("$real_home/.local/bin/$app_name" --version 2> /dev/null)" \
				|| current_version="$("$real_home/.local/bin/$app_name" -v 2> /dev/null)" \
				|| current_version="$("$app_name" --version 2> /dev/null)" \
				|| current_version="$("$app_name" -v 2> /dev/null)"; then
				if grep -q "$latest_ver_tr" <<< "$current_version"; then
					echo -e "$Msg_Success$Font_Purple$app_name$Font_Suffix is already the lastest version($latest_ver)"
					continue
				fi
			fi
		fi
		app_tar_names=("$app_name-$latest_ver-$OS_TYPE-unknown-$OS-gnu.tar.gz"
			"$app_name-$latest_ver_tr-$OS_TYPE-unknown-$OS-gnu.tar.gz"
			"$app_name-$latest_ver-$OS_TYPE-unknown-$OS-musl.tar.gz"
			"$app_name-$latest_ver_tr-$OS_TYPE-unknown-$OS-musl.tar.gz")
		for app_tar_name in "${app_tar_names[@]}"; do
			download_url="$git_app/releases/download/$latest_ver/$app_tar_name"
			if Is404 "$download_url"; then
				echo -e "$Msg_Info\"$app_name\"($latest_ver) The url returned 404, keep trying..."
				continue
			else
				echo -e "$Msg_Info\"$app_name\"($latest_ver) Got it! downloading..."
				local download_status
				curl -SfLO --progress-bar "$download_url" && tar -axf "$app_tar_name" && rm "$app_tar_name"
				download_status=$?
				if [[ $download_status -eq 0 ]] && CfgGitApps; then
					echo -e "$Msg_Success\"$app_name\"($latest_ver) installed successfully."
				else
					echo -e "$Msg_Failed: unable to download $app_name."
				fi
				break
			fi
		done
	done
	if [ -v proxy_flag ] && [ "$proxy_flag" -eq 1 ]; then
		Noproxy
	fi
	echo -e "${Msg_Success}Github utilities task done."
}

CfgGitApps() {
	sudo -u "${SUDO_USER:-$USER}" mkdir -p ~/.local/share/{bash,zsh}-completion/completions || return 1
	sudo -u "${SUDO_USER:-$USER}" mkdir -p ~/.local/share/man/man{1..8} || return 1
	if ! [ -f ~/.manpath ]; then
		sudo -u "${SUDO_USER:-$USER}" tee ~/.manpath <<- EOF > /dev/null
			MANDATORY_MANPATH ~/.local/share/man
		EOF
	fi

	find . -name "*ps1" -print0 | xargs -0 rm -f

	if file_bin_path=$(find . -iname "$app_name" -type f | grep .) && [ "$file_bin_path" ]; then
		chown "${SUDO_USER:-$USER}:${SUDO_USER:-$USER}" "$file_bin_path" && chmod 0755 "$file_bin_path" && mv -f "$file_bin_path" ~/.local/bin/
	fi

	if file_man_path=$(find . -iname "$app_name*.1" -type f | grep .) && [ "$file_man_path" ]; then
		echo "$file_man_path" | xargs chown "${SUDO_USER:-$USER}:${SUDO_USER:-$USER}"
		echo "$file_man_path" | xargs -I % mv -f % ~/.local/share/man/man1/
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

AddCstmFunc() {
	[ -e ~/.zshfn ] || sudo -u "${SUDO_USER:-$USER}" mkdir ~/.zshfn
	if ! [ -e ~/.zshfn/hp ]; then
		cat > ~/.zshfn/hp <<- 'EOF'
			# for pritter help
			hp() {
				if [ "$#" -eq 0 ]; then
					echo >&2 "Usage: help <command>"
					exit 0
				fi

				if [ "$#" -eq 1 ]; then
					("$1" --help 2> /dev/null || "$1" -h - 2> /dev/null) | bat --plain -l help -
				fi
			}
		EOF
	fi
	if ! [ -e ~/.zshfn/tf ]; then
		cat > ~/.zshfn/tf <<- 'EOF'
			# for tail -f file
			tf() {
				if [ $# -ge 1 ]; then
					tail -f $* | bat --theme Dracula --paging=never -l log
				else
				echo "Usage: tf /path/to/file"
				fi
			}
		EOF
	fi
	chown -R "${SUDO_USER:-$USER}:${SUDO_USER:-$USER}" ~/.zshfn
	if [ -f ~/.zshrc ]; then
		if ! grep -q "^fpath+=" ~/.zshrc; then
			sed -i '/^autoload/i \fpath+=\~/\.local/share/zsh-completion/completions' ~/.zshrc
		fi
		if ! grep -qi "zshfn" ~/.zshrc; then
			sed -i '/^autoload/i \fpath=( ~/.zshfn ${fpath[@]} )\nautoload -Uz $fpath[1]/*(.:t)' ~/.zshrc
		fi
	fi
	if ! [ -e ~/.local/bin/batman ]; then
		cat > ~/.local/bin/batman <<- 'EOF'
			#!/bin/bash
			#for prettier man page
			set -eu
			if [ "$#" -eq  0 ]; then /usr/bin/man; fi
			if [ "$1" ]; then
				if [[ "$1" =~ ^-[kf] ]]; then
					/usr/bin/man "$@" | col -bx | sed '1i \Key word list' | bat -l man -pp
				elif [[ "$1" =~ [[:digit:]]|-a|^[^-] ]]; then
					/usr/bin/man "$@" | col -bx | bat -l man -p
			else
			/usr/bin/man "$@"
				fi
			fi
		EOF
		chown -R "${SUDO_USER:-$USER}:${SUDO_USER:-$USER}" ~/.local/bin/batman && chmod 0755 ~/.local/bin/batman
	fi
	echo -e "${Msg_Success}Custom functions task done."
}

CalcTimeTaken() {
	printf -v end_time "%(%s)T"
	printf -v start_time "%(%s)T" -2
	time_taken=$((end_time - start_time))
	if [ $time_taken -gt 60 ]; then
		min=$(("$time_taken" / 60))
		sec=$(("$time_taken" % 60))
		echo -e "${Msg_Info}Completed in $min min $sec sec."
	else
		echo -e "${Msg_Info}Completed in $time_taken sec."
	fi
}

PrintSuccess() {
	printf '%s         %s__      %s           %s        %s       %s     %s__   %s\n' $FMT_RAINBOW $FMT_RESET
	printf '%s  ____  %s/ /_    %s ____ ___  %s__  __  %s ____  %s_____%s/ /_  %s\n' $FMT_RAINBOW $FMT_RESET
	printf '%s / __ \\%s/ __ \\  %s / __ `__ \\%s/ / / / %s /_  / %s/ ___/%s __ \\ %s\n' $FMT_RAINBOW $FMT_RESET
	printf '%s/ /_/ /%s / / / %s / / / / / /%s /_/ / %s   / /_%s(__  )%s / / / %s\n' $FMT_RAINBOW $FMT_RESET
	printf '%s\\____/%s_/ /_/ %s /_/ /_/ /_/%s\\__, / %s   /___/%s____/%s_/ /_/  %s\n' $FMT_RAINBOW $FMT_RESET
	printf '%s    %s        %s           %s /____/ %s       %s     %s          %s....is now installed!%s\n' $FMT_RAINBOW $FMT_GREEN $FMT_RESET
}

Tasks() {
	if [ "$1" = "update" ]; then
		ChkOSType
		ChkDist
		SetRealHome
		MkTempDir
		UpdateApps
		CleanUp
		CalcTimeTaken
	else
		ChkOSType
		ChkDist
		SetRealHome
		#ChgTimeZone
		SetSudoConf
		MkTempDir
		ChkPM
		InstallPkgs
		PipPacks
		InstallOhMyZsh
		ModifyZshRC
		ZshPlugins
		ModifyVimRC
		UpdateApps
		AddCstmFunc
		cd "$HOME" && CleanUp
		CalcTimeTaken
		SetupColor
		SetupZsh
	fi
}

Usage() {
	cat >&2 <<- EOF
		#
		# #******************************************************************#
		# | Example: sudo bash /path/to/script -a
		# | Options: [au], Default is '-a'.
		# | -a: Full, deb(apt)|rpm(dnf) install packages
		# | -a: vimrc, Oh-My-Zsh, and the ones listed below.
		# | -u: Install or update the latest pre-built binaries from github.
		# | -u: Such as bat, fd, dust, lsd, zoxide...
		# # *****************************************************************#
		#
	EOF
}

main() {
	Tasks "$action"
}

if [ -t 1 ]; then
	IsTTY() {
		true
	}
else
	IsTTY() {
		false
	}
fi

if [ $EUID -ne 0 ]; then
	Usage
	echo -e "\n${Msg_Error}This script must be run as ${Font_Yellow}root${Font_Suffix}!\n"
	exit 1
fi

while getopts ':au' opt; do
	case $opt in
		a) action='all' ;;
		u) action='update' ;;
		*)
			echo -e "${Font_Yellow}Wrone arguments.${Font_Suffix}"
			Usage
			exit 1
			;;
	esac
done
main "action"
