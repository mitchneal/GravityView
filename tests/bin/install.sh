#!/usr/bin/env bash

#if [ $# -lt 3 ]; then
#	echo "usage: $0 <db-name> <db-user> <db-pass> [db-host] [wp-version] [skip-database-creation]"
#	exit 1
#fi

WP_TESTS_DIR=${WP_TESTS_DIR-/tmp/wordpress-tests-lib}
WP_CORE_DIR=${WP_CORE_DIR-/tmp/wordpress/}

## Begin GravityView mod - we modify the default variables by setting some defaults

#DB_NAME=$1
#DB_USER=$2
#DB_PASS=$3
#DB_HOST=${4-localhost}
#WP_VERSION=${5-latest}
#SKIP_DB_CREATE=${6-false}

DB_NAME="${1-gravityview_test}"
DB_USER="${2-root}"
DB_PASS="${3-root}"
DB_HOST="${4-localhost}"
WP_VERSION="${5-latest}"
SKIP_DB_CREATE="${6-false}"
PATH_TO_GF_ZIP="${7}"

GF_CORE_DIR=${WP_TESTS_DIR-/tmp/gravityforms/}

## End GravityView mod

download() {
    if [ `which curl` ]; then
        curl -s "$1" > "$2";
    elif [ `which wget` ]; then
        wget -nv -O "$2" "$1"
    fi
}

if [[ $WP_VERSION =~ [0-9]+\.[0-9]+(\.[0-9]+)? ]]; then
	WP_TESTS_TAG="tags/$WP_VERSION"
elif [[ $WP_VERSION == 'nightly' || $WP_VERSION == 'trunk' ]]; then
	WP_TESTS_TAG="trunk"
else
	# http serves a single offer, whereas https serves multiple. we only want one
	download http://api.wordpress.org/core/version-check/1.7/ /tmp/wp-latest.json
	grep '[0-9]+\.[0-9]+(\.[0-9]+)?' /tmp/wp-latest.json
	LATEST_VERSION=$(grep -o '"version":"[^"]*' /tmp/wp-latest.json | sed 's/"version":"//')
	if [[ -z "$LATEST_VERSION" ]]; then
		echo "Latest WordPress version could not be found"
		exit 1
	fi
	WP_TESTS_TAG="tags/$LATEST_VERSION"
fi

set -ex

