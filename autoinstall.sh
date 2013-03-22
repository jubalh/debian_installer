#!/bin/bash

#siehe http://tldp.org/LDP/abs/html/index.html
#hilfe: https://github.com/ginatrapani/todo.txt-cli/blob/master/todo.sh

#VARIABLES
SOURCES_LIST="/etc/apt/sources.list"
USR=$USER #TODO: als parameter getopt?
USR_HOME=/home/$USR
DEST_FOLDER=$USR_HOME/.jubaliansetup
IS_ROOT=0
MODE_INTERACTIVE=0

#REPOSITORIES
REPO_DOTFILES="https://github.com/jubalh/dotfiles.git"
REPO_GTK_GREYBIRD="https://github.com/shimmerproject/Greybird"
REPO_ICON_FAENZA="https://github.com/zhelyabuzhsky/faenza"
REPO_LS_COLORS="https://github.com/seebi/dircolors-solarized"
REPO_VUNDLE="https://github.com/gmarik/vundle.git"
REPO_OH_MY_ZSH="git://github.com/robbyrussell/oh-my-zsh.git"

#DESTINATIONS
DEST_GTK_GREYBIRD="greybird"
DEST_ICON_FAENZA="faenza"
DEST_LS_COLORS="dircolors-solarized"
DEST_VUNDLE=$USR_HOME"/.vim/bundle/vundle"
DEST_OH_MY_ZSH=$USR_HOME"/.oh-my-zsh/"
DEST_DOTFILES=$USR_HOME"/.dotfiles"

GIT_REPOS=($REPO_GTK_GREYBIRD $REPO_ICON_FAENZA $REPO_LS_COLORS $REPO_AWESOME_THEMES)
DESTINATIONS=($DEST_DOTFILES $DEST_OH_MY_ZSH $DEST_VUNDLE)

#FUNCTIONS
function usage(){
	echo "usage"
}

function check_root(){
	if [[ $(/usr/bin/id -u) -eq 0 ]]; then
		IS_ROOT=1
	else
		IS_ROOT=0
	fi
}

function clean_up(){
	for dest in "${DESTINATIONS[@]}"; do
		echo "removing ${dest}"
		rm -rf "${dest}"
	done
}

function git_clone() {
	git clone $1 $2
	if [[ $? -ne 0 ]]; then
		echo "error while cloning"
		echo "$*"
		exit 1
	fi
}

function say_done() {
	echo "done"
	echo 
}

#MAIN
clear
echo '######################'
echo 'automatic setup script'
echo '######################'

check_root()
if [[ $IS_ROOT -eq 0 ]]; then
	echo "going to install the config files and themes in your home directory"
	echo "if you want to have them globally run this script as root"
	echo "make sure your sources.list has all necessary repos. we can't edit them without root access"
fi

#writing sources.list
if [[ $IS_ROOT -eq 1 ]]; then
	if [[ $MODE_INTERACTIVE -eq 1 ]]; then
		echo "modifying sources.list?"
		echo -n "y/n: "
		read q
	fi
	if [[ ($MODE_INTERACTIVE -eq 0) || ($q == "y") ]]; then
		echo "deb http://ftp.halifax.rwth-aachen.de/debian/ testing main contrib non-free" > $SOURCES_LIST
		echo "deb-src http://ftp.halifax.rwth-aachen.de/debian/ testing main contrib non-free" >> $SOURCES_LIST
		echo "deb http://ftp.debian.org/debian/ wheezy-updates main contrib non-free" >> $SOURCES_LIST
		echo "deb-src http://ftp.debian.org/debian/ wheezy-updates main contrib non-free" >> $SOURCES_LIST
		echo "deb http://security.debian.org/ wheezy/updates main contrib non-free" >> $SOURCES_LIST
		echo "deb-src http://security.debian.org/ wheezy/updates main contrib non-free" >> $SOURCES_LIST
		echo "#Third Parties Repos" >> $SOURCES_LIST
		echo "#Debian Multimedia" >> $SOURCES_LIST
		echo "deb http://www.las.ic.unicamp.br/pub/debian-multimedia/ testing main" >> $SOURCES_LIST
		echo "#Debian Mozilla team" >> $SOURCES_LIST
		echo "deb http://your-mirror.debian.org/debian experimental main" >> $SOURCES_LIST #TODO: check correct uri
	fi
	if [[ $MODE_INTERACTIVE -eq 1 ]]; then
		echo "do you want to take a look at the modified sources.list?"
		echo -n "y/n: "
		read q
		if [[ "$q" -eq "y" ]]; then
			vim $SOURCES_LIST #TODO: editor variabel
		fi
	fi

	#TODO: oben fragen ob multimedia verwendet werden soll. wenn ja dann hier auch folgendes machen.
	#Debian Mozilla team
	#wget http://mozilla.debian.net/pkg-mozilla-archive-keyring_1.0_all.deb;
	#dpkg --install pkg-mozilla-archive-keyring_1.0_all.deb

	echo "updating..."
	apt-get update
	apt-get dist-upgrade

	if [[ $MODE_INTERACTIVE -eq 1 ]]; then
		echo "going to install packages"
		echo "do you want to take a look at the packages list?"
		echo "y/n: "
		read q
		if [[ "$q" -eq "y" ]]; then
			vim packages.lst
		fi
	fi

	echo "installing packages"
	if [[ -e packages.lst ]]; then
		apt-get install $(< packages.lst)
	else
		echo "packages.lst is missing"
		exit 1
	fi
