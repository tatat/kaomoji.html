# -*- coding: utf-8 -*-

$:.unshift File.expand_path(File.dirname __FILE__ )

require 'application'

use Rack::Deflater
run Application