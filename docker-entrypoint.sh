#!/bin/sh

# docker-entrypoint.sh
# version: 1.0


# stop immediately if somethings goes wrong
set -e

# Create calendar users file with names and encrypted passwords
if [ -n "$USERS" ]; then

  for e in $(echo $USERS | tr "," " "); do
    usr=$(echo $e | cut -d':' -f1)
    psw=$(echo $e | cut -d':' -f2)
    htpasswd -Bb /etc/radicale/users ${usr} ${psw} ;
  done

fi


# Switch to unprivileged process owner?
if [ -n "$RUNAS" ]; then
  # execute as unprivileged user requested

  # we are on busybox, no array capabilities
  owner=$(echo $RUNAS | cut -d':' -f1)
    uid=$(echo $RUNAS | cut -d':' -f2)
    gid=$(echo $RUNAS | cut -d':' -f3)

  if id -u "$owner" > /dev/null 2>&1; then
    # Owner spezified and existing
    if [ "$owner" != "$uid" ]; then
      # A uid is specified for existing owner, gid may or may not
      # NOTE: cut provides the value of the first expression (f1 /owner) for
      #       all 3 expressions if just the first parameter exists.
      #       There is no empty uid.
      usermod -o -u "$uid" "$owner"  > /dev/null 2>&1
      if [ -n "$gid" ]; then
        if [ ! $(getent group "$gid") ]; then
          # spezified gid is unused
          if [ $(getent group "$owner") ]; then
            # groupname (owner) already exists
            groupmod  -g "$gid"  "$owner"
          else
            groupadd  -g "$gid"  "$owner"
          fi
        fi
        usermod -g "$gid" "$owner"  > /dev/null 2>&1
      fi
    fi
  else
    # new owner specified
    adduser -D -H -h "" -g "Radicale user" -s /bin/false   "$owner"
    if [ "$owner" != "$uid" ]; then
      # Additionally a uid and maybe gid spezified (see note above)
      usermod -o -u "$uid" "$owner"
      if [ -n "$gid" ]; then
        # gid specified as well
        if [ ! $(getent group "$gid") ]; then
          groupadd  -g "$gid"  "$owner"
        fi
        usermod -g "$gid" "$owner"  > /dev/null 2>&1
      fi
    fi
  fi


  # Re-set permission to the specified user if current user is root
  # This avoids permission denied if the data volume is mounted by root
  if  [ "$(id -u)" = '0' ]; then
      #Leave the files group untouched.
      chown -R $owner        /srv/radicale
  fi


  exec su-exec "$owner" "$@"
else
  # execute as root
  exec "$@"
fi
