class HomeController < ApplicationController
  def top
    @topics = Topic.all
  end
end
