require 'rubygems'
require 'bundler/setup'
Bundler.require(:default)

require "benchmark/memory"
require "summernote-rails"
require "summernote-rails/cleaner"

def clean
  SummernoteCleaner.clean '<p>'
end

Benchmark.memory do |x|
  x.report("clean") { clean }
end
