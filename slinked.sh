#!/bin/bash
#
# @author Martin Vicián <info@vician.cz>
#
# @file slinked.sh
# @brief Symbolic links for git
# @details Way to have git in separate folder and using git file in anywhere in system via symbolic links
#
# @version 0.1
# @date 2014-07-10

### Params ###
debug=""
# Extension for config file, without standard dot, default is 'sln' that mean fir file 'filename' is it 'filename.sln'
config_ext="sln"
# Backup old file whitch will be replaced by symlink
backup=""
# Extension for backup file, without standard dot, for example will create dir /etc/apache2.sln.bak/
backup_ext="sln.bak"
# Default type link
link_type="s"

### Variables ###
configs=()
script_dir=`dirname $0`
# Only test, not creating link
test=""
# Restoring process
restore=""
# Remove destination
force=""

### Functions ###
function help {
	echo "usage: $0 [-l link_type] [-d] [-f] [-t] [-h] [-r]"
	exit 1
}

function params {
	run="run[$#]: $0 $*"

	OPTIND=1
	while getopts 'l:dfthr' opt; do
	  case "$opt" in
		l)
		  link_type=$OPTARG ;;
		d)
		  debug="True"
		  if [ $debug ]; then echo $run; fi
		  ;;
		f)
		  force="True" ;;
		t)
		  test="True" ;;
		r)
		  restore="True" ;;
		h)
		  help ;;
	  esac
	done

	shift $(($OPTIND - 1)) # move to first non-option params
}

function ask_yes_or_no {
	#if [ $# -ne 1 ]; then
	#	ask="Would you like it?"
	#else
	#	ask=$1
	#fi
	#echo "$ask (y/n)"
	read -n 1 choice < /proc/${PPID}/fd/0
	if [ "$choice" = "y" ] || [ "$choice" = "Y" ]; then
		echo "yes"
	fi
	#echo "no"
	#return 0
}

