#!/bin/bash

echo "$(date): Setting up demo environment."
sleep 1

echo "$(date): Creating project: demo-abtesting."
oc new-project demo-abtesting --description "Demo of AB testing using PHP 7.0 and 5.6" --display-name "Demo - AB testing"
sleep 1

oc project demo-abtesting

echo "$(date): Creating an PHP 7.0 application."
oc new-app openshift/php:7.0~https://github.com/mglantz/ocp-php.git --name=php70
oc expose service php70
sleep 1

echo "$(date): Creating an PHP 5.6 application"
oc new-app openshift/php:5.6~https://github.com/mglantz/ocp-php.git --name=php56
oc expose service php56
sleep 1

echo "$(date): Creating an AB route"
oc expose service php70 --name='ab-php' -l name='ab-php'
sleep 1

echo "$(date): Configuring load balancing between the two applications."
oc set route-backends ab-php php70=10 php56=90
oc annotate route/ab-php haproxy.router.openshift.io/balance=static-rr
sleep 1

echo "$(date): Waiting for the php applications to build and deploy. This may take a bit."
while true; do
	if oc get pods|egrep '(php56|php70)'|grep Running|grep "1/1"|wc -l|grep 2 >/dev/null; then
		echo "$(date): Applications are now up. Displaying applications in project demo-abtesting:"
		oc get pods|egrep '(php56|php70)'|grep Running|grep "1/1"
		echo
		echo "$(date): Displaying AB route:"
		oc get route|grep ab-php
		echo
		break
	fi
	sleep 1
done

read -p "Press enter to commence testing of AB route." GO

ABROUTE=$(oc get route|grep ab-php|awk '{ print $2 }')

echo "$(date): Making 20 http requests to the load balanced AB route."

for i in {1..20}; do
	curl -s http://$ABROUTE|grep Version
	sleep 1
done


