#!/bin/sh

$LOG notice :tools/ci/convert "Converting TAP to XML report"
npm install https://github.com/dotmpe/tap-xunit

{ ./node_modules/.bin/tap-xunit < build/test-results.tap > build/test-results.xml
} || true
#
