class AdminController < ApplicationController

  before_action :authorize
  before_action :show_header

end
