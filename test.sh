#!/bin/bash
#set -x

JAVA_CMD=/opt/java6/bin/java

KIT_DIR=./basekit
LOG_DIR=./log

[ -d $LOG_DIR ] || mkdir -p $LOG_DIR

#MAP=./test/maps/space_test.txt
#MAP=./test/maps/long_coord_test.txt
MAP=./test/maps/headon_symmetric_test.txt
#MAP=./test/maps/dont_split_test.txt
#MAP=$KIT_DIR/maps/apocalyptic.txt
#MAP=$KIT_DIR/maps/empty-room.txt
#MAP=$KIT_DIR/maps/playground.txt

MYBOT_FILE=./lib/main.rb
#MYBOT_FILE=$KIT_DIR/MyTronBot.rb
MYBOT_CMD="ruby $MYBOT_FILE --debug"

#RIVAL_FILE=$KIT_DIR/example_bots/Chaser.jar
#RIVAL_FILE=$KIT_DIR/example_bots/RandomBot.jar
#RIVAL_FILE=$KIT_DIR/example_bots/RunAway.jar
RIVAL_FILE=$KIT_DIR/example_bots/WallHugger.jar
RIVAL_CMD="$JAVA_CMD -jar $RIVAL_FILE"

export SAFE=3

$JAVA_CMD -jar $KIT_DIR/engine/Tron.jar $MAP "$MYBOT_CMD" "$RIVAL_CMD" | tee $LOG_DIR/fight.log

echo "`basename $MYBOT_FILE .rb` | `basename $RIVAL_FILE .jar` | `basename $MAP` | `tail -n 1 $LOG_DIR/fight.log`" >> $LOG_DIR/stat.txt 1.5

