#!/bin/sh
npm install https://github.com/dotmpe/tap-xunit

{ ./node_modules/.bin/tap-xunit < build/test-results.tap > build/test-results.xml
} || true
#