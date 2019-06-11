### you can use `fish_config` to config a lot of things in WYSIWYG way in browser

#set -gx GOPATH $GOPATH ~/GoPro
# set -gx PATH $HOME/anaconda3/bin ~/.local/share/arm-linux/bin ~/.local/bin ~/.linuxbrew/bin $GOPATH/bin ~/bin $PATH
#set -gx PATH $HOME/anaconda3/bin $HOME/.local/bin $GOPATH/bin /usr/local/bin /usr/local/liteide/bin /bin /sbin /usr/bin /usr/sbin $PATH
set -gx PATH $HOME/anaconda3/bin $HOME/.local/bin /usr/local/bin /bin /sbin /usr/bin /usr/sbin $PATH

# By default, MANPATH variable is unset, so set MANPATH to the result of `manpath` according to
# /etc/man.config and add the customized man path to MANPATH
if test "$MANPATH" = ""
    set -gx MANPATH (manpath | string split ":")
end
set -gx MANPATH $HOME/anaconda3/share/man $MANPATH

set -gx FISH_CONFIG_PATH ~/.config/fish/config.fish
set -gx EMACS_EL ~/.spacemacs.d/init.el

# Please put the following lines into ~/.bashrc, putting them in config.fish won't work
# This fixes a lot problems of displaying unicodes
# https://github.com/syl20bnr/spacemacs/issues/12257
# export LC_ALL=en_US.UTF-8
# export LANG=en_US.UTF-8
# export LANGUAGE=en_US.UTF-8

# fix the Display :0 can't be opened problem
if test $DISPLAY
    if xhost ^/dev/null >/dev/null
        if not xhost | grep (whoami) ^/dev/null >/dev/null
            xhost +si:localuser:(whoami) ^/dev/null >/dev/null
        end
    end
end

# disable ksshaskpass pop window in KDE
set -e SSH_ASKPASS

# for ~/.linuxbrew/ (brew for linux to install programs)
#set -gx LD_LIBRARY_PATH $LD_LIBRARY_PATH ~/.linuxbrew/Library

# do not use the format above
# http://vivafan.com/2013/03/%E3%80%8Cfish%E3%80%8D%E3%82%B7%E3%82%A7%E3%83%AB%E3%82%92%E5%AE%9F%E9%9A%9B%E3%81%AB%E4%BD%BF%E3%81%86%E3%81%9F%E3%82%81%E3%81%AB/
# for more formats

# remove the greeting message
set fish_greeting
set fish_new_pager 1
set -gx fish_color_user magenta
set -gx fish_color_host yellow
# set the color of the selected on in the drop list of TAB #4695
set -g fish_color_search_match --background=blue

# start fish without configuration
abbr fi "sh -c 'env HOME=\$(mktemp -d) fish'"


# do `h` in the new one after switching terminal session
function h --on-process-exit %self
    history --merge
end
function his
    history | ag $argv[1]
end

function auto-source --on-event fish_preexec -d 'auto source config.fish if gets modified!'
    if not set -q FISH_CONFIG_TIME # if FISH_CONFIG_TIME not set, status != 0
        set -g FISH_CONFIG_TIME (date +%s -r $FISH_CONFIG_PATH)
    else
        set FISH_CONFIG_TIME_NEW (date +%s -r $FISH_CONFIG_PATH)
        if test "$FISH_CONFIG_TIME" != "$FISH_CONFIG_TIME_NEW"
            fsr
            set FISH_CONFIG_TIME (date +%s -r $FISH_CONFIG_PATH)
        end
    end
end

function path_prompt
    # check if tmux is running in current terminal/tty
    if test $TMUX
        return
    else
        set_color -ru
        # User
        set_color $fish_color_user
        echo -n $USER
        # set_color normal

        echo -n '@'

        # Host
        set_color $fish_color_host
        echo -n (hostname -s)
        # set_color normal

        echo -n ':'

        # PWD
        #set_color $fish_color_cwd
        set_color -o yellow
        echo -n (prompt_pwd)
        set_color normal

        echo
    end
end
function fish_prompt --description 'Write out the prompt'
    h
    set -l last_status $status

    # if the PWD is not the same as the PWD of previous prompt, print path part
    if test "$OLDPWD" != "$PWD"
        path_prompt
    end

    if test $last_status != 0
        set_color $fish_color_error
    end
    # http://unicode-table.com/en/sets/arrows-symbols/
    # http://en.wikipedia.org/wiki/Arrow_(symbol)
    set_color -o yellow
    set_color -u
    echo -n '>>' # '➤➤ '  # ➢ ➣, ↩ ↪ ➥ ➦, ▶ ▷ ◀ ◁, ❥
    #echo -n '➤➤ '  # ➢ ➣, ↩ ↪ ➥ ➦, ▶ ▷ ◀ ◁, ❥
    set_color normal
    echo ' '
end
function measure_time
    # from joker plugin https://github.com/fisherman/joker
    if test "$CMD_DURATION" -gt 1000 # 1s
        set -l duration_copy $CMD_DURATION
        set -l duration (echo $CMD_DURATION | humanize_duration)
        printf (set_color red)"($duration)"(set_color normal)
    end
end
function fish_right_prompt -d "Write out the right prompt"
    # set_color -o black
    measure_time
    set_color -o normal
    echo -n '['
    echo -n (date +%T)
    echo -n ']'

    __informative_git_prompt
    set_color $fish_color_normal
end

function fsr --description 'Reload your Fish config after configuration'
    source $FISH_CONFIG_PATH # fsr
    varclear PATH
    echo $FISH_CONFIG_PATH is reloaded!
    path_prompt
end

# tmux related
abbr tls 'tmux list-panes -s'
function tk -d 'tmux kill-session all(default)/single(id)/multiple(id1 id2)/except(-e)/list(-l) sessions'
    if test (ps -ef | grep -v grep | grep -i tmux | wc -l ) = 0
        echo "No tmux server is running!!!"
        return
    end
    set -l options 'e' 'l'
    argparse -n tk $options -- $argv
    or return

    if set -q _flag_l
        tmux ls
        if set -q TMUX_PANE # check if running inside a tmux session
            echo
            echo Already inside tmux session: (tmux display-message -p '#S')
        end
        return
    end
    if set -q $argv[1] # no arguments
        if set -q TMUX_PANE # check if running inside a tmux session
            echo Inside a tmux session!
            read -n 1 -l -p 'echo "Kill all sessions include current running one? [y/N]"' answer
            if test "$answer" = "y"
                echo tmux kill-server        # kill all sessions include current one
            end
        end
        return
    end

    if test (count $argv) -gt 0
        set -l sid (tmux ls | nl | awk '{print $2}' | sed 's/://g')
        for i in $sid
            if set -q _flag_e
                if not contains $i $argv
                    tmux kill-session -t $i
                    echo Tmux session $i is killed
                end
            else
                if contains $i $argv
                    tmux kill-session -t $i
                    echo Tmux session $i is killed
                end
            end
        end
        echo \n--------------\n
        echo Left sessions:
        tmux ls
    end
end

# or just use 'M-c r', it is defiend in ~/.tmux.conf
abbr tsr 'tmux source-file ~/.tmux.conf; echo ~/.tmux.conf reloaded!'
# this line will make the indentation of lines below it wrong, TODO: weird
# abbr tt 'tmux switch-client -t'
function twp -d 'tmux swap-pane to current pane to the target pane'
    tmux display-panes "'%%'"
    read -n 1 -p 'echo "Target pane number? "' -l num
    tmux swap-pane -s $num
end

alias check 'checkpatch.pl --ignore SPDX_LICENSE_TAG,CONST_STRUCT,AVOID_EXTERNS,NEW_TYPEDEFS --no-tree -f'

# TODO: the following part will make fish print "No protocol specified" error line
# source $HOME/.config/fish/functions/done.fish
# the following script will make fish v3.0.0 prompt hang
# source $HOME/.config/fish/functions/__async_prompt.fish

# LS_COLORS, color for ls command
# http://linux-sxs.org/housekeeping/lscolors.html
# http://www.bigsoft.co.uk/blog/index.php/2008/04/11/configuring-ls_colors
set -gx LS_COLORS 'ex=01;33:ln=96:*~=90:*.swp=90:*.bak=90:*.o=90:*#=90'

# fix the `^[]0;fish  /home/chz^G` message in shell of Emacs
if test "$TERM" = "dumb"
    function fish_title
    end
end

function dirp --on-event fish_preexec
    set -g OLDPWD $PWD
end

function delete-or-ranger -d 'modified from delete-or-exit, delete one char if in command, execute ranger instead exiting the current terminal otherwise'
    set -l cmd (commandline)

    switch "$cmd"
        case ''
            ranger

        case '*'
            commandline -f delete-char
    end
end
# all bindings should be put inside the single one fish_user_key_bindings
function fish_user_key_bindings
    # without this line, C-l will not print the path at top of the screen
    #bind \cl 'clear; commandline -f repaint; path_prompt'
    #bind \cl ""
    #bind \cl "tput reset; commandline -f repaint; path_prompt"
    bind \cd delete-or-ranger
    # if Alt-backword doesn't work, use this
    # TODO: delete it if fish-shell itself fix it
    bind \e\b backward-kill-word
    # TODO: delete it if fish-shell itself fix it
    # Ctrl-c/v is bound to fish_clipboard_copy/paste which is not working in non-X
    if not test $DISPLAY
        bind --erase \cx # or bind \cx ""
        bind --erase \cv # or bind \cv ""
    end
end
abbr clr "echo -e '\033c\c'; path_prompt"

abbr pm-sl 'sudo pm-suspend'   # 'Suspend to ram' in GUI buttom, power button to wake up
abbr pm-hb 'sudo pm-hibernate' # not work in old CentOS6

abbr rg 'rg -p'
abbr rgr 'ranger'
abbr fpp '~/Public/PathPicker/fpp'
abbr ga 'glances -t 1 --hide-kernel-threads -b --disable-irq --enable-process-extended'
abbr dst 'dstat -d -n'

# make the make and gcc/g++ color
function make
    /usr/bin/make -B $argv 2>&1 | grep --color -iP "\^|warning:|error:|undefined|"
