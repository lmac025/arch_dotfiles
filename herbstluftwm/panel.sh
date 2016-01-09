#!/bin/bash

source ~/.colours

monitor=${1:-0}
geometry=( $(herbstclient monitor_rect "$monitor") )
if [ -z "$geometry" ] ;then
    echo "Invalid monitor $monitor"
    exit 1
fi
# geometry has the format: WxH+X+Y
x=${geometry[0]}
y=${geometry[1]}
panel_width=${geometry[2]}
panel_height=16
font="-*-fixed-medium-*-*-*-12-*-*-*-*-*-*-"
bgcolor=$c_black
selbg=$c_blue
selfg=$c_white

####
# Try to find textwidth binary.
# In e.g. Ubuntu, this is named dzen2-textwidth.
if [ -e "$(which textwidth 2> /dev/null)" ] ; then
    textwidth="textwidth";
elif [ -e "$(which dzen2-textwidth 2> /dev/null)" ] ; then
    textwidth="dzen2-textwidth";
else
    echo "This script requires the textwidth tool of the dzen2 project."
    exit 1
fi
####

function uniq_linebuffered() {
    awk '$0 != l { print ; l=$0 ; fflush(); }' "$@"
}

herbstclient pad $monitor $panel_height
{
    # events:
    #mpc idleloop player &
    while true ; do
        date +'date ^fg(#efefef)%H:%M^fg(#909090), %Y-%m-^fg(#efefef)%d'
        sleep 1 || break
    done > >(uniq_linebuffered)  &
    childpid=$!
    herbstclient --idle
    kill $childpid
} 2> /dev/null | {
    TAGS=( $(herbstclient tag_status $monitor) )
    date=""
    windowtitle=""
    while true ; do
        bordercolor="#26221C"
        separator="^bg()^fg($selbg)|"
        # draw tags
        for i in "${TAGS[@]}" ; do
            case ${i:0:1} in
                '.') # Empty window
                    echo -n "^bg()^fg($c_grey)"
                    ;;
                '#') # Current window
                    echo -n "^bg($selbg)^fg($selfg)"
                    ;;
                '+') # Focused window not focused  monitor
                    echo -n "^bg($selbg)^fg($c_black)"
                    ;;
                '-') # Focused window on another monitor -- Still don't know what triggers this
                    echo -n "^bg($c_violet)^fg()"
                    ;;
                ':') # not empty
                    echo -n "^bg()^fg($c_white)"
                    ;;
                '!') # Alert
                    echo -n "^bg()^fg($c_red)"
                    ;;
                *)  # ???    -- No idea whatfuck
                    echo -n "^bg($c_violet)^fg()" 
                    ;;

            esac
            echo -n " ${i:1} "
        done
        echo -n "$separator"
        echo -n "^bg()^fg() ${windowtitle//^/^^}"
        # small adjustments
        right="$separator^bg() $date $separator"
        right_text_only=$(echo -n "$right"|sed 's.\^[^(]*([^)]*)..g')
        # get width of right aligned text.. and add some space..
        width=$($textwidth "$font" "$right_text_only    ")
        echo -n "^pa($(($panel_width - $width)))$right"
        echo
        # wait for next event
        read line || break
        cmd=( $line )
        # find out event origin
        case "${cmd[0]}" in
            tag*)
                #echo "reseting tags" >&2
                TAGS=( $(herbstclient tag_status $monitor) )
                ;;
            date)
                #echo "reseting date" >&2
                date="${cmd[@]:1}"
                ;;
            quit_panel)
                exit
                ;;
            reload)
                exit
                ;;
            focus_changed|window_title_changed)
                windowtitle="${cmd[@]:2}"
                ;;
            #player)
            #    ;;
        esac
        done
    } 2> /dev/null | dzen2 -w $panel_width -x $x -y $y -fn "$font" -h $panel_height -ta l -bg "$bgcolor" -fg "$c_grey"