function get_configs {
	if [ $# -ne 1 ]; then
		echo "ERROR: get_configs: empty dirname!"
		return 1;
	fi
	#if [ $debug ]; then echo "get_configs: $1"; fi
	for i in "$1"/* ;do
		if [ -d "$i" ];then
			#echo "dir: $i"
			get_configs "$i"
		elif [ -f "$i" ]; then
			filename=$(basename "$i")
			ext="${filename##*.}"
			#echo "file: $i => '$ext'"
			if [ "$ext" == "$config_ext" ]; then
				configs+=($i)
			fi

		fi
	done
}

function print_configs {
	if [ ! $debug ]; then
		return 0;
	fi
	echo "Loaded configs [${#configs[@]}]:"
	for config in ${configs[*]}; do
		echo -e "\t$config"
	done
}

function get_src {
	if [ $# -ne 1 ]; then
		echo "ERROR: get_src no config file!"
		exit 1;
	fi
	file=$1
	ext_length=${#config_ext} # length of config extension
	let ext_length++ # but without standard dot
	# substr
	src=${file:0:-$ext_length}

	echo $src
}

function create_link {
	if [ $# -ne 1 ]; then
		echo "ERROR: create_link no config file!"
		exit 1;
	fi
	file=$1
	if [ ! -f $file ]; then
		echo "ERROR: create_link config file not exists! ($file)"
		exit 1;
	fi
	src=`get_src $file`
	if [ ! -f $src ] && [ ! -d $src ]; then
		echo "ERROR: create_link source file not exists! ($src)"
		exit 1;
	fi
	if [ $debug ]; then echo "file: $file, src: $src"; fi
	# var for previously used hostname
	used_hostname=""
	# loaded links
	while read -e LINE; do
		# filter comments
		if [ "${LINE:0:1}" == "#" ]; then
			continue
		fi
		# Remove previous params
		hostname=""
		current_link_type=""
		# Try separate params
		IFS='|' read -ra arr <<< "$LINE"
		# Dest is always first
		first="True"
		for param in ${arr[@]}; do
			# Dest is
			if [ $first ] ; then
				dest=${arr[0]}
				first=""
				continue
			fi
			param_type=${param:0:1}
			case $param_type in
				h)
					hostname=${param:2};;
				l)
					current_link_type=${param:2};;
			esac
		done

		if [ $debug ]; then echo -e "\tdst: $dest (${dest:0:2}), host:$hostname, link:$current_link_type"; fi

		if [ "${dest:0:1}" != "/" ] && [ "${dest:0:1}" != "~" ] && [ "${dest:0:2}" != "./" ] && [ "${dest:0:3}" != "../" ]; then
			echo "ERROR: Path is not absolute!"
			exit 1;
		fi
		if [ "${dest:0:1}" = "~" ]; then
			#echo "! converting ~"
			dest="`echo $HOME`${dest:1}"
		fi

		if [ "${dest:0:2}" = "./" ] || [ "${dest:0:3}" = "../" ]; then
			echo "@todo relative path"
			dest="`dirname $src`/$dest"
			echo "new dest: $dest"
		fi

		if [ "$hostname" ]; then
			# hostname is set in this config rule
			me_hostname=`hostname`
			if [ "$hostname" != "$me_hostname" ]; then
				if [ $debug ]; then echo -e "\t\t-> skiping (me: $me_hostname)"; fi
				continue;
			fi
			used_hostname="True"
		else
			# global config rule
			if [ $used_hostname ]; then
				if [ $debug ]; then echo -e "\t\t-> global rule but was used specific rule"; fi
				continue;
			fi
		fi

		if [ -f "$dest" ] || [ -d "$dest" ]; then
			# @test if is already symbolic link
			if [ ! -h "$dest" ]; then
				echo "dest: $dest exists (not as link)"
				if [ ! -f $dest.$backup_ext ] && [ ! -d $dest.$backup_ext ]; then
					echo "Create backup? (y/n)"
					if [ "`ask_yes_or_no`" ]; then
						if [ ! $test ]; then
							mv $dest $dest.$backup_ext
							rm -rf $dest
						fi
					fi
				else
					echo "Backup exist, replace it? (y/n)"
					if [ "`ask_yes_or_no`" ]; then
						if [ ! $test ]; then
							mv $dest $dest.$backup_ext
							rm -rf $dest
						fi
					else
						echo "Remove original dest? (y/n)"
						if [ "`ask_yes_or_no`" ]; then
							if [ ! $test ]; then
								rm -rf $dest
							fi
						else
							echo "Skiping this dest!"
							continue
						fi
					fi
				fi
			else
				echo "Link already exists ($dest), replace it? (y/n)"
				if [ "`ask_yes_or_no`" ]; then
					if [ ! $test ]; then
						rm -rf $dest
					else
						echo "$ rm -rf $dest"
					fi
				else
					echo "Skiping this dest!"
					continue
				fi
			fi
		fi
		src=`realpath $src`

		# set default
		do_link_type=$link_type
		if [ $current_link_type ]; then
			do_link_type=$current_link_type
		fi

		case $do_link_type in
			s)
				run="ln -s" ;;
			l)
				run="ln" ;;
			c)
				run="cp" ;;
		esac

		if [ $test ]; then
			echo "$ $run $src $dest"
		else
			$run $src $dest
		fi

	done < $file
}

function do_link {
	if [ ${#configs[@]} -eq 0 ]; then
		echo "ERROR: no configs file!"
		exit 1;
	fi
	for config in ${configs[@]}; do
		if [ $debug ]; then echo "- creating_link $config"; fi
		create_link $config
	done
}

function check_linked_integrity {
	echo "@todo check_linked_integrity"
}

### Main ###
#if [ "`ask_yes_or_no`" ]; then
#	echo "yes"
#else
#	echo "no"
#fi
#exit 0;
params $*
get_configs .
print_configs
do_link