end
function gcc
    /usr/bin/gcc $argv 2>&1 | grep --color -iP "\^|warning:|error:|undefined|"
end
function gcc-a
    set BIN (echo (string split .c $argv) | awk '{print $1;}')
    /usr/bin/gcc -Wall -W -g -o $BIN $argv 2>&1 | grep --color -iP "\^|warning:|error:|undefined|"
end
function g++
    /usr/bin/g++ $argv 2>&1 | grep --color -iP "\^|warning:|error:|Undefined|"
end
abbr gcc-w 'gcc -g -Wall -W -Wsign-conversion'
abbr gcca 'gcc -g -pedantic -Wall -W -Wconversion -Wshadow -Wcast-qual -Wwrite-strings -Wmissing-prototypes  -Wno-sign-compare -Wno-unused-parameter'
# gcc -Wall -W -Wextra -Wconversion -Wshadow -Wcast-qual -Wwrite-strings -Werror

# User specific aliases and functions
function lsx -d 'cp the full path of a file/dir to sytem clipboard'
    if test $DISPLAY
        if test -f $argv -o -d $argv
            readlink -fn $argv | xc
            xc -o
            echo \n---- Path Copied to Clipboard! ----
        end
    else
        echo DISPLAY is not available!
    end
end
function xcp -d 'paste the echo string into system clipper board'
    echo -n $argv | xc
    echo "'$argv'"
    echo Copied to system clipped board!!!
end
# pastebin service in command line
function bxp -d 'pastebin service in command line'
    eval $argv
    eval $argv | curl -F 'f:1=<-' ix.io
    # slow
    # eval $argv | curl -F 'sprunge=<-' http://sprunge.us
end
#
function lls -d 'ls functions with options'
    set -l options 't' 'T' 's' 'S'
    argparse -n lls $options -- $argv
    or return

    if set -q $argv[1]          # no argument
        set ARGV "."
    else
        set ARGV $argv
    end
    if set -q _flag_t      # sort by last modification time, only show tail
        ls -lhA --color=yes $ARGV --sort=time -r -lh --time=ctime | nl -v 0 | tail -20
    else if set -q _flag_T # like -t, but show the whole list
        ls -lhA --color=yes $ARGV --sort=time -r -lh --time=ctime | nl -v 0
    else if set -q _flag_s # sort by size, only show tail
        ll -lhA --color=yes $ARGV --sort=size -r -lh | nl -v 0 | tail -20
    else if set -q _flag_S # like -s, but show the whole list
        ll -lhA --color=yes $ARGV --sort=size -r -lh | nl -v 0
    else                   # otherwise without option, working like -t
        ls -lhA --color=yes $ARGV --sort=time -r -lh --time=ctime | nl -v 0 | tail -20
    end
end
# valgrind
# abbr va='valgrind -v --track-origins=yes'
abbr va 'valgrind --track-origins=yes --leak-check=full'
# more detail about time
abbr vad 'valgrind --tool=callgrind --dump-instr=yes --simulate-cache=yes --collect-jumps=yes'

abbr im 'ristretto'
abbr ds 'display'

abbr ka 'killall -9'
# If Emacs hangs and won't response to C-g, use this to force it to stop whatever it's doing
# Note that do not use this if you got more than one instances of Emacs running
# Use `pkill -SIGUSR2 PID` to kill the PID, send SIGUSR2 to emacs will turn on `toggle-debug-on-quit`, turn it off once emacs is alive again
abbr ke 'pkill -SIGUSR2 emacs'
# get the pid of a gui program using mouse
abbr pid 'xprop | grep -i pid | grep -Po "[0-9]+"'
function psg -d 'pgrep process'
    ps -ef | grep -v grep | grep -i $argv[1] | nl
end
# pkill will not kill processes matching pattern, you have to kill the PID
function pk --description 'kill processes containing a pattern or PID'
    set result (psg $argv[1] | wc -l)
    if test $result = 0
        echo "No '$argv[1]' process is running!"
    else if test $result = 1
        set -l pid (psg $argv[1] | awk '{print $3}')
        if not kill -9 $pid # failed to kill, $status != 0
            psg $pid | ag $argv[1] # list the details of the process need to be sudo kill
            read -n 1 -p 'echo "Use sudo to kill it? [Y/n]: "' -l arg
            if test "$arg" = "" -o "$arg" = "y" -o "$arg" = " "
                sudo kill -9 $pid
            end
        end
    else
        while test 1
            psg $argv[1]
            if test (psg $argv[1] | wc -l) = 0
                return
            end
            read -p 'echo "Kill all of them or specific PID? [y/N/index/pid/m_ouse]: "' -l arg2
            if test $arg2       # it is not Enter directly
                if not string match -q -r '^\d+$' $arg2 # if it is not integer
                    if test "$arg2" = "y" -o "$arg2" = " "
                        set -l pids (psg $argv[1] | awk '{print $3}')
                        for i in $pids
                            if not kill -9 $i # failed to kill, $status != 0
                                psg $i | ag $argv[1]
                                read -n 1 -p 'echo "Use sudo to kill it? [Y/n]: "' -l arg3
                                if test "$arg3" = "" -o "$arg3" = "y" -o "$arg3" = " "
                                    sudo kill -9 $i
                                end
                            end
                        end
                        return
                    else if test "$arg2" = "m" # Use mouse the click the opened window
                        # This may be used for frozen emacs specifically, -usr2 or -SIGUSR2
                        # will turn on `toggle-debug-on-quit`, turn it off once emacs is alive again
                        # Test on next frozen Emacs
                        # kill -usr2 (xprop | grep -i pid | grep -Po "[0-9]+")
                        # kill -SIGUSR2 (xprop | grep -i pid | grep -Po "[0-9]+")
                        set -l pid_m (xprop | grep -i pid | grep -Po "[0-9]+")
                        echo Pid is: $pid_m
                        if test (psg $pid_m | grep -i emacs)
                            kill -SIGUSR2 $pid_m
                        else
                            kill -9 $pid_m
                        end
                        return
                    else if test "$arg2" = "n"
                        return
                    else
                        echo Wrong Argument!
                    end
                else  # if it is digital/integer
                    if test $arg2 -lt 20 # index number, means lines of searching result
                        # The "" around $arg2 is in case of situations like 10 in 1002
                        set -l pid_of_index (psg $argv[1] | awk 'NR == n' n=" $arg2 " | awk '{print $3}')
                        if not test $pid_of_index
                            echo $arg2 is not in the index of the list.
                        else
                            # return
                            if not kill -9 $pid_of_index # kill failed, $status != 0
                                psg $pid_of_index | ag $argv[1] # list the details of the process need to be sudo kill
                                read -n 1 -p 'echo "Use sudo to kill it? [Y/n]: "' -l arg4
                                if test $arg4 = "" -o "$arg4" = "y" -o "$arg4" = " "
                                    # the first condition is to check Return key
                                    sudo kill -9 $pid_of_index
                                end
                            end
                        end
                    else        # pid
                        # The $arg2 here can be part of the real pid, such as typing only 26 means 126
                        if test (psg $argv[1] | awk '{print $3}' | grep -i $arg2)
                            set -l pid_part (psg $argv[1] | awk '{print $3}' | grep -i $arg2)
                            if not kill -9 $pid_part # kill failed, $status != 0
                                psg $pid_part | ag $argv[1] # list the details of the process need to be sudo kill
                                read -n 1 -p 'echo "Use sudo to kill it? [Y/n]: "' -l arg5
                                if test $arg5 = "" -o "$arg5" = "y" -o "$arg5" = " "
                                    sudo kill -9 $pid_part
                                end
                            end
                        else
                            echo "PID '$arg2' is not in the pid of the list!"
                            echo
                        end
                    end
                end
            else # Return goes here, means `quit` like C-c or no nothing
                return
            end
            sleep 1
        end
    end
end

abbr epath 'varclear PATH; echo $PATH | tr " " "\n" | nl'
function varclear --description 'Remove duplicates from environment varieble'
    if test (count $argv) = 1
        set -l newvar
        set -l count 0
        for v in $$argv
            if contains -- $v $newvar
                set count (math $count+1)
            else
                set newvar $newvar $v
            end
        end
        set $argv $newvar
        test $count -gt 0
    else
        for a in $argv
            varclear $a
        end
    end
end

alias rm 'rm -vi'
alias cp 'cp -vi'
alias mv 'mv -vi'
abbr rcp 'rsync --stats --progress -rhv'
abbr rmc 'rsync --stats --progress -rhv --remove-source-files' # this will not delte the src dir, only the contents

# abbr grep='grep -nr --color=auto'
abbr g 'grep -F -n --color=auto'

function abbrc -d 'clean abbrs in `abbr --show` but not in $FISH_CONFIG_PATH'
    if abbr --show | head -n1 | grep "abbr -a -U" ^/dev/null >/dev/null
        set abbr_show "abbr -a -U --"
    else
        set abbr_show "abbr"
    end

    for abr in (abbr --show)
        set abr_def (echo $abr | sed "s/$abbr_show//g" | awk '{print $1}')
        # echo abr_def: $abr_def
        set def_file $FISH_CONFIG_PATH
        set num_line (grep -n "^abbr $abr_def " $def_file | cut -d: -f1)
        if not test $num_line # empty
            echo "$abr_def is an abbr in `abbr --show` but not defined in $FISH_CONFIG_PATH, may be defined temporally or in other file!"
            abbr -e $abr_def
            echo "$abr_def is erased!"
            # return
        end
    end
end

