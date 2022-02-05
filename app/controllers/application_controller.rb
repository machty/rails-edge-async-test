class ApplicationController < ActionController::Base
  def index
    @wat = Async::Task.current
  end
end
