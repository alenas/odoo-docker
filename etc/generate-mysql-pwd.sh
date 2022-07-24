# Generates random strong passwords and saves them as environment variables
# so you do this once and then can reuse database connection on container rebuild
export MYSQLPWD=$(cat /dev/urandom | tr -dc 'a-zA-Z0-9!@#$%^&*()' | fold -w 24 | head -n 1)
# save backup passwords to set-env-pwd.sh file
echo -e "export MYSQLPWD='$MYSQLPWD'" > set-env-pwd.sh