fi

#create working dir
echo "creating work directory "$DEST_FOLDER
mkdir -p $DEST_FOLDER
cd $DEST_FOLDER

echo "cloning dotfiles..."
git_clone $REPO_DOTFILES $DEST_DOTFILES
bash $DEST_DOTFILES/setup.sh #warum geht exec nicht?
say_done

echo "cloning vundle and setting up vim plugins depending on vimrc..."
git_clone $REPO_VUNDLE $DEST_VUNDLE
#su $USR -c "vim +BundleInstall +qall" #TODO: oder vor allen ein su? aufpassen wegen rechten!
say_done
#TODO: oder zsh plugin vundle nutzen

#TODO: mehrere gute themes holen und am schluss setzen lassen. themes und icons als liste und oben definieren damit andere user einfach waehlen koennen? .git dir rausloeschen?
#gtk theme
echo "cloning greybird gtk theme..."
git_clone $REPO_GTK_GREYBIRD $DEST_GTK_GREYBIRD
if [[ $IS_ROOT -eq 1 ]]; then
	mv $DEST_GTK_GREYBIRD /usr/share/themes #TODO: oder /usr/share/local/themes?
else
	mv $DEST_GTK_GREYBIRD $USR_HOME/.themes
fi

#icons
echo "cloning faenza icon theme..."
git_clone $REPO_ICON_FAENZA $DEST_ICON_FAENZA
if [[ $IS_ROOT -eq 1 ]]; then
	mv $DEST_ICON_FAENZA /usr/share/icons
else
	mv $DEST_ICON_FAENZA $USR_HOME/.icons
fi

#mouse cursor

#solarized theme for ls command
git_clone $REPO_LS_COLORS $DEST_LS_COLORS
mv $DEST_LS_COLORS $USR_HOME/.dircolors
eval "dircolors $USR_HOME/.dircolors/dircolors.256dark"
#echo "eval \"dircolors $USR_HOME/.dircolors/dircolors.256dark\"" > ~/.profile or ~/.zshrc or do it in dotfiles?

echo "urxvt*termName:	rxvt-unicode-256color" >> $USR_HOME/.XDefaults
echo "urxvt*font: xft:Inconsolata:pixelsize=14" >> $USR_HOME/.XDefaults #TODO: inconsolata klein?
#am besten solarized mit >> dranhaengen

#zsh config und theme
git_clone $REPO_OH_MY_ZSH $DEST_OH_MY_ZSH
cp $DEST_OH_MY_ZSH"/templates/zshrc.zsh-template" $USR_HOME"/.zshrc"

#bzw. echo "colorscheme indigo" >> $USR_HOME/.vimperatorrc

#TODO: im interaktiv modus gtk theme switch prog oder so aufrufen
#TODO: clean modus bauen der dann die git repos in $HOME/.awsetup loescht. so das nur noch die benoetigten dateien bleiben. oder dohc lieber auch diese nach ~/.dotfiles verschieben -n?

#TODO: am schluss/danach heimstall.sh starten und meine configs ueber diese schreiben. somit hab ich was allgemeines fuer neuinstalliation(und andere user) und hab meine spezifischen konfigs