function fu -d 'fu command and prompt to ask to open it or not'
    # $argv could be builtin keyword, function, alias, file(bin/script) in $PATH, abbr
    # And they all could be defined in script or temporally (could be found in any file)
    set found 0
    # Check `type` output, NOTE: `type` doesn't support abbr
    if type $argv ^/dev/null # omit the result once error(abbr or not-a-thing) returned, $status = 0
        set found 1 # for not-a-thing
        set result (type $argv)
    end

    if abbr --show | head -n1 | grep "abbr -a -U" ^/dev/null >/dev/null
        set abbr_show "abbr -a -U --"
    else
        set abbr_show "abbr"
    end
    # NOTE: $argv may also be defined as an abbr like rm command
    abbr --show | grep "$abbr_show $argv " # Space to avoid the extra abbr starting with $ARGV
    if test $status = 0
        # in case $argv existes in both `type` and `abbr --show`
        # function may be `function func` and `function func -d ...`
        if test $found = 1 -a (echo (grep -w -E "^alias $argv |^function $argv |^function $argv\$" $FISH_CONFIG_PATH))
            echo "$argv is in both `type` and `abbr --list`, found definition in $FISH_CONFIG_PATH"
            echo "Please clean the multiple definitions!"
            abbrc
            # return
        else # only exists in `abbr --show`
            set found 1
            set result (abbr --show | grep "$abbr_show $argv ")
        end
    else if test $status != 0 -a $found != 1
        echo "$argv is not a thing!"
        return
    end

    set result_1 (printf '%s\n' $result | head -1)
    set def_file $FISH_CONFIG_PATH
    if test (echo $result_1 | grep -E "$abbr_show $argv |is a function with definition") # defined in fish script
        if test (echo $result_1 | grep -E "is a function with definition")
            # 1. function or alias -- second line of output of fu ends with "$path @ line $num_line"
            set -l result_2 (printf '%s\n' $result | sed -n "2p")
            set def_file (echo $result_2 | awk -v x=4 '{print $x}')
            if test "$def_file" = "-" # alias, no definition file is printed
                set def_file $FISH_CONFIG_PATH
            end

            set num_line (grep -n -w -E "^alias $argv |^function $argv |^function $argv\$" $def_file | cut -d: -f1)
            # NOTE: $num_line may contain more than one number, use "$num_line", or test will fail
            if not test "$num_line" # empty
               echo "$argv is an alias/functions in `alias/functions` but not defined in $def_file, may be defined temporally or in other file!"
                if test $def_file = $FISH_CONFIG_PATH
                    functions -e $argv
                    echo "$argv is erased!"
                end
                return
            else if test (echo "$num_line" | grep " ") # $num_line contains more than one value
                echo "$argv has multiple definitions(alias and function) in $FISH_CONFIG_PATH, please clean them!"
                return
            end
        else # 2. abbr, only handle abbr defined in $FISH_CONFIG_PATH
            abbrc
            set num_line (grep -n -w -E "^abbr $argv " $def_file | cut -d: -f1)
        end

        echo
        read -n 1 -p 'echo "Open the file containing the definition? [y/N]: "' -l answer
        if test "$answer" = "y" -o "$answer" = " "
            vim $def_file +$num_line
        end
    else if test (echo $result_1 | grep -i "is a builtin")
        # 3. $argv in builtin like if
        return
    else # 4. $argv is a file in $PATH
        set -l file_path (echo $result_1 | awk 'NF>1{print $NF}')
        file $file_path | grep "symbolic link" # print only $argv is symbolic link
        file (readlink -f $file_path) | grep -E "ELF|script|executable" # highlight
        if test (file (readlink -f $file_path) | grep "script") # script can be open
            echo
            read -n 1 -p 'echo "Open the file for editing?[y/N]: "' -l answer
            if test "$answer" = "y" -o "$answer" = " "
                vim $file_path
            end
        end
    end
end

