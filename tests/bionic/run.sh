#!/bin/sh -ex
mkdir -p ~/.config/Yubico

create_keys() {
	pamu2fcfg -t es256 -N > /tmp/es256
	[ "${U2F_TOKEN}" != "" ] && return
	pamu2fcfg -t es256 -N -r -o originA > /tmp/es256.r
	pamu2fcfg -t rs256 -N -r -o originB > /tmp/rs256.r
}

run_tests() {
	[ "${U2F_TOKEN}" != "" ] && return

	echo "auth sufficient pam_u2f.so" > /etc/pam.d/dummy
	cp /tmp/es256 ~/.config/Yubico/u2f_keys
	pamtester dummy root authenticate

	echo "auth sufficient pam_u2f.so origin=originA" > /etc/pam.d/dummy
	cp /tmp/es256.r ~/.config/Yubico/u2f_keys
	pamtester dummy root authenticate

	echo "auth sufficient pam_u2f.so origin=originB" > /etc/pam.d/dummy
	cp /tmp/rs256.r ~/.config/Yubico/u2f_keys
	pamtester dummy root authenticate
}

run_user_presence_tests() {
	echo "auth sufficient pam_u2f.so" > /etc/pam.d/dummy
	cat /tmp/es256 | sed 's/-$/p/' > ~/.config/Yubico/u2f_keys
	pamtester dummy root authenticate

	[ "${U2F_TOKEN}" != "" ] && return

	echo "auth sufficient pam_u2f.so origin=originA" > /etc/pam.d/dummy
	cat /tmp/es256.r | sed 's/-$/p/' > ~/.config/Yubico/u2f_keys
	pamtester dummy root authenticate

	echo "auth sufficient pam_u2f.so origin=originB" > /etc/pam.d/dummy
	cat /tmp/rs256.r | sed 's/-$/p/' > ~/.config/Yubico/u2f_keys
	pamtester dummy root authenticate
}

run_user_verification_tests() {
	[ "${U2F_TOKEN}" != "" ] && return
	[ "${FIDO2_PIN}" = "" ] && return

	echo "auth sufficient pam_u2f.so" > /etc/pam.d/dummy
	cat /tmp/es256 | sed 's/-$/v/' > ~/.config/Yubico/u2f_keys
	pamtester dummy root authenticate

	echo "auth sufficient pam_u2f.so origin=originA" > /etc/pam.d/dummy
	cat /tmp/es256.r | sed 's/-$/v/' > ~/.config/Yubico/u2f_keys
	pamtester dummy root authenticate

	echo "auth sufficient pam_u2f.so origin=originB" > /etc/pam.d/dummy
	cat /tmp/rs256.r | sed 's/-$/v/' > ~/.config/Yubico/u2f_keys
	pamtester dummy root authenticate
}

run_session_tests() {
	echo "session required pam_u2f.so" > /etc/pam.d/dummy
	cp /tmp/es256 ~/.config/Yubico/u2f_keys
	pamtester dummy root open_session
	pamtester dummy root close_session

	rm ~/.config/Yubico/u2f_keys
	if pamtester dummy root open_session > /dev/null 2>&1 ; then
		>&2 echo Error: unexpectingly succeeding opening session when it shouldn\'t.
		exit 1
	else
		echo Successfully prevented opening session because no key configured.
	fi
}

create_keys
run_tests
run_user_presence_tests
run_user_verification_tests
run_session_tests
