class AdminController < ApplicationController

  before_filter :authorize
  before_filter :show_header

end
