#!/bin/bash

if [ "$environemt" = "staging" ]
then
  if grep -Fxq "# NO-BOT" wp/.htaccess
  then
    echo "No-Bot already set"
  else

cat <<EOF >> wp/.htaccess

# NO-BOT
RewriteEngine On

RewriteCond %{HTTP_USER_AGENT} (googlebot|bingbot|Baiduspider) [NC]
RewriteRule .* - [R=403,L]
# NO-BOT
EOF

  fi
fi
