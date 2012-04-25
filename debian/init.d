#!/bin/sh
### BEGIN INIT INFO
# Provides:          gerrit
# Required-Start:    $network $local_fs $remote_fs
# Required-Stop:     $remote_fs
# Default-Start:     2 3 4 5
# Default-Stop:      0 1 6
# Description:       Web based code review and project management for Git based projects
### END INIT INFO

# Author: Marin Atanasov Nikolov <mra@melexis.com>

# PATH should only include /usr/* if it runs after the mountnfs.sh script
PATH=/sbin:/usr/sbin:/bin:/usr/bin

DESC=gerrit
NAME=gerrit
SCRIPTNAME=/etc/init.d/$NAME

# Read configuration variable file if it is present
[ -r /etc/default/$NAME ] && . /etc/default/$NAME

DAEMON=/usr/bin/daemon
DAEMON_ARGS=""

PIDFILE=${GERRIT_SITE}/logs/$NAME.pid

SU=/bin/su

# Exit if the package is not installed
[ -x $DAEMON ] || exit 0

# Load the VERBOSE setting and other rcS variables
. /lib/init/vars.sh

# Define LSB log_* functions.
# Depend on lsb-base (>= 3.0-6) to ensure that this file is present.
. /lib/lsb/init-functions

#
# Function that initializes Gerrit
# 
gerrit_initialize()
{
    echo "No Gerrit site found. Will Initialize Gerrit first..."

    [ ! -d "${GERRIT_DATADIR}" ] && install -d -o ${GERRIT_USER} -g ${GERRIT_GROUP} -m 750 ${GERRIT_DATADIR}
    
    [ ! -d "${GERRIT_SITE}" ] && \
	${SU} -l ${GERRIT_USER} --shell=/bin/sh -c "${DAEMON} ${DAEMON_ARGS} -- ${JAVA} ${JAVA_ARGS} -jar ${GERRIT_WAR} ${GERRIT_ARGS} init -d ${GERRIT_SITE}"
}

#
# Function that starts the daemon/service
#
do_start()
{
	# Return
	#   0 if daemon has been started
	#   1 if daemon was already running
	#   2 if daemon could not be started
    
	${DAEMON} ${DAEMON_ARGS} --running && return 1
	
	# Initialize Gerrit if it is not yet initialized
	[ ! -d "${GERRIT_DATADIR}" -o ! -d "${GERRIT_SITE}" ] && gerrit_initialize
	
	${GERRIT_SH} start
}

#
# Verify that all Gerrit processes have been shutdown
# and if not, then do killall for them
# 
get_running() 
{
    return `ps -U $GERRIT_USER --no-headers -f | egrep -e '(java|daemon)' | grep -c . `
}

force_stop() 
{
    get_running
    if [ $? -ne 0 ]; then
        killall -u $GERRIT_USER java daemon || return 3
    fi
}

# Get the status of the daemon process
get_daemon_status()
{
    $DAEMON $DAEMON_ARGS --running || return 1
}

#
# Function that stops the daemon/service
#
do_stop()
{
	# Return
	#   0 if daemon has been stopped
	#   1 if daemon was already stopped
	#   2 if daemon could not be stopped
	#   other if a failure occurred

    	get_daemon_status
	case "$?" in
            0)
		$DAEMON $DAEMON_ARGS --stop || return 2
        	# wait for the process to really terminate
		for n in 1 2 3 4 5; do
		    sleep 1
		    $DAEMON $DAEMON_ARGS --running || break
		done
		if get_daemon_status; then
		    force_stop || return 3
		fi
		;;
            *)
		force_stop || return 3
		;;
	esac
	
	# Many daemons don't delete their pidfiles when they exit.
	rm -f $PIDFILE
	return 0
}

case "$1" in
  start)
    log_daemon_msg "Starting $DESC " "$NAME"
    do_start
    case "$?" in
		0|1) log_end_msg 0 ;;
		2) log_end_msg 1 ;;
	esac
  ;;
  stop)
	log_daemon_msg "Stopping $DESC" "$NAME"
	do_stop
	case "$?" in
		0|1) log_end_msg 0 ;;
		2) log_end_msg 1 ;;
	esac
	;;
  status)
       get_daemon_status
       case "$?" in
           0) echo "$DESC is running with the pid `cat $PIDFILE`";;
           *)
               get_running
               procs=$?
               if [ $procs -eq 0 ]; then
                   echo -n "$DESC is not running"
                   if [ -f $PIDFILE ]; then
                       echo ", but the pidfile ($PIDFILE) still exists"
                   else
                       echo
                   fi

               else
                   echo "$procs instances of jenkins are running at the moment"
                   echo "but the pidfile $PIDFILE is missing"
               fi
               ;;
       esac
       ;;
  restart|force-reload)
	#
	# If the "reload" option is implemented then remove the
	# 'force-reload' alias
	#
	log_daemon_msg "Restarting $DESC" "$NAME"
	do_stop
	case "$?" in
	  0|1)
		do_start
		case "$?" in
			0) log_end_msg 0 ;;
			1) log_end_msg 1 ;; # Old process is still running
			*) log_end_msg 1 ;; # Failed to start
		esac
		;;
	  *)
	  	# Failed to stop
		log_end_msg 1
		;;
	esac
	;;
  *)
	echo "Usage: $SCRIPTNAME {start|stop|status|restart|force-reload}" >&2
	exit 3
	;;
esac

exit 0