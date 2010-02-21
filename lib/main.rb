# Mirlord's RNP-contest Bot
# Author: Vladimir Chizhov <master@mirlord.com>

require 'lib/utils'
require 'lib/point'
require 'lib/map'
require 'lib/moves'
require 'lib/bot'

$SAFE=3 if ARGV.include?( '--safe' )

MirlordBot.new()

