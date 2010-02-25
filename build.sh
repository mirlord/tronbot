#!/bin/bash

DST=./MyTronBot.rb
cat /dev/null > $DST

function catrb() {
    cat $1 | grep -v "^[[:space:]]*[#].*" | grep -v "^[[:space:]]*think[[:space:]].*" | grep -v "^require[[:space:]].*" >> $DST
}

for i in utils map point space moves bot main; do
    catrb lib/${i}.rb
done

