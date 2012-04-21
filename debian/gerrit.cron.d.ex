#
# Regular cron jobs for the gerrit package
#
0 4	* * *	root	[ -x /usr/bin/gerrit_maintenance ] && /usr/bin/gerrit_maintenance