install_wp() {

	if [ -d $WP_CORE_DIR ]; then
		return;
	fi

	mkdir -p $WP_CORE_DIR

	if [[ $WP_VERSION == 'nightly' || $WP_VERSION == 'trunk' ]]; then
		mkdir -p /tmp/wordpress-nightly
		download https://wordpress.org/nightly-builds/wordpress-latest.zip  /tmp/wordpress-nightly/wordpress-nightly.zip
		unzip -q /tmp/wordpress-nightly/wordpress-nightly.zip -d /tmp/wordpress-nightly/
		mv /tmp/wordpress-nightly/wordpress/* $WP_CORE_DIR
	else
		if [ $WP_VERSION == 'latest' ]; then
			local ARCHIVE_NAME='latest'
		else
			local ARCHIVE_NAME="wordpress-$WP_VERSION"
		fi
		download https://wordpress.org/${ARCHIVE_NAME}.tar.gz  /tmp/wordpress.tar.gz
		tar --strip-components=1 -zxmf /tmp/wordpress.tar.gz -C $WP_CORE_DIR
	fi

	download https://raw.github.com/markoheijnen/wp-mysqli/master/db.php $WP_CORE_DIR/wp-content/db.php
}

install_test_suite() {
	# portable in-place argument for both GNU sed and Mac OSX sed
	if [[ $(uname -s) == 'Darwin' ]]; then
		local ioption='-i .bak'
	else
		local ioption='-i'
	fi

	# set up testing suite if it doesn't yet exist
	if [ ! -d $WP_TESTS_DIR ]; then
		# set up testing suite
		mkdir -p $WP_TESTS_DIR
		svn co --quiet https://develop.svn.wordpress.org/${WP_TESTS_TAG}/tests/phpunit/includes/ $WP_TESTS_DIR/includes
		mkdir $WP_TESTS_DIR/data
	fi

	if [ ! -f wp-tests-config.php ]; then
		download https://develop.svn.wordpress.org/${WP_TESTS_TAG}/wp-tests-config-sample.php "$WP_TESTS_DIR"/wp-tests-config.php
		# remove all forward slashes in the end
		WP_CORE_DIR=$(echo $WP_CORE_DIR | sed "s:/\+$::")
		sed $ioption "s:dirname( __FILE__ ) . '/src/':'$WP_CORE_DIR/':" "$WP_TESTS_DIR"/wp-tests-config.php
		sed $ioption "s/youremptytestdbnamehere/$DB_NAME/" "$WP_TESTS_DIR"/wp-tests-config.php
		sed $ioption "s/yourusernamehere/$DB_USER/" "$WP_TESTS_DIR"/wp-tests-config.php
		sed $ioption "s/yourpasswordhere/$DB_PASS/" "$WP_TESTS_DIR"/wp-tests-config.php
		sed $ioption "s|localhost|${DB_HOST}|" "$WP_TESTS_DIR"/wp-tests-config.php
	fi

}

install_db() {

	if [ ${SKIP_DB_CREATE} = "true" ]; then
		return 0
	fi

	# parse DB_HOST for port or socket references
	local PARTS=(${DB_HOST//\:/ })
	local DB_HOSTNAME=${PARTS[0]};
	local DB_SOCK_OR_PORT=${PARTS[1]};
	local EXTRA=""

	if ! [ -z $DB_HOSTNAME ] ; then
		if [ $(echo $DB_SOCK_OR_PORT | grep -e '^[0-9]\{1,\}$') ]; then
			EXTRA=" --host=$DB_HOSTNAME --port=$DB_SOCK_OR_PORT --protocol=tcp"
		elif ! [ -z $DB_SOCK_OR_PORT ] ; then
			EXTRA=" --socket=$DB_SOCK_OR_PORT"
		elif ! [ -z $DB_HOSTNAME ] ; then
			EXTRA=" --host=$DB_HOSTNAME --protocol=tcp"
		fi
	fi

	# create database
	if ! mysql -u"$DB_USER" --password="$DB_PASS" -e "use $DB_NAME"$EXTRA; then
	    mysqladmin create $DB_NAME --user="$DB_USER" --password="$DB_PASS"$EXTRA
	fi
}

install_wp
install_test_suite
install_db

##
## Above this is generated by wp-cli
## Below is custom GravityView code
##


if [ "$1" == 'help' ]; then
    echo "usage: $0 [db-name (default: root)] [db-user (default: root)] [db-pass (default: root)] [db-host (default: localhost)] [wp-version (default: latest)] [skip-database-creation (default: false)] [gravity-forms-zip-url]"
    echo "example using remote .zip: $0 gravityview_test root root localhost latest http://example.com/path/to/gravityview.zip"
    echo "example using local path: $0 gravityview_test root root localhost latest ../gravityforms/"
    echo "If Gravity Forms is not installed locally, you must provide either a path to a local Gravity Forms directory, or a full URL that points to a .zip file of Gravity Forms. If it is, you can leave the argument blank."
	exit 1
fi

# TRAVIS_GRAVITY_FORMS_2_2_DL_URL variable will be set in TravisCI
GRAVITY_FORMS_DL_PATH_OR_URL="${7-$TRAVIS_GRAVITY_FORMS_2_3_DL_URL}"

# Get current WordPress plugin directory
TESTS_PLUGINS_DIR="$(dirname "${PWD}")"

install_gravity_forms_22(){
    mkdir -p "$GF_CORE_DIR"

    if [ -z ${TRAVIS_GRAVITY_FORMS_2_2_DL_URL+x} ]; then
        # Pull from remote
	    curl -L "$GRAVITY_FORMS_DL_PATH_OR_URL" --output /tmp/gravityforms-2.2.zip

	    # -o will overwrite files. -q is quiet mode
	    unzip -o -q /tmp/gravityforms-2.2.zip -d /tmp/
    else
        if [[ -d "$TESTS_PLUGINS_DIR"/gravityforms2.2 ]]; then
            rsync -ar --exclude=.git "$TESTS_PLUGINS_DIR"/gravityforms /tmp/
        else
            exit 1
        fi
    fi
}

install_gravity_forms(){
    mkdir -p "$GF_CORE_DIR"

    echo "$GRAVITY_FORMS_DL_PATH_OR_URL";

    # If you have passed an URL with a ZIP file, grab it and install
    if [[ $GRAVITY_FORMS_DL_PATH_OR_URL = *".zip"* ]]; then

        # install unzip if not available
        if ! [ -x "$(command -v unzip)" ]; then
            apt-get install zip unzip
        fi

        # Pull from remote
	    curl -L "$GRAVITY_FORMS_DL_PATH_OR_URL" --output /tmp/gravityforms.zip

	    # -o will overwrite files. -q is quiet mode
	    unzip -o -q /tmp/gravityforms.zip -d /tmp/

    # If you have passed a path, check if it exists. If it does, use that as the Gravity Forms location
    elif [[ $GRAVITY_FORMS_DL_PATH_OR_URL != '' && -d $GRAVITY_FORMS_DL_PATH_OR_URL ]]; then

        rsync -ar --exclude=.git "$GRAVITY_FORMS_DL_PATH_OR_URL" /tmp/gravityforms/

    # Otherwise, if you have Gravity Forms installed locally, use that.
    else
        if [[ -d "$TESTS_PLUGINS_DIR"/gravityforms ]]; then
            rsync -ar --exclude=.git "$TESTS_PLUGINS_DIR"/gravityforms /tmp/
        elif [[ -d "$TESTS_PLUGINS_DIR"/../../gravityforms ]]; then
            rsync -ar --exclude=.git "$TESTS_PLUGINS_DIR"/../../gravityforms/ /tmp/
        else
            exit 1
        fi
	fi
}

# Pick version to install
if [[ $GF_VERSION == "2.2" ]]; then
	install_gravity_forms_22
else
	install_gravity_forms
fi
