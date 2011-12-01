# Helper functions

# encoding: utf-8
require 'sinatra/base'

module Sinatra
  module HelperMethods
    # From http://api.rubyonrails.org/classes/ActionView/Helpers/TextHelper.html#method-i-truncate
    def truncate(text, options = {})
      options.reverse_merge!(:length => 30)
      text.truncate(options.delete(:length), options) if text
    end
  end
  helpers HelperMethods
end