function fzfp -d 'check if fzf is existed, with any argument, fzf binary file will be upgraded'
    if command -sq fzf; and set -q $argv[1] # fzf is in $PATH, and no any argv is given, two conditions
        # echo "fzf is installed, use any extra to upgrade it!"
        return 0
    else
        # check internet connection
        if not wget -q --spider http://www.baidu.com # failed, $status != 0
            echo "fzf doesn't exist and error occurs when downloading it!"
            return 1
        end
        set tag_name (curl -s "https://api.github.com/repos/junegunn/fzf-bin/releases/latest" | grep "tag_name" | cut -d : -f 2 | awk -F[\"\"] '{print $2}')
        if not test $tag_name
            echo "API rate limit exceeded, please input your password for your username!"
            set tag_name (curl -u c02y -s "https://api.github.com/repos/junegunn/fzf-bin/releases/latest" | grep "tag_name" | cut -d : -f 2 | awk -F[\"\"] '{print $2}')
        end
        set file_name (echo fzf-$tag_name-linux_amd64.tgz)
        set file_link (echo https://github.com/junegunn/fzf-bin/releases/download/$tag_name/$file_name)
        wget $file_link -O /tmp/$file_name
        if test -f /tmp/$file_name
            tar -xvzf /tmp/$file_name -C ~/.local/bin
            return 0
        else
            echo "fzf doesn't exist and error occurs when downloading it!"
            return 1
        end
    end
end

set -gx Z_PATH ~/.config/fish/functions/
if test -e $Z_PATH/z.lua
    source (lua $Z_PATH/z.lua --init fish once echo | psub)
    # z.lua using built-in cd which won't affect the cd stack of fish shell, use fish's cd so you can use `cd -`
    set -gx _ZL_CD cd
    set -gx _ZL_INT_SORT 1
    set -gx _ZL_FZF_HEIGHT 0 # 0 means fullscreen
    set -gx FZF_DEFAULT_OPTS '-1 -0' # auto select the only match, auto exit if no match
end
function zp -d 'check exists of z.lua, with any given argument, update z.lua'
    if test -e $Z_PATH/z.lua; and set -q $argv[1] # z.lua file exists and no any argv is given, two conditions
        # echo "z.lua is installed, use any extra to upgrade it!"
        return 0
    else
        if not curl https://raw.githubusercontent.com/skywind3000/z.lua/master/z.lua -o /tmp/z.lua
            echo "Failed to install/update z.lua due to Internet issue!"
            return 1
        else
            mv /tmp/z.lua $Z_PATH/z.lua
            return 0
        end
    end
end
abbr zb 'z -b' # Bonus: zb .. equals to cd .., zb ... equals to cd ../.. and
# zb .... equals to cd ../../.., and so on. Finally, zb ..20 equals to cd (..)x20.
function zz -d 'z\'s interactive selection mode'
    if not zp
        echo "Failed to install z.lua!"
        return
    end
    if fzfp # fzf exists, $status = 0
        set z_cmd z -I
    else
        set z_cmd z -i
    end
    if test (count $argv) = 0
        eval $z_cmd .
    else
        eval $z_cmd  $argv
    end
end
function zh -d 'z\'s cd into the cd history'
    if not zp
        echo "Failed to install z.lua!"
        return
    end
    if fzfp # fzf exists, $status = 0
        set z_cmd z -I -t
    else
        set z_cmd z -i -t
    end
    if test (count $argv) -eq 0
        eval $z_cmd .
    else
        eval $z_cmd $argv
    end
end

# touch temporary files
abbr tout 'touch ab~ .ab~ .\#ab .\#ab\# \#ab\# .ab.swp ab.swp'
# find
# alias find 'find -L' # make find follow symlink dir/file by default
function finds -d 'find a file/folder and view/edit using less/vim/emacs/emx/cd/readlink with fzf'
    set -l options 'l' 'v' 'e' 'x' 'c' 'p' 'g'
    argparse -n finds $options -- $argv
    or return

    if not fzfp # fzf doesn't exist, $status != 0
        find $argv[1] -name "*$argv[2]*"
        return
    end

    if set -q _flag_l           # find a file and view it using less
        less (find $argv[1] -name "*$argv[2]*" | fzf)
    else if set -q _flag_v      # find a file and view it using vim
        vim (find $argv[1] -name "*$argv[2]*" | fzf)
    else if set -q _flag_e      # find a file and view it using emm
        emm (find $argv[1] -name "*$argv[2]*" | fzf)
    else if set -q _flag_x      # find a file and view it using emx
        emx (find $argv[1] -name "*$argv[2]*" | fzf)
    else if set -q _flag_c      # find a folder and try cd into it
        cd (find $argv[1] -type d -name "*$argv[2]*" | fzf)
    else if set -q _flag_p      # find a file/folder and copy/echo its path
        if not test $DISPLAY
            readlink -f (find $argv[1] -name "*$argv[2]*" | fzf)
        else
            find $argv[1] -name "*$argv[2]*" | fzf | xc
        end
    else if set -q _flag_g      # find all the .git directory
        if set -q $argv[1]      # no argument
            find . -type d -name .git | sort
        else
            find $argv[1] -type d -name .git | sort
        end
    else
        if set -q $argv[2]      # no argv[2]
            find . -name "*$argv[1]*"
        else
            find $argv[1] -name "*$argv[2]*"
        end
    end
end
function fts -d 'find the temporary files such as a~ or #a or .a~, and files for latex, if no argv is passed, use the current dir'
    set -l options 'c' 'C' 'r' 'R' 'l'
    argparse -n fts $options -- $argv
    or return

    if set -q $argv[1]          # no ARGV
        set ARGV "."
    else
        set ARGV $argv
    end
    if set -q _flag_c           # one level, not recursive, print
        find $ARGV -maxdepth 1 \( -name "*~" -o -name "#?*#" -o -name ".#?*" -o -name "*.swp" \) | xargs -r ls -lhd | nl
    else if set -q _flag_C      # one level, not recursive, remove
        find $ARGV -maxdepth 1 \( -name "*~" -o -name "#?*#" -o -name ".#?*" -o -name "*.swp" \) | xargs rm -rfv
    else if set -q _flag_r      # recursive, print
        find $ARGV \( -name "*~" -o -name "#?*#" -o -name ".#?*" -o -name "*.swp" \) | xargs -r ls -lhd | nl
    else if set -q _flag_R      # recursive, remove
        find $ARGV \( -name "*~" -o -name "#?*#" -o -name ".#?*" -o -name "*.swp" \) | xargs rm -rfv
    else if set -q _flag_l      # remove temporary files for latex
        if not find $ARGV -maxdepth 1 -name "*.tex" | egrep '.*' # normal find returns 0 no matter what
            echo "$ARGV is not a LaTeX directory!"
            return
        end
        for EXT in ind ilg toc out idx aux fls log fdb_latexmk nav snm
            # ind ilg toc out idx aux fls log fdb_latexmk faq blg bbl brf nlo dvi ps lof pdfsync synctex.gz
            find $ARGV -maxdepth 1 \( -name "*.$EXT"  -o -name "auto" \) | xargs -r rm -rv
        end
        fts -C
    end
end
function findn --description 'find the new files in the whole system, argv[1] is the last mins, argv[2] is the file name to search'
    sudo find / -type f -mmin -$argv[1] | sudo ag $argv[2]
end

# du
alias du 'du -h --apparent-size'
abbr dul 'sudo du --summarize -h -c /var/log/* | sort -h'
function dus
    if test (count $argv) -gt 1 # $argv contains /* at the end of path
        du -cs $argv | sort -h
    else
        du -cs $argv
    end
end
function duss --description 'list and sort all the files recursively by size'
    du -ah $argv | grep -v "/\$" | sort -rh
end

abbr watd 'watch -d du --summarize'
function watch -d 'wrap default watch to support aliases and functions'
    while test 1
        date; eval $argv
        sleep 1; echo
    end
end
# abbr df '/bin/df -hT -x tmpfs -x devtmpfs'
alias df 'df -Th | grep -v grep | grep -v tmpfs | grep -v boot | grep -v var | grep -v snapshots | grep -v opt | grep -v tmp | grep -v srv | grep -v usr | grep -v user'
# stop less save search history into ~/.lesshst
# or LESSHISTFILE=-
# set -gx LESSHISTFILE /dev/null $LESSHISTFILE
function m
    # check if argv[1] is a number
    # `m 100 filename` (not +100)
    # BUG: after viewing the right line, any navigation will make point back to the beginning of the file
    if echo $argv[1] | awk '$0 != $0 + 0 { exit 1 }'
        less -RM -s +G$argv[1]g $argv[2]
    else
        less -RM -s +Gg $argv
    end
end
#more
abbr me 'm $EMACS_EL'
abbr mh 'm /etc/hosts'
abbr m2 'm ~/Recentchange/TODO'
abbr mf 'm $FISH_CONFIG_PATH'
#
alias less 'less -x4 -RM -s +Gg' # -x4 to set the tabwidth to 4 instead default 8
abbr lesst 'less ~/.tmux.conf'
abbr lessf 'less $FISH_CONFIG_PATH'
abbr lesse 'less $EMACS_EL'
abbr lessv 'less ~/.vim/vimrc'
abbr lessem 'less ~/.local/bin/emm'

# # color in less a code file
# if command -sq pygmentize # check if command pygmentize exists
#     set -gx LESSOPEN '| pygmentize -g %s'
# else if test -e /usr/bin/src-hilite-lesspipe
#     # if pygmentize not working, use source-highlight instead
#     # if less gets stuck when opening a file, comment out this LESSOPEN line
#     set -gx LESSOPEN '| /usr/bin/src-hilite-lesspipe.sh %s'
# else if test -e /usr/share/source-highlight/src-hilite-lesspipe.sh
#     set -gx LESSOPEN '| /usr/share/source-highlight/src-hilite-lesspipe.sh %s'
# else if test -e $HOME/anaconda3/bin/src-hilite-lesspipe.sh
#     set -gx LESSOPEN '| eval $HOME/anaconda3/bin/src-hilite-lesspipe.sh %s'
# end
# nums are explained at
# http://www.tuxarena.com/2012/04/tutorial-colored-man-pages-how-it-works/
set -gx LESS_TERMCAP_me \e'[0m' # turn off all appearance modes (mb, md, so, us)
set -gx LESS_TERMCAP_se \e'[0m' # leave standout mode
set -gx LESS_TERMCAP_ue \e'[0m' # leave underline mode
set -gx LESS_TERMCAP_so \e'[01;44m' # standout-mode – info
set -gx LESS_TERMCAP_mb \e'[01;31m' # enter blinking mode
set -gx LESS_TERMCAP_md \e'[01;38;5;75m' # enter double-bright mode
set -gx LESS_TERMCAP_us \e'[04;38;5;200m' # enter underline mode
#########################################
# Colorcodes:
# Black           0;30     Dark Gray     1;30
# Red         0;31     Light Red     1;31
# Green           0;32     Light Green   1;32
# Brown           0;33     Yellow        1;33
# Blue        0;34     Light Blue    1;34
# Purple      0;35     Light Purple      1;35
# Cyan        0;36     Light Cyan    1;36
# Light Gray  0;37     White         1;37
#########################################

# color in man page
set -gx MANPAGER 'less -s -M +Gg -i'
# color in man page and less
# without this line, the LESS_TERMCAP_xxx won't work in Fedora
set -gx GROFF_NO_SGR yes
# other major details goto the end of the this file

abbr ifw 'ifconfig wlp5s0'
abbr mpp "ip route get 1.2.3.4 | cut -d' ' -f8 | head -1"
abbr mppa "ifconfig | sed -En 's/127.0.0.1//;s/.inet (addr:)?(([0-9].){3}[0-9])./\2/p'"
# abbr nl 'nload -u H p4p1'
abbr nll 'nload -u H wlp8s0'
abbr nh 'sudo nethogs wlp5s0'
# =ifconfig= is obsolete! For replacement check =ip addr= and =ip link=. For statistics use =ip -s link=.
# abbr ipp 'ip -4 -o address'
abbr ipp 'ip addr'
abbr tf 'traff wlan0'
abbr m-c 'minicom --color=on'
function tree
    if test -f /usr/bin/tree
        command tree -Cshf $argv
    else
        find $argv
        echo -e "\n...tree is not installed, use find instead..."
    end
end

# j for .bz2, z for .gz, J for xz, a for auto determine
function tars -d 'tar extract(x)/list(l)/create(l, add extra arg to include .git dir), or others using dtrx(d)'
    set -l options 'x' 'l' 'c' 'd'
    argparse -n tars $options -- $argv
    or return

    if set -q _flag_x           # extract
        tar xvfa $argv
    else if set -q _flag_l      # list contents
        tar tvfa $argv
    else if set -q _flag_c      # create archive
        # remove the end slash in argv
        set ARGV (echo $argv[1] | sed 's:/*$::')
        if test (count $argv) = 1
            tar cvfa $ARGV.tar.xz $ARGV --exclude-vcs
        else
            tar cvfa $ARGV.tar.xz $ARGV
        end
    else if set -q _flag_d
        if command -sq dtrx
            dtrx -v $argv
        else
            echo "dtrx command is not installed!"
        end
    end
end
# using unar -- https://unarchiver.c3.cx/unarchiver is available
# if the code is not working, try GBK or GB18030
# unzip zip if it is archived in Windows and messed up characters with normal unzip
abbr unzipc 'unzip -O CP936'
function zips -d 'zip to list(l)/extract(x)/create(c)'
    set -l options 'l' 'L' 'c' 'x' 'X'
    argparse -n zips $options -- $argv
    or return

    for a in $argv
        if set -q _flag_l           # list
            unzip -l $a
        else if set -q _flag_L      # list Chinese characters
            zips.py -l $a
        else if set -q _flag_x
            unzip -e $a
        else if set -q _flag_X      # extract Chinese characters
            zips.py -x $a
        else if set -q _flag_c
            # remove the end slash in argv
            set ARGV (echo $a | sed 's:/*$::')
            zip -r $ARGV.zip $ARGV
        end
    end
end
function deb -d 'deb package, list(default)/extract(x)'
    set -l options 'x'
    argparse -n deb $options -- $argv
    or return

    if set -q _flag_x           # extract
        set pkgname (basename $argv[1] .deb)
        mkdir -v $pkgname
        if command -sq dpkg # check if dpkg command exists, replace which
            dpkg -x $argv[1] $pkgname
        else
            set dataname (ar t $argv[1] | ag data)
            if not ar p $argv[1] $dataname | tar Jxv -C $pkgname ^/dev/null # failed, $status != 0
                if not ar p $argv[1] $dataname | tar zxv -C $pkgname ^/dev/null # failed, $status != 0
                    rm -rfv $pkgname
                    return
                end
            end
        end
        echo ----in $pkgname ----
    else                        # default, list
        dpkg -c $argv
    end
end

alias wget 'wget -c --no-check-certificate'
abbr wgets 'wget -c --mirror -p --html-extension --convert-links'
abbr wt 'bash -c \'rm -rf /tmp/XLN* 2>/dev/null\'; wget -c -P /tmp/ http://down.sandai.net/XLNetAcc/XLNetAccSetup.exe'
abbr wtt 'bash -c \'rm -rf /tmp/XMPS* 2>/dev/null\'; wget --connect-timeout=5 -c -P /tmp/ http://xmp.down.sandai.net/xmp/XMPSetup_5.4.5.6478.exe'
# curl -L -O -C - https://site.com/file.iso
abbr a2 'aria2c -c -x 5 --check-certificate=false --file-allocation=none'

# rpm
function rpms -d 'rpm file, install(i)/extract(x)/list(default)'
    set -l options 'i' 'x'
    argparse -n rpms $options -- $argv
    or return

    if set -q _flag_i           # install
        sudo rpm -Uvh $argv
    else if set -q _flag_x      # extract
        for i in $argv
            echo \<$i\>
            echo -------------------
            rpm2cpio $i | cpio -idmv
        end
    else                        # default list
        for i in $argv
            rpm -qlpv $i
        end
    end
end

# yum
abbr yum   'sudo yum -C --noplugins' # not update cache
abbr yumi  'sudo yum install'
abbr yumiy 'sudo yum install -y'
abbr yumr  'sudo yum remove'
abbr yumri 'sudo yum reinstall -y'
abbr yumca 'sudo yum clean all -v'
abbr yumu  'sudo yum --exclude=kernel\* upgrade' # this line will be '=kernel*' in bash
abbr yumuk 'sudo yum upgrade kernel\*'
abbr yumue 'sudo yum update --exclude=kernel\*'
abbr yumul 'sudo yum history undo last'
abbr yumhl 'sudo yum history list'
abbr yumun 'sudo yum history undo'
abbr yums  'sudo yum search'
abbr yumsa 'sudo yum search all'
# dnf
abbr dnfu 'sudo dnf update -v'
abbr dnfU 'sudo dnf update --setopt exclude=kernel\* -v'
abbr dnfu2 'sudo dnf update -y --disablerepo="*" --enablerepo="updates"'
abbr dnfc 'sudo dnf clean all'
abbr dnfi 'sudo dnf install -v'
abbr dnfr 'sudo dnf remove -v'
abbr dnfl 'dnf list installed| less'
abbr dnfs 'sudo dnf search'
abbr dnfsa 'sudo dnf search all'
abbr dnful 'sudo dnf history undo last'

# zypper for openSUSE
abbr zppi 'sudo zypper install --details'
abbr zppiy 'sudo zypper install -y -v --details'
abbr zppif 'sudo zypper info'
abbr zppwp 'sudo zypper search --provides --match-exact' # dependencies
abbr zppr 'sudo zypper remove --details'
abbr zppld 'zypper lr -d' # list repo
abbr zpprr 'sudo zypper rr' # +repo_num in zppld to remove a repo
abbr zpplr 'sudo zypper lr -u --details'
abbr zpps 'sudo zypper search -v'
abbr zppsi 'sudo zypper search -i -v'
abbr zppsd 'sudo zypper search -d -C -i -v' # also search description and summaries
abbr zppu 'sudo zypper update --details'
abbr zppud 'sudo zypper dist-upgrade -l --details'
abbr zppdup 'sudo zypper dist-upgrade -l --details --no-recommends'
abbr zppca 'sudo zypper clean --all'

# apt
abbr api 'sudo apt-get install -V'
abbr apu 'sudo apt-get update; sudo apt-get upgrade -V'
abbr apr 'sudo apt-get remove -V'
abbr apar 'sudo apt-get autoremove -V'
abbr aps 'apt-cache search'

# donnot show the other info on startup
abbr gdb 'gdb -q'
abbr gdbx 'gdb -q -n'         # with loading any .gdbinit file

# systemd-analyze
function sab --description 'systemd-analyze blame->time'
    systemd-analyze blame | head -40
    systemd-analyze time
end

# cd
function ..; cd ..; end
function ...; cd ../..; end
function ....; cd ../../..; end
function .....; cd ../../../..; end
abbr cdp 'cd ~/Public; and lls'
abbr cdu 'cd /run/media/chz/UDISK/; and lls'

# NOTE: this function is obsolete since using Spacemacs now
function elpac -d 'print old packages in .emacs.d/elpa/, with any command, it will clean old ones'
    set -l elpa_path ~/.emacs.d/elpa
    # ls contains color which will affect the $pkg string, * part means only directories
    for pkg in (command ls $elpa_path)
        if echo $pkg | grep -q '[0-9]' # check if pkg $contains version number, $status = 0
            set -l pkg_ver (echo $pkg | sed 's!.*-!!')
            set -l pkg_name (echo $pkg | sed 's/[0-9.]*$//g')

            set pkg_com (echo $pkg_name(echo $pkg_ver | cut -c1))
            if test (command ls $elpa_path | grep "^$pkg_com" | wc -l) -gt 1
                set first (command ls $elpa_path | grep "^$pkg_com" | head -1 | sed "s/$pkg_com//g")
                set second (command ls $elpa_path | grep "^$pkg_com" | sed -n "2p" | sed "s/$pkg_com//g")
                if echo $first$second | grep -q '[a-zA-Z]'
                    continue # files/dirs like let-alias-1.0.5 and let-alias-1.0.5.signed
                end
                # echo pkg: $pkg, first: $first, second:$second
                set first_num (echo $first | sed -e 's/\.//g') # get rid of . in version number
                set second_num (echo $second | sed -e 's/\.//g')
                if test $firstnum -le $secondnum
                    echo $pkg_com$first is le
                    echo $pkg_com$second
                    set old $first
                else
                    echo $pkg_com$first is gt
                    echo $pkg_com$second
                    set old $second
                end
                if not set -q $argv[1]
                    command rm -rf $elpa_path/$pkg_com$old
                    echo $elpa_path/$pkg_com$old is deleted!
                end
                echo
            end
        end
    end
end

function diffs -d "all kinds of diff features"
    set -l options 'f' 'w' 'l' 'L' 'W' 'h'
    argparse -n diffs $options -- $argv
    or return

    if set -q _flag_h
        echo "diffs [-f/-w/-l/-L/-W/-h]"
        echo "      no option --> side by side, only diffs"
        echo "      -f --> like no argument, but print whole files"
        echo "      -w --> like no argument, but ignore all white spaces"
        echo "      -l --> line by line, only diffs"
        echo "      -L --> like -l, but print whole files"
        echo "      -W --> like -l, but ignore all white spaces"
        echo "      -h --> usage"
        return
    else if set -q _flag_f
        diff -r -y -s -W $COLUMNS $argv | less
    else if set -q _flag_w
        diff -r -y -s --suppress-common-line -W $COLUMNS -w $argv | less
    else if set -q _flag_l
        diff -r -s --suppress-common-line -W $COLUMNS $argv | less
    else if set -q _flag_L
        diff -r -s -W $COLUMNS $argv | less
    else if set -q _flag_W
        diff -r -s --suppress-common-line -W $COLUMNS -w $argv | less
    else                        # no option
        diff -r -y -s --suppress-common-line -W $COLUMNS $argv | less
    end
end

function mkcd --description 'mkdir dir then cd dir'
    mkdir -p $argv
    cd $argv
end

# xclip, get content into clipboard, echo file | xclip
alias xc 'xclip -selection c'
abbr xp 'xclip'
abbr rl 'readlink -f'

abbr km 'sudo kermit'

abbr dusc 'dus -c ~/.config/google-chrome ~/.cache/google-chrome ~/.mozilla ~/.cache/mozilla'
abbr gcp 'google-chrome --incognito'
abbr ffp 'firefox -private-window'

abbr cx 'chmod +x'

# netease-play, douban.fm
abbr np 'netease-player'
abbr db 'douban.fm'

#vim
abbr V 'vim -u NONE'
abbr vimc 'vim ~/.cgdb/cgdbrc'
abbr vimm 'vim -u ~/.vim/vimrc.more'
abbr vimv 'vim ~/.vim/vimrc'
abbr vimb 'vim ~/.bashrc'
abbr vime 'vim $EMACS_EL'
abbr vim2 'vim ~/Recentchange/TODO'
abbr vimf 'vim $FISH_CONFIG_PATH'
abbr vimt 'vim ~/.tmux.conf; tmux source-file ~/.tmux.conf; echo ~/.tmux.conf reloaded!'
function vundles -d 'fix the :BundleUpdate error of conflicts problem'
    for dir in ~/.vim/bundle/*
        cd $dir
        echo $PWD
        gitco
        echo
    end
end

# emacs
# -Q = -q --no-site-file --no-splash, which will not load something like emacs-googies
alias emx 'emacs -nw -q --no-splash --eval "(setq find-file-visit-truename t)"'
abbr emq 'emacs -q --no-splash'
abbr emd 'rm -rfv ~/.emacs.d/init.elc; emacs --debug-init'
abbr eml 'emacs -q --no-splash --load' # load specific init.el
abbr emn 'emacs --no-desktop'
abbr eme 'emm $EMACS_EL'
abbr emc 'emm ~/.cgdb/cgdbrc'
abbr emf 'emm $FISH_CONFIG_PATH'
abbr emt 'emm ~/.tmux.conf'
abbr emv 'emm ~/.vimrc'
abbr emb 'emm ~/.bashrc'
abbr em2 'emm ~/Recentchange/TODO'
abbr emtime "time emacs --debug-init -eval '(kill-emacs)'" # time emacs startup time

# C-w to reload $FISH_CONFIG_PATH
#bind \cs fsr

# the gpl.txt can be gpl-2.0.txt or gpl-3.0.txt
abbr lic 'wget -q http://www.gnu.org/licenses/gpl.txt -O LICENSE'

# git
abbr gg 'grv'
abbr lg 'lazygit'
abbr gits 'git status' # gs is original Ghostscript app
abbr gitpl 'git pull -v'
abbr gitpu 'git push -v'
abbr gitl 'git log --stat'
abbr gitd 'git diff'           # show unstaged local modification
abbr gitdc 'git diff' --cached # show staged bu unpushed local modification
abbr gitlp 'git log -p --' # [+ file] to how entire all/[file(even renamed)] history
abbr gitsh 'git show' # [+ COMMIT] to show the modifications in a last/[specific] commit
abbr gitlo 'git log --oneline'
abbr gitb 'git branch'
abbr gitcl 'git config -l'
abbr gitcp 'git checkout HEAD^1' # git checkout previous/old commit
abbr gitcn 'git log --reverse --pretty=%H master | grep -A 1 (git rev-parse HEAD) | tail -n1 | xargs git checkout' # git checkout next/new commit
abbr gitcm 'git commit -m'
abbr gitt 'git tag'
abbr gitft 'git ls-files --error-unmatch' # Check if file/dir is git-tracked
function gitc -d 'git clone and cd into it'
    git clone -v $argv
    echo ---------------------------
    if test (count $argv) -eq 2
        set project $argv[2]
    else
        set project (basename $argv .git) # this works when $argv contains or not contains .git
    end
    cd $project
    echo cd ./$project
end
function gitpa --description 'git pull all in dir using `fing dir`'
    for i in (find $argv[1] -type d -name .git | sort | xargs realpath)
        cd $i; cd ../
        pwd
        git pull -v;
        echo -----------------------------
        echo
    end
end
function gitco -d 'git checkout -- for multiple files at once, default all files'
    # when you copy/paste using mouse, the strings you pasted are not seprated by space ACTUALLY, using ','
    if set -q $argv # no given files
        git checkout .
    else
        set -l files (echo $argv | tr ',' '\n')
        for i in $files
            echo 'git checkout -- for file' $i
            git checkout -- $i
        end
    end
end
function gita -d 'git add for multiple files at once'
    if set -q $argv # no given files
        git add .
    else
        set -l files (echo $argv | tr ',' '\n')
        for i in $files
            echo 'git add for file:' $i
            git add $i
        end
    end
end
function gitrh -d 'git reset HEAD for multiple files(file1 file2), soft(-s)/hard(-h) reset'
    set -l options 's' 'h'
    argparse -n gitrh $options -- $argv
    or return

    if set -q _flag_s # undo last unpushed commit, keeps changes
        git reset --soft HEAD~1
    else if set -q _flag_h # undo last unpushed commit, delete changes
        git reset --hard HEAD~1
    else
        set -l files (echo $argv | tr ',' '\n')
        for i in $files
            echo 'git reset HEAD for file:' $i
            git reset HEAD $i
        end
    end
end

function gitdl -d 'download several files from github'
    set -l options 'f' 'g' 's' 'z' 'h'
    argparse -n gitdl $options -- $argv
    or return

    if set -q _flag_h
        echo "gitdl [-f/-g/-z/-s/-h]"
        echo "      no option --> once for all"
        echo "      -f --> fzf"
        echo "      -g --> grv"
        echo "      -s --> scc"
        echo "      -z --> z.lua"
        echo "      -h --> usage"
        return
    else if set -q _flag_f
        echo "Update/Download fzf..."
        fzfp u
    else if set -q _flag_g
        echo "Update/Download grv..."
        grvp u
    else if set -q _flag_s
        echo "Update/Download scc..."
        sccp u
    else if set -q _flag_z
        echo "Update/Download z.lua..."
        zp u
    else                        # no option
        read -n 1 -p 'echo "Update/Download all of fzf, grv, scc, and z.lua from github? [Y/n]: "' -l arg
        if test "$arg" = "" -o "$arg" = "y" -o "$arg" = " "
            echo "Update/Download fzf..."
            fzfp u

            echo "Update/Download grv..."
            grvp u

            echo "Update/Download scc..."
            sccp u

            echo "Update/Download z.lua..."
            zp u
        else
            echo "Quit to update/download all of fzf, grv, scc and z.lua from github!!!"
        end
    end
end

function grvp -d 'check if grv exists, or without any argument, download the latest version'
    if command -sq grv; and set -q $argv[1] # grv is in $PATH, and no any argv is given, two conditions
        # echo "grv is installed, use any extra to upgrade it!"
        return 0
    else
        # https://github.com/rgburke/grv/releases/download/v0.3.2/grv_v0.3.2_linux64
        set tag_name (curl -s "https://api.github.com/repos/rgburke/grv/releases/latest" | grep "tag_name" | cut -d : -f 2 | awk -F[\"\"] '{print $2}')
        if not test $tag_name
            echo "API rate limit exceeded, please input your password for your username!"
            set tag_name (curl -u c02y -s "https://api.github.com/repos/rgburke/grv/releases/latest" | grep "tag_name" | cut -d : -f 2 | awk -F[\"\"] '{print $2}')
        end
        set file_name (echo grv_v(echo $tag_name | sed 's/^v//')_linux64)
        set file_link (echo https://github.com/rgburke/grv/releases/download/$tag_name/$file_name)
        wget $file_link -O /tmp/$file_name
        if test -f /tmp/$file_name
            install -v -m 755 /tmp/$file_name ~/.local/bin/grv
        else
            echo "grv doesn't exist and error occurs when downloading it!"
            return 1
        end
    end

end
function sccp -d 'check if scc exists, or without any argument, download the latest version'
    if command -sq scc; and set -q $argv[1] # scc is in $PATH, and no any argv is given, two conditions
        # echo "scc is installed, use any extra to upgrade it!"
        return 0
    else
        # https://github.com/boyter/scc/releases/download/v2.2.0/scc-2.2.0-x86_64-unknown-linux.zip
        set tag_name (curl -s "https://api.github.com/repos/boyter/scc/releases/latest" | grep "tag_name" | cut -d : -f 2 | awk -F[\"\"] '{print $2}')
        if not test $tag_name
            echo "API rate limit exceeded, please input your password for your username!"
            set tag_name (curl -u c02y -s "https://api.github.com/repos/boyter/scc/releases/latest" | grep "tag_name" | cut -d : -f 2 | awk -F[\"\"] '{print $2}')
        end
        set file_name (echo scc-(echo $tag_name | sed 's/^v//')-x86_64-unknown-linux.zip)
        set file_link (echo https://github.com/boyter/scc/releases/download/$tag_name/$file_name)
        wget $file_link -O /tmp/$file_name
        if test -f /tmp/$file_name
            unzip -e /tmp/$file_name -d ~/.local/bin/
            return 0
        else
            echo "scc doesn't exist and error occurs when downloading it!"
            return 1
        end
    end
end

# svn
abbr svnp 'svn update; and echo "---status---"; svn status'
abbr svnpn 'svn update ~/NVR.ori/Code'
abbr svns 'svn status'
abbr svnc 'svn commit -m'
abbr svnd 'svn diff | less'
abbr svnll 'svn log -v -l 10 | less'
function svncf -d 'view old version of a file'
    svn cat -r $argv[1] $argv[2] | less
end
function svnl --description 'view the svn log with less, if arg not passed, using current dir'
    svn log -v $argv[1] | /usr/bin/less
end
function svnlh
    svn log -v $argv[1] | head -$argv[2]
end
function svndd --description 'show the svn diff detail'
    # the revision of whole svn project
    # set Revision (svn info | awk '/Revision/ {print $2}')
    # the revision of current directory
    set Revision (svn log | grep "^r[0-9]\+ | " | cut -d' ' -f1 | cut -c2- | sed -n "1p")
    # TODO: check if argv is 1)integer, 2)number between $Revision and 1 if given
    if test (echo $argv[1] | grep ':' -c) -eq 1
        # if argv is like 1000:1010, then svn diff the two revisions
        svn diff -r $argv[1] | less
    else if test (count $argv) -eq 1
        if test $argv[1] -gt 10
            # if the argv is like 1000, then svn diff revision
            svn diff -c $argv[1] | less
        else
            # if the argv is like 3, the svn diff the 3th commit to the last
            # the PREV is 1
            # if the list of revision is continuous
            # set Rev (echo $Revision-$argv[1]+1 | bc)
            # whether the list is continuous or not
            set Rev (svn log | grep "^r[0-9]\+ | " | cut -d' ' -f1 | cut -c2- | sed -n "$argv[1]p")
            svn diff -c $Rev | less
        end
    else if test (count $argv) = 0
        if test (svn status | wc -l) != 0
            # show the diff if local differs from server
            svn status # in case there are new files
            svn diff | less
        else
            # if no argv is given, and status is clean then svn diff the last commit
            # equals to `svndd` == `svndd 1`
            svn diff -r PREV | less
        end
    else
        echo Arguments are wrong!!!
    end
end

abbr hs 'sudo cp -v ~/Public/hosts/hosts /etc/hosts'

# https://stackoverflow.com/questions/10408816/how-do-i-use-the-nohup-command-without-getting-nohup-out
function meld --description 'lanuch meld from terminal without block it'
    # You could just use
    # bash -c "(nohup /usr/bin/meld $argv </dev/null >/dev/null 2>&1 &)"
    # But it will not work if the name of arguments contains space
    # \"$argv\" like in `ok` does not work for multiple arguments even no space
    set -l argc (count $argv)
    switch $argc
        case 0
            /usr/bin/meld
        case 1
            echo "This is version control comparison, use `command meld file/dir`"
        case 2
            bash -c "(nohup /usr/bin/meld \"$argv[1]\" \"$argv[2]\" </dev/null >/dev/null 2>&1 &)"
        case 3
            bash -c "(nohup /usr/bin/meld \"$argv[1]\" \"$argv[2]\" \"$argv[3]\" </dev/null >/dev/null 2>&1 &)"
        case '*'
            echo Wrong arguments!!!
    end
    return
end
# okular
abbr ok 'bash -c "(nohup okular \"$argv\" </dev/null >/dev/null 2>&1 &)"'
abbr ima 'bash -c "(nohup gwenview \"$argv\" </dev/null >/dev/null 2>&1 &)"'
abbr op 'bash -c "(nohup xdg-open \"$argv\" </dev/null >/dev/null 2>&1 &)"'
abbr fcg 'fc-list | ag'

function wc
    if test (count $argv) -gt 1
        command wc $argv | sort -n
    else
        command wc $argv
    end
end

abbr st 'stow -DRv'

abbr ptp 'ptipython'
# install pytest and pytest-pep8 first, to check if the code is following pep8 guidelines
abbr pyp8 'py.test --pep8'

# abbr rea 'sudo ~/.local/bin/reaver -i mon0 -b $argv[1] -vv'
# function rea
# sudo ~/.local/bin/reaver -i mon0 -b $argv
# end

abbr epub 'ebook-viewer --detach'
alias time 'time -p'
abbr ex 'exit'
abbr x 'exit'

abbr sss 'ps -eo tty,command | grep -v grep | grep "sudo ssh "'
abbr p 'ping -c 5'
alias ping 'ping -c 5'
function po -d 'Test the connection of outside internet'
    if not timeout 1 ping... # failed, $status != 0
        echo Offline!
    else
        echo Online!
    end
end
function pl -d 'Test the connection of inside internet'
    if test (count $argv) -eq 1
        if not timeout 1 ping -c 1 10.8.2.$argv ^/dev/null >/dev/null
            echo Offline!
        else
            echo Online!
        end
    else
        if not timeout 1 ping -c 1 10.0.4.4 ^/dev/null >/dev/null
            echo Offline!
        else
            echo Online!
        end
    end
end
function pv --description "ping vpn servers"
    p p1.jp1.seejump.com | tail -n3
    echo --------------------------------------------------------------
    p p1.jp2.seejump.com | tail -n3
    echo --------------------------------------------------------------
    p p1.jp3.seejump.com | tail -n3
    echo --------------------------------------------------------------
    p p1.jp4.seejump.com | tail -n3
    echo --------------------------------------------------------------
    p p1.hk1.seejump.com | tail -n3
    echo --------------------------------------------------------------
    p p1.hk2.seejump.com | tail -n3
    echo --------------------------------------------------------------
    p p1.hk3.seejump.com | tail -n3
    echo --------------------------------------------------------------
end
function ipl -d 'get the location of your public IP address'
    if test (ps -ef | grep -v grep | grep -i shadow | awk '{ print $(NF-2)     }') # ssr is running
        proxychains4 curl myip.ipip.net
    else
        curl myip.ipip.net
    end
end
function port -d 'list all the ports are used or check the process which are using the port'
    if test (count $argv) = 1
        netstat -tulpn | grep $argv
    else
        netstat -tulpn
    end
end
abbr px 'proxychains4'

abbr lo 'locate -e'
function lop --description 'locate the full/exact file'
    locate -e -r "/$argv[1]\$"
end
function findn --description 'find the new files in the whole system, argv[1] is the last mins, argv[2] is the file name to search'
    sudo find / -type f -mmin -$argv[1] | sudo ag $argv[2]
end

# bc -- calculator
function bc --description 'calculate in command line using bc non-interactive mode if needed, even convert binary/octual/hex'
    if test (count $argv) -eq 0
        /usr/bin/bc -ql
    else
        # TODO: fish won't recognize command like `bc 2*3`, you have to quote it or use `bc 2\*3`
        for i in $argv
            echo $i:
            echo -ne "\t"
            echo -e $i | /usr/bin/bc -l
        end
    end
end
# more examples using bc
# http://www.basicallytech.com/blog/archive/23/command-line-calculations-using-bc/
#1 convert 255 from base 10 to base 16
# echo 'obase=16; 255' | bc
# use `bcc 'obase=16; 255'` directly
#2 convert hex FF (not ff) from base 16 to binary
# echo 'obase=2; FF' | bc
#3 convert binary 110 from binary to hex
# echo 'ibase=2;obase=A;110' | bc
# not 16 or a but A means hex
#4 convert from hexadecimal to decimal ; 3 and 4 are weird
# echo 'ibase=16;obase=A;FF' | bc
#5 convert hex to octual
# echo 'F' | bc

function catt
    if test (count $argv) -gt 1
        for i in $argv
            echo -e "\\033[0;31m"\<$i\>
            echo -e ------------------------------------------------- "\\033[0;39m"
            /bin/cat $i
            echo
        end
    else
        /bin/cat $argv
    end
end

function deff
    echo "-1\n" | sdcv $argv | head -n 1 | grep ", similar to " ^/dev/null >/dev/null
    if test $status = 0         # Found exact words or similar
        echo "-1\n" | sdcv $argv | head -n 2 | tail -n 1 | grep "^-->" ^/dev/null >/dev/null
        if test $status = 0     # Exact definition
            sdcv $argv
        else                    # similar
            echo "-1\n" | sdcv $argv | head -n 1 | grep $argv
            # 1th, send -1 to prompt; 3th, delete last line; 4th, delete first line;
            # 5th, get last part after ">"; 5th & 6th, delete duplicates;
            # 7th, combine and separate multiple lines (words) with ", "
            # 8th, delete last ", "
            echo "-1\n" | sdcv $argv | head -n -1 | tail -n +2 | cut -d ">" -f 2 | sort | uniq | awk 'ORS=", "' | sed 's/, $/\n/'
        end
    else                        # Nothing similar
        sdcv $argv
    end
    # NOTE: double quotes in sed, single quotes does not work
    sed -i "/\<$argv\>/d" ~/.sdcv_history # delete the word in ~/.sdcv_history
end
function SDCV
    sdcv -u "WordNet" -u "牛津现代英汉双解词典" -u "朗道英汉字典5.0" $argv
    sort -u -o ~/.sdcv_history ~/.sdcv_history # sort and unique them
end
function defc_new -d 'Check if the word is new in ~/.sdcv_history, if new add it'
    grep -w $argv ~/.sdcv_history >> /dev/null
    or begin # new, not searched the dict before, save
        if not test -e ~/.sdcv_rem
            touch ~/.sdcv_rem
        end
        echo ---------------------------------------------- >> ~/.sdcv_rem
        echo -e \< $argv \> >> ~/.sdcv_rem
        echo ---------------------------------------------- >> ~/.sdcv_rem
        SDCV $argv >> ~/.sdcv_rem
        echo ---------------------------------------------- >> ~/.sdcv_rem
        echo >> ~/.sdcv_rem
    end
end
function defc --description 'search the defnition of a word and save it into personal dict if it is the first time you search'
    echo "-1\n" | SDCV $argv | head -n 1 | grep ", similar to " ^/dev/null >/dev/null
    if test $status = 0         # Found exact words or similar
        echo "-1\n" | SDCV $argv | head -n 2 | tail -n 1 | grep "^-->" ^/dev/null >/dev/null
        if test $status = 0     # Exact definition
            SDCV $argv
            defc_new $argv
        else                    # similar
            echo "-1\n" | SDCV $argv | head -n 1 | grep $argv
            echo "-1\n" | SDCV $argv | head -n -1 | tail -n +2 | cut -d ">" -f 2 | sort | uniq | awk 'ORS=", "' | sed 's/, $/\n/'
            sed -i "/\<$argv\>/d" ~/.sdcv_history # delete the wrong word in ~/.sdcv_history
        end
    else                        # Nothing similar
        SDCV $argv
        sed -i "/\<$argv\>/d" ~/.sdcv_history # delete the wrong word in ~/.sdcv_history
    end
end

# count chars of lines of a file
# awk '{ print length }' | sort -n | uniq -c

# note that there is no $argv[0], the $argv[1] is the first argv after the command name, so the argc of `command argument` is 1, not 2
function man
    if test (count $argv) -eq 2
        #sed -i "s/.shell/\"$argv[2]\n.shell/g" ~/.lesshst
        echo "\"$argv[2]" >> ~/.lesshst
    else
        #sed -i "s/.shell/\"$argv[1]\n.shell/g" ~/.lesshst
        echo "\"$argv[1]" >> ~/.lesshst
    end
    command man $argv
end
abbr ma 'man'

function wtp --description 'show the real definition of a type or struct in C code, you can find which file it is defined in around the result'
    gcc -E ~/.local/bin/type.c -I$argv[1] > /tmp/result
    if test (count $argv) -eq 2
        if test (echo $argv[1] | grep struct)
            ag -A $argv[2] "^$argv[1]" /tmp/result
        else
            ag -B $argv[2] $argv[1] /tmp/result
        end
    else
        ag $argv[1] /tmp/result
    end
end

# if usb0 is not connected or data sharing is not enabled:
# `ip link ls dev usb0` returns 255, else returns 0
# if usb0 is not connected to network:
# `ip link ls dev usb | grep UP` returns 1, else returns 0
# if returns 1, then kill dhclient and enabled dhclient again:
# sudo dhclient usb0
function ut -d 'toggle -- use data network sharing through Android device throught USB'
    ip link ls dev usb0 ^/dev/null >/dev/null
    if not ip link ls dev usb0 ^/dev/null >/dev/null0 # ()=255, not plugged or enabled in Android device
        echo Android device is not plugged or data network sharing is not enabled!
    else          # ()=0
        # ip link ls dev usb0 | grep UP ^/dev/null >/dev/null
        # if test $status != 0
        if test 1 != 0
            # echo Network on usb0 is off!
            if test (pgrep dhclient | wc -l) != 0 # This will be useless since the latter kill
                echo dhclient is already running, Kill it!
                echo "      " | sudo -p "" -S pkill dhclient
            end
            echo Starting `dhclient usb0`
            echo "      " | sudo -p "" -S dhclient usb0
            # something it will fail, output error message like
            # dhclient(26477) is already running - exiting....
            if test $status != 0
                sudo dhclient -r
                sudo dhclient
                sudo pkill dhclient
            end
        else
            # echo Network on usb0 is already on!
        end
        if test (pgrep dhclient | wc -l) != 0
            sudo pkill dhclient  # this has no effect on the network, just make next usbt quicker
        end
    end
end

abbr um 'pumount /run/media/chz/UDISK'
abbr mo 'pmount /dev/sdb4 /run/media/chz/UDISK'
function mo-bak
    set -l done 1
    while test $done = 1
        if not command df | grep -v grep | grep -i UDISK  ^/dev/null >/dev/null # no UDISK in df, new or unplug
            set -l device
            if test -b /dev/sdb4
                set device /dev/sdb4
            else if test -b /dev/sdc4
                set device /dev/sdc4
            else
                echo Please plug your USB drive!!!
                return
            end
            pmount $device /media/UDISK
            df
            return
        else                        # UDISK is in df, right or not-umount old
            set -l device (command df | grep -v grep | grep -i UDISK | awk '{print $1}')
            if not test -b $device
                if not pumount /media/UDISK ^/dev/null >/dev/null
                    echo $device -- /media/UDISK is busy.
                    lsof | ag UDISK
                    return
                end
            else                    # right
                echo Device /dev/sdb4 is already mounted to /media/UDISK
                return
            end
        end
    end
end

abbr ytd 'youtube-dl -citw'

function agr -d 'ag errno'
    for file in /usr/include/asm-generic/errno-base.h /usr/include/asm-generic/errno.h
        command ag -w $argv[1] $file
    end
end
# ag work with less with color and scrolling
function ag
    #sed -i "s/.shell/\"$argv[1]\n.shell/g" ~/.lesshst
    echo "\"$argv[1]" >> ~/.lesshst
    if command -sq ag # check if ag command exists
        command ag --ignore '*~' --ignore '#?*#' --ignore '.#?*' --ignore '*.swp' --ignore -s --pager='less -RM -FX -s' $argv
    else
        grep -n --color=always $argv | more
        echo -e "\n...ag is not installed, use grep instead..."
    end
end
function ags -d 'ag sth in a init.el(-e)/config.fish(-f)/.tmux.conf(-t)/vimrc(-v), or use vim(-V)/emm(-E) to open the file'
    set -l options 'e' 'E' 'f' 't' 'v' 'V'
    argparse -n ags -N 1 $options -- $argv
    or return

    if set -q _flag_e
        ag $argv[1] $EMACS_EL
    else if set -q _flag_E
        ag $argv[1] $argv[2]
        echo
        read -n 1 -p 'echo "Open it with emm? [Y/n]: "' -l answer
        if test "$answer" = "y" -o "$answer" = " "
            emm (command ag -l $argv[1] $argv[2] | fzf)
        end
    else if set -q _flag_f
        ag $argv[1] $FISH_CONFIG_PATH
    else if set -q _flag_t
        ag $argv[1] ~/.tmux.conf
    else if set -q _flag_v
        ag $argv[1] ~/.vim/vimrc
    else if set -q _flag_V
        ag $argv[1] $argv[2]
        echo
        read -n 1 -p 'echo "Open it with vim? [Y/n]: "' -l answer
        if test "$answer" = "y" -o "$answer" = " "
            vim (command ag -l $argv[1] $argv[2] | fzf)
        end
    end
end

# ls; and ll -- if ls succeed then ll, if failed then don't ll
# ls; or ll -- if ls succeed then don't ll, if failed then ll

# such as:
# abbr sp 'svn update; and echo "---status---"; svn status'

# if test $status -eq 0; ... else ... # success
# to
# and begin ... end; or ...

# if test $status -eq 1; ... else ... # failure
# to
# or begin ... end; or ...

function bkm -d 'backups manager: rename files/dirs from name to name.bak or backwards(-b) using cp/mv(-m)'
    # set optional options
    set -l options 'b' 'm'
    argparse -n bkm -N 1 $options -- $argv
    or return

    set -l backward 0 # 0(name->name.bak), 1(backward, name.bak->name)
    set -l CMD cp -vr # 0(cp), 1(mv)
    if set -q _flag_b
        set backward 1
    end
    if set -q _flag_m
        set CMD mv -v
    end

    for name in $argv # support multiple arguments
        if test $backward = 1
            set -l result (echo (string split -r -m1 .bak $name)[1])
            if test -e $result
                echo $result alread exists.
            else
                eval $CMD $name $result
            end
        else
            set old $name
            if test "/" = (echo (string sub --start=-1 $name)) # for dir ending with "/"
                set old (echo (string split -r -m1 / $name)[1])
            end
            if test -e $old.bak
                echo $old.bak already exists.
                read -n 1 -l -p 'echo "Remove $old.bak first? [y/N]"' answer
                if test "$answer" = "y" -o "$answer" = " "
                    rm -rfv $old.bak
                else
                    continue
                end
            end
            eval $CMD $old{,.bak}
        end
    end
end

function d --description "Choose one from the list of recently visited dirs"
    # this function is introduced into fish-shell release since v2.7b1, called `cdh` (mostly similar)
    # See if we've been invoked with an argument. Presumably from the `cdh` completion script.
    # If we have just treat it as `cd` to the specified directory.
    if set -q argv[1]
        cd $argv
        return
    end

    if set -q argv[2]
        echo (_ "d: Expected zero or one arguments") >&2
        return 1
    end


    set -l all_dirs $dirprev $dirnext
    if not set -q all_dirs[1]
        echo (_ 'No previous directories to select. You have to cd at least once.') >&2
        return 0
    end

    # Reverse the directories so the most recently visited is first in the list.
    # Also, eliminate duplicates; i.e., we only want the most recent visit to a
    # given directory in the selection list.
    set -l uniq_dirs
    for dir in $all_dirs[-1..1]
        if not contains $dir $uniq_dirs
            set uniq_dirs $uniq_dirs $dir
        end
    end

    set -l letters - b c d e f h i j k l m n o p q r s t u v w x y z
    set -l dirc (count $uniq_dirs)
    if test $dirc -gt (count $letters)
        set -l msg 'This should not happen. Have you changed the cd command?'
        printf (_ "$msg\n")
        set -l msg 'There are %s unique dirs in your history' \
        'but I can only handle %s'
        printf (_ "$msg\n") $dirc (count $letters)
        return 1
    end

    # Print the recent directories, oldest to newest. Since we previously
    # reversed the list, making the newest entry the first item in the array,
    # we count down rather than up.
    # already_pwd avoid always print the bottom line *pwd:...
    set -l pwd_existed 0
    for i in (seq $dirc -1 1)
        set dir $uniq_dirs[$i]

        if test $pwd_existed != 1
            if test "$dir" = "$PWD"
                set pwd_existed 1
            end
        end

        set -l home_dir (string match -r "$HOME(/.*|\$)" "$dir")
        if set -q home_dir[2]
            set dir "~$home_dir[2]"
            # change dir from /home/user/path to ~/path
            # dir is not PWD anymore
        end

        if test $pwd_existed = 1
            printf '%s* %2d)  %s%s\n' (set_color red) $i $dir (set_color normal)
            set pwd_existed 2 # to make the rest of current the dirprev not red
        else if test $i = 1
            printf '%s- %2d)  %s%s\n' (set_color cyan) $i $dir (set_color normal)
        else if test $i != 1 -a $pwd_existed != 1
            printf '%s %2d)  %s\n' $letters[$i] $i $dir

        end
    end
    if test $pwd_existed = 0 # means the current dir is not in the $uniq_dirs
        printf '%s* %2d)  %s%s\n' (set_color red) "0" $PWD (set_color normal)
    end

    echo '---------------------------'
    read -n 1 -l -p 'echo "Goto: "' choice
    if test "$choice" = ""
        return 0
    else if string match -q -r '^[\-|b-z]$' $choice
        set choice (contains -i $choice $letters)
    end

    if string match -q -r '^\d+$' $choice
        if test $choice -ge 1 -a $choice -le $dirc
            cd $uniq_dirs[$choice]
            set -l dir_short (string match -r "$HOME(/.*|\$)" "$uniq_dirs[$choice]")
            set -l cd_dir "~$dir_short[2]"
            echo cd $cd_dir
            return
        else if test $choice -eq 0
            echo You are already in directory `(pwd)`
        else
            echo Error: expected a number between 0 and $dirc, got \"$choice\"
            return 1
        end
    else
        echo Error: expected a number between 1 and $dirc or letter in that range, got \"$choice\"
        return 1
    end
end

# Download anaconda from https://mirrors.cloud.tencent.com/anaconda/archive/
# Check ~/.condarc for configuration
# https://www.piqizhu.com/tools/anaconda
#conda install -c binstar binstar # renamed to anaconda-client, so `conda install anaconda-client`
#binstar search -t conda packgename # get the channel(user) name
#conda install -c channel packagename
# After install package using `conda install -c CHANNEL PKG`, you have to manually
# conda config --add channels your_new_channel, or these packages won't be updateed when `condau`
#
# The packages needed to be installed using conda are(only if you have no sudo permission or the offcial is old)
# conda install -c conda-forge ncurses emacs w3m fish the_silver_searcher source-highlight tmux lazygit
# conda install -c lebedov tig
abbr condas 'binstar search -t conda' # [packagename]
abbr condai 'conda install -c' # [channel] [packagename]
abbr condau 'conda upgrade --all -vy; and conda clean -avy'
abbr condac 'conda clean -avy'
abbr condaS 'anaconda show' # [channel/packagename]

#### ---------------- anaconda starts -----------------------
# anaconda
function condalist -d 'List conda environments.'
    for dir in (ls $HOME/anaconda3/envs)
        echo $dir
    end
end

function condactivate -d 'Activate a conda environment' -a cenv
    if test -z $cenv
        echo 'Usage: condactivate <env name>'
        return 1
    end

    # condabin will be the path to the bin directory
    # in the specified conda environment
    set condabin $HOME/anaconda3/envs/$cenv/bin

    # check whether the condabin directory actually exists and
    # exit the function with an error status if it does not
    if not test -d $condabin
        echo 'Environment not found.'
        return 1
    end

    # deactivate an existing conda environment if there is one
    if set -q __CONDA_ENV_ACTIVE
        deactivate
    end

    # save the current path
    set -xg DEFAULT_PATH $PATH

    # put the condabin directory at the front of the PATH
    set -xg PATH $condabin $PATH

    # this is an undocumented environmental variable that influences
    # how conda behaves when you don't specify an environment for it.
    # https://github.com/conda/conda/issues/473
    set -xg CONDA_DEFAULT_ENV $cenv

    # set up the prompt so it has the env name in it
    functions -e __original_fish_prompt
    functions -c fish_prompt __original_fish_prompt
    function fish_prompt
        set_color blue
        echo -n '('$CONDA_DEFAULT_ENV') '
        set_color normal
        __original_fish_prompt
    end

    # flag for whether a conda environment has been set
    set -xg __CONDA_ENV_ACTIVE 'true'
end

function deactivate -d 'Deactivate a conda environment'
    if set -q __CONDA_ENV_ACTIVE
        # set PATH back to its default before activating the conda env
        set -xg PATH $DEFAULT_PATH
        set -e DEFAULT_PATH

        # unset this so that conda behaves according to its default behavior
        set -e CONDA_DEFAULT_ENV

        # reset to the original prompt
        functions -e fish_prompt
        functions -c __original_fish_prompt fish_prompt
        functions -e __original_fish_prompt
        set -e __CONDA_ENV_ACTIVE
    end
end

# aliases so condactivate and deactivate can have shorter names
function ca -d 'Activate a conda environment'
    condactivate $argv
end

function cda -d 'Deactivate a conda environment'
    deactivate $argv
end

# complete conda environment names when activating
complete -c condactivate -xA -a "(condalist)"
complete -c ca -xA -a "(condalist)"

function con --description 'Activate a conda environment.'
    if test (count $argv) -eq 0
        conda info -e
        return 0
    end

    if test (count $argv) -ne 1
        echo 'Too many args -- expected at most one conda environment name.'
        return 1
    end

    set -l conda_env $argv[1]

    if not command conda '..checkenv' fish $conda_env
        return 1
    end

    # Deactivate the currently active environment if set.
    if set -q CONDA_DEFAULT_ENV
        coff
    end

    # Try to activate the environment.
    set -l new_path (command conda '..activate' fish $conda_env)
    or return $status

    set -g CONDA_PATH_BACKUP $PATH
    set -gx PATH $new_path $PATH
    set -gx CONDA_DEFAULT_ENV $conda_env
end
function coff --description 'Deactivate a conda environment.'
    if set -q argv[1]
        echo "Too many args -- expected no args, got: $argv" >&2
        return 1
    end

    if not set -q CONDA_DEFAULT_ENV
        echo "There doesn't appear to be any conda env in effect." >&2
        return 1
    end

    # Deactivate the environment.
    set -gx PATH $CONDA_PATH_BACKUP
    set -e CONDA_PATH_BACKUP
    set -e CONDA_DEFAULT_ENV
end
#### ---------------- anaconda ends -----------------------
