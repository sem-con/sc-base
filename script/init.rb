#!/usr/bin/env ruby
# encoding: utf-8

require 'httparty'

init_url = "http://localhost:3000/api/init"
response = HTTParty.post(init_url)
