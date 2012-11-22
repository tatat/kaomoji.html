# -*- coding: utf-8 -*-

APP_ROOT = File.expand_path(File.dirname __FILE__ ) unless defined? APP_ROOT
$:.unshift APP_ROOT

require 'application'

use Rack::Deflater
run Application